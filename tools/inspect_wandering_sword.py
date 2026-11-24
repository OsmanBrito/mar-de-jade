"""Read-only structural study of the installed Wandering Sword UE4 PAK.

Supports unencrypted v11 PAKs and None/Zlib/Gzip payloads. Writes metadata,
not game artwork or executable code. No third-party Python packages required.
Format references and limitations are documented in the study README.
"""
from __future__ import annotations

import argparse
from collections import Counter
import csv
import gzip
import hashlib
import json
import mmap
from pathlib import Path
import re
import struct
import zlib


class Reader:
    def __init__(self, data: bytes):
        self.data = data
        self.pos = 0

    def take(self, size: int) -> bytes:
        if size < 0 or self.pos + size > len(self.data):
            raise ValueError(f"Read outside buffer: {self.pos}+{size}/{len(self.data)}")
        result = self.data[self.pos:self.pos + size]
        self.pos += size
        return result

    def number(self, fmt: str) -> int:
        return struct.unpack("<" + fmt, self.take(struct.calcsize("<" + fmt)))[0]

    def string(self) -> str:
        count = self.number("i")
        if abs(count) > 2_000_000:
            raise ValueError(f"Implausible FString size {count}")
        if count == 0:
            return ""
        raw = self.take(abs(count) * (2 if count < 0 else 1))
        terminator = b"\0\0" if count < 0 else b"\0"
        if not raw.endswith(terminator):
            raise ValueError("FString without terminator")
        return raw[:-len(terminator)].decode("utf-16-le" if count < 0 else "utf-8")


def digest_file(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def full_entry(reader: Reader) -> dict:
    offset, stored, size, method = [reader.number(fmt) for fmt in ("Q", "Q", "Q", "I")]
    sha1 = reader.take(20).hex()
    blocks = []
    if method:
        count = reader.number("I")
        if count > 1_000_000:
            raise ValueError("Implausible block count")
        blocks = [(reader.number("Q"), reader.number("Q")) for _ in range(count)]
    encrypted = reader.number("B") & 1
    block_size = reader.number("I")
    return dict(offset=offset, stored=stored, size=size, method=method,
                encrypted=bool(encrypted), blocks=blocks, block_size=block_size, sha1=sha1)


class Pak:
    def __init__(self, path: Path):
        self.path = path
        self.size = path.stat().st_size
        with path.open("rb") as stream:
            stream.seek(-221, 2)
            footer = Reader(stream.read(221))
            guid = footer.take(16).hex()
            encrypted = bool(footer.number("B"))
            magic, version = footer.number("I"), footer.number("I")
            if magic != 0x5A6F12E1 or version != 11:
                raise ValueError("This study reader only supports the standard v11 footer")
            offset, size = footer.number("Q"), footer.number("Q")
            sha1 = footer.take(20).hex()
            methods = [footer.take(32).split(b"\0", 1)[0].decode("ascii") for _ in range(5)]
        self.footer = dict(version=version, encrypted_index=encrypted, encryption_guid=guid,
                           index_offset=offset, index_size=size, index_sha1=sha1,
                           compression_methods=methods)
        if encrypted:
            raise ValueError("Encrypted index: this reader does not decrypt data")
        self.checked_indexes = []
        self.verified_payloads = set()
        index = Reader(self.region(offset, size, sha1, "primary"))
        self.mount = index.string()
        self.count = index.number("I")
        self.seed = index.number("Q")
        secondary = {}
        for label in ("path_hash", "directory"):
            if index.number("I"):
                at, length = index.number("Q"), index.number("Q")
                secondary[label] = (at, length, index.take(20).hex())
        encoded = index.take(index.number("I"))
        non_count = index.number("I")
        non_encoded = [full_entry(index) for _ in range(non_count)]
        if index.pos != len(index.data):
            raise ValueError("Primary index was not consumed exactly")
        for label, args in secondary.items():
            self.region(*args, label)
        if "directory" not in secondary:
            raise ValueError("No full directory index available")
        directory = Reader(self.region(*secondary["directory"], "directory"))
        self.entries = {}
        encoded_reader = Reader(encoded)
        for _ in range(directory.number("I")):
            folder = directory.string().lstrip("/")
            for _ in range(directory.number("I")):
                name, location = directory.string(), directory.number("i")
                if location == -2147483648:
                    continue
                if location < 0:
                    entry = dict(non_encoded[-location - 1])
                else:
                    encoded_reader.pos = location
                    entry = self.compact_entry(encoded_reader)
                name = folder + name
                if name in self.entries or entry["offset"] >= self.size:
                    raise ValueError(f"Duplicate path or invalid offset: {name}")
                self.entries[name] = entry
        if directory.pos != len(directory.data) or len(self.entries) != self.count:
            raise ValueError("Directory size/count mismatch")

    def region(self, offset: int, size: int, sha1: str, label: str) -> bytes:
        if offset < 0 or size < 0 or offset + size > self.size or size > 128 * 1024 * 1024:
            raise ValueError("Invalid index region")
        with self.path.open("rb") as stream:
            stream.seek(offset)
            data = stream.read(size)
        if len(data) != size or hashlib.sha1(data).hexdigest() != sha1:
            raise ValueError(f"Invalid {label} index SHA1")
        if label not in self.checked_indexes:
            self.checked_indexes.append(label)
        return data

    @staticmethod
    def compact_entry(reader: Reader) -> dict:
        flags = reader.number("I")
        method = (flags >> 23) & 63
        encrypted = bool(flags & (1 << 22))
        blocks_count = (flags >> 6) & 65535
        block_size = flags & 63
        block_size = reader.number("I") if block_size == 63 else block_size << 11
        offset = reader.number("I" if flags & (1 << 31) else "Q")
        size = reader.number("I" if flags & (1 << 30) else "Q")
        stored = reader.number("I" if flags & (1 << 29) else "Q") if method else size
        header_size = 53 + (4 + blocks_count * 16 if method else 0)
        blocks = []
        cursor = header_size
        for _ in range(blocks_count):
            length = stored if blocks_count == 1 and not encrypted else reader.number("I")
            blocks.append((cursor, cursor + length))
            cursor += (length + 15) & ~15 if encrypted else length
        return dict(offset=offset, stored=stored, size=size, method=method,
                    encrypted=encrypted, blocks=blocks, block_size=block_size)

    def read(self, name: str, maximum: int = 64 * 1024 * 1024, oodle_decoder=None) -> bytes:
        expected = self.entries[name]
        if expected["encrypted"]:
            raise ValueError("Encrypted payload: not decrypted")
        if expected["size"] > maximum or expected["stored"] > maximum:
            raise ValueError("Payload exceeds study size limit")
        with self.path.open("rb") as stream:
            stream.seek(expected["offset"])
            raw_header = stream.read(48)
            method = struct.unpack_from("<I", raw_header, 24)[0]
            if method:
                count_raw = stream.read(4)
                count = struct.unpack("<I", count_raw)[0]
                if count > 1_000_000:
                    raise ValueError("Invalid payload block count")
                raw_header += count_raw + stream.read(count * 16 + 5)
            else:
                raw_header += stream.read(5)
            actual = full_entry(Reader(raw_header))
            for field in ("stored", "size", "method", "encrypted", "blocks"):
                if actual[field] != expected[field]:
                    raise ValueError(f"Payload/index mismatch in {field}: {name}")
            # Compact records quantize a single block's size to 2 KiB.
            if len(actual["blocks"]) > 1 and actual["block_size"] != expected["block_size"]:
                raise ValueError(f"Payload/index mismatch in block_size: {name}")
            if actual["encrypted"]:
                raise ValueError("Encrypted payload: not decrypted")
            stored = stream.read(actual["stored"])
            if hashlib.sha1(stored).hexdigest() != actual["sha1"]:
                raise ValueError(f"Invalid payload SHA1: {name}")
            if not method:
                data = stored
            else:
                codec = self.footer["compression_methods"][method - 1]
                if codec not in ("Zlib", "Gzip") and not (codec == "Oodle" and oodle_decoder):
                    raise ValueError(f"Unsupported compression: {codec}")
                payload_at = len(raw_header)
                decoded = []
                remaining = actual["size"]
                for a, b in actual["blocks"]:
                    block = stored[a - payload_at:b - payload_at]
                    expected_size = min(remaining, actual["block_size"])
                    value = oodle_decoder(block, expected_size) if codec == "Oodle" else zlib.decompress(block, 31 if codec == "Gzip" else 15)
                    if len(value) != expected_size:
                        raise ValueError(f"Invalid decompressed block size: {name}")
                    decoded.append(value)
                    remaining -= len(value)
                data = b"".join(decoded)
            if len(data) != actual["size"]:
                raise ValueError(f"Decompressed size mismatch: {name}")
            self.verified_payloads.add(name)
            return data


def package_names(data: bytes) -> dict:
    """Read the UE4 cooked package summary and its serialized FName table."""
    reader = Reader(data)
    if reader.number("I") != 0x9E2A83C1:
        raise ValueError("Not a UE package")
    legacy = reader.number("i")
    if legacy != -7:
        raise ValueError(f"Unsupported UE package legacy version {legacy}")
    reader.number("i")  # Legacy UE3 version.
    version, licensee = reader.number("i"), reader.number("i")
    custom_count = reader.number("i")
    if not 0 <= custom_count <= 500:
        raise ValueError("Invalid custom versions count")
    reader.take(custom_count * 20)
    header_size = reader.number("i")
    folder = reader.string()
    flags = reader.number("I")
    count, offset = reader.number("i"), reader.number("i")
    reader.take(8)  # Gatherable text count and offset in this UE4 layout.
    export_count, export_offset = reader.number("i"), reader.number("i")
    import_count, import_offset = reader.number("i"), reader.number("i")
    depends_offset = reader.number("i")
    if not 0 <= count <= 500_000 or not 0 <= offset <= len(data):
        raise ValueError("Invalid name map bounds")
    reader.pos = offset
    names = []
    for _ in range(count):
        names.append(reader.string())
        if version == 0 or version >= 504:
            reader.take(4)  # Serialized name hashes.
    def fname(at: int) -> str:
        number, suffix = struct.unpack_from("<ii", data, at)
        if not 0 <= number < len(names) or suffix < 0:
            raise ValueError("Invalid FName reference")
        return names[number] + (f"_{suffix - 1}" if suffix else "")

    imports = []
    for i in range(import_count):
        at = import_offset + i * 28
        imports.append(dict(class_package=fname(at), class_name=fname(at + 8),
                            outer=struct.unpack_from("<i", data, at + 16)[0],
                            object_name=fname(at + 20)))
    exports = []
    stride = (depends_offset - export_offset) // export_count if export_count else 0
    if export_count and (stride != 104 or export_offset + export_count * stride != depends_offset):
        raise ValueError(f"Unsupported export table stride {stride}")
    for i in range(export_count):
        at = export_offset + i * stride
        class_index = struct.unpack_from("<i", data, at)[0]
        class_name = imports[-class_index - 1]["object_name"] if class_index < 0 else f"export:{class_index}"
        serial_size, serial_offset = struct.unpack_from("<qq", data, at + 28)
        exports.append(dict(name=fname(at + 16), class_name=class_name,
                            serial_offset=serial_offset, serial_size=serial_size))
    for export in exports:
        if export["class_name"].startswith("export:"):
            index = int(export["class_name"].split(":")[1])
            if index > 0:
                export["class_name"] = exports[index - 1]["name"]
    return dict(ue4_package_version=version, licensee_version=licensee, flags=flags,
                total_header_size=header_size, folder=folder, name_count=count,
                name_offset=offset, unversioned_package=version == 0,
                name_hash_layout="UE4 >= 504 (also assumed for unversioned packages)",
                imports=imports, exports=exports,
                export_classes=dict(Counter(e["class_name"] for e in exports)), names=names)


def property_tags(reader: Reader, names: list[str]) -> list[dict]:
    """Read tagged UE4 property headers; skip opaque/nested values by size."""
    def fname() -> str:
        index, suffix = reader.number("i"), reader.number("i")
        if not 0 <= index < len(names) or suffix < 0:
            raise ValueError("Invalid property FName")
        return names[index] + (f"_{suffix - 1}" if suffix else "")

    result = []
    for _ in range(10000):
        name = fname()
        if name == "None":
            return result
        kind = fname()
        if not kind.endswith("Property"):
            raise ValueError(f"Invalid property type {kind}")
        size, index = reader.number("i"), reader.number("i")
        tag = dict(name=name, type=kind, array_index=index, serialized_bytes=size)
        if kind == "StructProperty":
            tag["struct"] = fname()
            reader.take(16)
        elif kind == "BoolProperty":
            tag["value"] = bool(reader.number("B"))
        elif kind in ("ByteProperty", "EnumProperty"):
            tag["enum"] = fname()
        elif kind in ("ArrayProperty", "SetProperty"):
            tag["inner"] = fname()
        elif kind == "MapProperty":
            tag["key"], tag["inner"] = fname(), fname()
        if reader.number("B"):
            reader.take(16)
        value_at = reader.pos
        if kind == "IntProperty" and size == 4:
            tag["value"] = reader.number("i")
        elif kind == "FloatProperty" and size == 4:
            tag["value"] = struct.unpack("<f", reader.take(4))[0]
        elif kind == "EnumProperty" and size == 8:
            tag["value"] = fname()
        elif kind in ("NameProperty", "ByteProperty") and size == 8:
            tag["value"] = fname()
        elif kind == "ObjectProperty" and size == 4:
            tag["object_index"] = reader.number("i")
        elif kind == "StructProperty":
            layout = {"Vector": (12, "fff"), "Rotator": (12, "fff"),
                      "Vector2D": (8, "ff"), "IntPoint": (8, "ii"),
                      "LinearColor": (16, "ffff")}.get(tag["struct"])
            if layout and size == layout[0]:
                tag["value"] = list(struct.unpack("<" + layout[1], reader.take(size)))
        elif kind in ("ArrayProperty", "SetProperty") and size >= 4:
            tag["element_count"] = reader.number("i")
        if size < 0:
            raise ValueError("Negative property payload size")
        reader.pos = value_at
        reader.take(size)
        result.append(tag)
    raise ValueError("Property tag limit reached")


def table_schema(data: bytes, metadata: dict, uasset_size: int) -> dict:
    exports = [e for e in metadata["exports"] if e["class_name"] == "DataTable"]
    if len(exports) != 1:
        raise ValueError("Expected one DataTable export")
    export = exports[0]
    start = export["serial_offset"] - uasset_size
    reader = Reader(data)
    reader.pos = start
    property_tags(reader, metadata["names"])
    if reader.number("I"):
        reader.take(16)  # Optional object GUID.
    count = reader.number("i")
    if not 0 <= count <= 1_000_000:
        raise ValueError("Invalid DataTable row count")
    fields = {}
    for _ in range(count):
        row_index, row_suffix = reader.number("i"), reader.number("i")
        if not 0 <= row_index < len(metadata["names"]) or row_suffix < 0:
            raise ValueError("Invalid table row name")
        tags = property_tags(reader, metadata["names"])
        for tag in tags:
            key = tag["name"]
            field = fields.setdefault(key, dict(type=tag["type"], rows_present=0))
            field["rows_present"] += 1
            for detail in ("struct", "enum", "inner", "key"):
                if detail in tag:
                    field[detail] = tag[detail]
    if reader.pos != start + export["serial_size"]:
        raise ValueError(f"DataTable export not consumed exactly: {reader.pos}/{start + export['serial_size']}")
    return dict(row_count=count, field_count=len(fields), fields=fields,
                export_bytes=export["serial_size"], exact_export_consumption=True)


def save_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def analyze(game: Path, output: Path) -> None:
    game, output = game.resolve(), output.resolve()
    if output == game or game in output.parents:
        raise ValueError("Study output must be outside the game installation")
    output.mkdir(parents=True, exist_ok=True)
    (output / ".gdignore").write_text("", encoding="utf-8")
    pak_path = game / "Wandering_Sword/Content/Paks/Wandering_Sword-WindowsNoEditor.pak"
    before = digest_file(pak_path)
    pak = Pak(pak_path)
    rows = []
    extensions, folders = Counter(), Counter()
    for path, entry in sorted(pak.entries.items()):
        extension = Path(path).suffix.lower()
        extensions[extension] += 1
        folders["/".join(path.split("/")[:4])] += 1
        rows.append(dict(path=path, **{k: entry[k] for k in
                    ("offset", "stored", "size", "method", "encrypted")}))
    with gzip.open(output / "pak-index.csv.gz", "wt", newline="", encoding="utf-8-sig") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    old_index = output / "pak-index.csv"
    if old_index.exists():
        old_index.unlink()  # Earlier output of this tool only.
    # Metadata, configuration, and table schemas are studied in memory.
    # The output contains no copied sprite atlases, music, maps, or binaries.
    configs = {}
    probes = []
    errors = []
    assets = sorted(p for p in pak.entries if p.startswith("Wandering_Sword/Content/JH/") and p.endswith(".uasset"))
    selected = [p for p in assets if "/Tables/" in p]
    for pattern, limit in ((r"camera", 12), (r"/MapEditor/.*?/Materials?/", 8),
                           (r"/AI/Combat/", 10), (r"/Core/", 8),
                           (r"/Characters/.*/PFB_.*_(?:I|R)_[DLRU]\.uasset$", 8),
                           (r"/Characters/.*/Sprite", 4)):
        selected += [p for p in assets if re.search(pattern, p, re.I)][:limit]
    selected += [p for p in assets if re.search(
        r"/Core/(Characters/(BP_SceneHero|BP_FightNPC|BP_WorldHero1)|Controllers/BP_PlayerController|GameModes/BP_GameMode)\.uasset$", p)]
    selected += sorted(p for p in pak.entries if p.startswith("Wandering_Sword/Content/JH/Maps/")
                       and p.endswith(".umap"))[:6]
    for name in pak.entries:
        if name.endswith((".uproject", "DefaultEngine.ini", "DefaultGame.ini", "DefaultInput.ini")):
            try:
                data = pak.read(name)
                text = data.decode("utf-8-sig", errors="replace")
                if name.endswith(".uproject"):
                    project = json.loads(text)
                    findings = {k: project[k] for k in ("FileVersion", "Modules", "Plugins", "TargetPlatforms") if k in project}
                else:
                    findings = [line for line in text.splitlines() if re.search(
                        r"^(\[|r\.|GameDefaultMap|GlobalDefaultGameMode|NearClipPlane|bUseFixedFrameRate|FixedFrameRate|MinDesiredFrameRate|DefaultViewportMouseCaptureMode|DefaultViewportMouseLockMode)", line)]
                configs[name] = dict(size=len(data), sha256=hashlib.sha256(data).hexdigest(), findings=findings)
            except (ValueError, UnicodeError) as exc:
                errors.append(dict(path=name, error=str(exc)))
    for name in dict.fromkeys(selected):
        try:
            data = pak.read(name)
            metadata = package_names(data)
            probe = dict(path=name, sha256=hashlib.sha256(data).hexdigest(), **metadata)
            if any(e["class_name"] == "DataTable" for e in metadata["exports"]):
                payload_path = name.rsplit(".", 1)[0] + ".uexp"
                payload = pak.read(payload_path)
                probe["table_schema"] = table_schema(payload, metadata, len(data))
                probe["uexp_sha256"] = hashlib.sha256(payload).hexdigest()
            elif not name.endswith(".umap"):
                payload = pak.read(name.rsplit(".", 1)[0] + ".uexp")
                defaults = []
                for export in metadata["exports"]:
                    interesting = export["class_name"] in ("CameraComponent", "SpringArmComponent", "JHSpringArmComponent", "PaperSprite", "PaperFlipbook", "Texture2D", "CharacterMovementComponent", "JHPaperFlipbookComponent")
                    interesting = interesting or (name.endswith("/BP_SceneHero.uasset") and export["name"] == "SpriteSceneComponent")
                    interesting = interesting or export["name"].startswith("Default__BP_SceneHero")
                    if interesting:
                        reader = Reader(payload)
                        reader.pos = export["serial_offset"] - len(data)
                        props = property_tags(reader, metadata["names"])
                        if reader.pos > export["serial_offset"] - len(data) + export["serial_size"]:
                            raise ValueError("Properties exceed export bounds")
                        defaults.append(dict(export=export["name"], class_name=export["class_name"], properties=props))
                probe["object_properties"] = defaults
                probe["uexp_sha256"] = hashlib.sha256(payload).hexdigest()
            probes.append(probe)
        except (ValueError, UnicodeError, zlib.error, struct.error) as exc:
            errors.append(dict(path=name, error=str(exc)))
    after = digest_file(pak_path)
    if before != after:
        raise ValueError("Source PAK changed during study")
    exe = game / "Wandering_Sword/Binaries/Win64/JH-Win64-Shipping.exe"
    with exe.open("rb") as stream, mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_READ) as mapped:
        branches = [dict(offset=match.start(), encoding="ascii", value=match.group().decode("ascii"))
                    for match in re.finditer(rb"\+\+UE4\+Release-[0-9.]+", mapped)]
        wide_pattern = rb"(?:\+\x00){2}U\x00E\x004\x00\+\x00R\x00e\x00l\x00e\x00a\x00s\x00e\x00-\x00(?:[0-9.]\x00)+"
        branches += [dict(offset=match.start(), encoding="utf-16-le", value=match.group().decode("utf-16-le"))
                     for match in re.finditer(wide_pattern, mapped)]
    manifest = dict(game="Wandering Sword", steam_appid=1876890, pak=str(pak_path),
                    binary_engine_branch_evidence=branches, executable_sha256=digest_file(exe),
                    pak_bytes=pak.size, pak_sha256_before=before, pak_sha256_after=after,
                    source_unchanged=before == after, footer=pak.footer, mount_point=pak.mount,
                    entry_count=pak.count, verified_index_sha1s=pak.checked_indexes,
                    extensions=dict(extensions.most_common()), top_folders=dict(folders.most_common(60)),
                    payloads_read=len(pak.verified_payloads), packages_read=len(probes),
                    tables_decoded=sum("table_schema" in p for p in probes),
                    verified_payload_paths=sorted(pak.verified_payloads),
                    encrypted_payloads=sum(e["encrypted"] for e in pak.entries.values()),
                    errors=errors)
    save_json(output / "manifest.json", manifest)
    save_json(output / "configuration-study.json", configs)
    save_json(output / "package-name-study.json", probes)
    save_json(output / "tables-summary.json", [dict(path=p["path"], **p["table_schema"])
              for p in probes if "table_schema" in p])
    save_json(output / "rendering-study.json", [dict(path=p["path"],
              export_classes=p["export_classes"], object_properties=p.get("object_properties", []))
              for p in probes if p["path"].endswith(".umap") or p.get("object_properties")])
    # A shortlist for follow-up investigation, classified by path only.
    patterns = dict(tables=r"/Tables/.*\.uasset$", maps=r"\.umap$",
                    camera=r"camera.*\.uasset$", materials=r"/Materials?/.*\.uasset$",
                    sprites=r"(sprite|flipbook|paper2d).*\.uasset$",
                    combat=r"(combat|battle|skill|ability).*\.uasset$",
                    characters=r"(character|animation|anim).*\.uasset$")
    shortlist = {}
    for category, pattern in patterns.items():
        matches = sorted(p for p in pak.entries if re.search(pattern, p, re.I))
        shortlist[category] = dict(count=len(matches), classification="path regex, not validated asset type",
                                  sample_limit=100, paths=matches[:100])
    save_json(output / "systems-index.json", shortlist)
    print(json.dumps({k: manifest[k] for k in ("pak_bytes", "entry_count", "source_unchanged",
                     "verified_index_sha1s", "packages_read", "encrypted_payloads", "errors")}, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game", type=Path, default=Path(
        "C:/Program Files (x86)/Steam/steamapps/common/Wandering Sword"))
    parser.add_argument("--output", type=Path, default=Path("reference-study/wandering-sword"))
    args = parser.parse_args()
    analyze(args.game, args.output)
