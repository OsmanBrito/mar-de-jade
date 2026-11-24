"""Read-only inventory and cooked-package metadata study of the local Resonance demo.

Handles standard unencrypted IoStore v8 and v11 PAK metadata. Oodle decoding
uses an explicitly supplied local library; this script never downloads tools.
"""
from __future__ import annotations
import argparse
from collections import Counter
import csv
import ctypes
import gzip
import hashlib
import json
from pathlib import Path
import re
import struct
import zlib

from inspect_wandering_sword import Pak, Reader, digest_file, save_json

STEAM = Path("C:/Program Files (x86)/Steam/steamapps")
GAME = STEAM / "common/FINAL FANTASY RESONANCE DEMO"
INVALID = 0xFFFFFFFF


class Oodle:
    def __init__(self, path: Path):
        self.path = path.resolve()
        self.sha256 = digest_file(self.path)
        self.library = ctypes.CDLL(str(self.path))
        self.function = self.library.OodleLZ_Decompress
        pointer, size, integer = ctypes.c_void_p, ctypes.c_ssize_t, ctypes.c_int
        self.function.argtypes = [pointer, size, pointer, size, integer, integer, integer,
                                  pointer, size, pointer, pointer, pointer, size, integer]
        self.function.restype = size

    def __call__(self, data: bytes, expected: int) -> bytes:
        if not 0 < expected <= 64 * 1024 * 1024:
            raise ValueError("Invalid Oodle target size")
        source = ctypes.create_string_buffer(data)
        target = ctypes.create_string_buffer(expected)
        count = self.function(source, len(data), target, expected, 1, 0, 0,
                              None, 0, None, None, None, 0, 3)
        if count != expected:
            raise ValueError(f"Oodle decoded {count} bytes, expected {expected}")
        return target.raw


def name_batch(reader: Reader) -> list[str]:
    count = reader.number("i")
    if not 0 <= count <= 500_000:
        raise ValueError("Invalid name batch count")
    if not count:
        return []
    byte_count = reader.number("I")
    reader.take(8 + count * 8)  # Hash version and per-name hashes.
    headers = reader.take(count * 2)
    start = reader.pos
    names = []
    for i in range(count):
        high, low = headers[i * 2:i * 2 + 2]
        length = ((high & 127) << 8) | low
        wide = bool(high & 128)
        names.append(reader.take(length * (2 if wide else 1)).decode("utf-16-le" if wide else "utf-8"))
    if reader.pos - start != byte_count:
        raise ValueError("Name batch byte count mismatch")
    return names


class IoStore:
    def __init__(self, path: Path, decoder=None):
        self.path = path
        self.ucas = path.with_suffix(".ucas")
        self.decoder = decoder
        self.read_chunks = set()
        data = path.read_bytes()
        self.toc_sha256 = hashlib.sha256(data).hexdigest()
        reader = Reader(data)
        if reader.take(16) != b"-==--==--==--==-":
            raise ValueError("Invalid IoStore TOC magic")
        version = reader.number("B")
        reader.take(3)
        if version != 8:
            raise ValueError(f"Unsupported IoStore version {version}; expected 8")
        keys = ("header_size", "chunk_count", "block_count", "block_entry_size", "method_count",
                "method_name_length", "block_size", "directory_size", "partition_count")
        header = {key: reader.number("I") for key in keys}
        header.update(version=version, container_id=reader.number("Q"), encryption_guid=reader.take(16).hex())
        flags = reader.number("B")
        reader.take(3)
        seeds = reader.number("I")
        partition_size = reader.number("Q")
        overflow = reader.number("I")
        header.update(flags=flags, encrypted=bool(flags & 2), signed=bool(flags & 4),
                      indexed=bool(flags & 8), partition_size=partition_size)
        if header["header_size"] != 144 or header["block_entry_size"] != 12:
            raise ValueError("Unsupported IoStore header/block size")
        if header["partition_count"] != 1:
            raise ValueError("This study handles single-partition containers only")
        self.header = header
        reader.pos = 144
        count = header["chunk_count"]
        ids = [reader.take(12) for _ in range(count)]
        self.chunks = []
        for identifier in ids:
            raw = reader.take(10)
            self.chunks.append(dict(id=identifier.hex(), package_id=int.from_bytes(identifier[:8], "little"),
                                    type=identifier[11], offset=int.from_bytes(raw[:5], "big"),
                                    size=int.from_bytes(raw[5:], "big")))
        reader.take((seeds + overflow) * 4)
        self.blocks = []
        ucas_size = self.ucas.stat().st_size
        for _ in range(header["block_count"]):
            raw = reader.take(12)
            block = dict(offset=int.from_bytes(raw[:5], "little"), stored=int.from_bytes(raw[5:8], "little"),
                         size=int.from_bytes(raw[8:11], "little"), method=raw[11])
            if block["offset"] + block["stored"] > ucas_size or block["method"] > header["method_count"]:
                raise ValueError("IoStore block exceeds its container or references invalid codec")
            self.blocks.append(block)
        self.methods = ["None"] + [reader.take(header["method_name_length"]).split(b"\0", 1)[0].decode("ascii")
                                   for _ in range(header["method_count"])]
        if header["signed"]:
            signature_size = reader.number("i")
            reader.take(signature_size * 2 + header["block_count"] * 20)
        self.entries = {}
        self.mount = ""
        self.directory_offset = reader.pos
        if header["indexed"] and not header["encrypted"]:
            self._directory(reader.take(header["directory_size"]))
        # v8 metadata is a 20-byte IoHash, one flag byte and 3 bytes of padding.
        expected_meta_end = self.directory_offset + header["directory_size"] + count * 24
        if expected_meta_end != len(data):
            raise ValueError(f"Unexpected TOC trailer size {len(data) - expected_meta_end}")
        self.chunk_types = dict(Counter(c["type"] for c in self.chunks))
        self.block_methods = dict(Counter(self.methods[b["method"]] for b in self.blocks))

    def _directory(self, data: bytes) -> None:
        reader = Reader(data)
        self.mount = reader.string()
        directories = [tuple(reader.number("I") for _ in range(4)) for _ in range(reader.number("I"))]
        files = [tuple(reader.number("I") for _ in range(3)) for _ in range(reader.number("I"))]
        strings = [reader.string() for _ in range(reader.number("I"))]
        if any(reader.take(len(data) - reader.pos)):
            raise ValueError("Unexpected directory index trailing data")
        stack = [(0, "")]
        seen_dirs, seen_files = set(), set()
        while stack:
            index, prefix = stack.pop()
            if index in seen_dirs or not 0 <= index < len(directories):
                raise ValueError("Invalid/cyclic directory tree")
            seen_dirs.add(index)
            name, child, sibling, file = directories[index]
            current = prefix + (strings[name] + "/" if name != INVALID else "")
            if sibling != INVALID:
                stack.append((sibling, prefix))
            if child != INVALID:
                stack.append((child, current))
            while file != INVALID:
                if file in seen_files or not 0 <= file < len(files):
                    raise ValueError("Invalid/cyclic directory file list")
                seen_files.add(file)
                name_index, next_file, chunk_index = files[file]
                if not 0 <= chunk_index < len(self.chunks):
                    raise ValueError("File references invalid chunk")
                path = current + strings[name_index]
                if path in self.entries:
                    raise ValueError("Duplicate directory path")
                self.entries[path] = chunk_index
                file = next_file
        if len(seen_dirs) != len(directories) or len(seen_files) != len(files):
            raise ValueError("Directory contains unreachable entries")

    def read(self, index: int, maximum=32 * 1024 * 1024) -> bytes:
        if self.header["encrypted"]:
            raise ValueError("Encrypted IoStore data is not decoded")
        chunk = self.chunks[index]
        if chunk["size"] > maximum:
            raise ValueError("Chunk exceeds study limit")
        block_size = self.header["block_size"]
        first = chunk["offset"] // block_size
        last = (chunk["offset"] + chunk["size"] + block_size - 1) // block_size
        decoded = []
        with self.ucas.open("rb") as stream:
            for block in self.blocks[first:last]:
                stream.seek(block["offset"])
                raw = stream.read(block["stored"])
                method = self.methods[block["method"]]
                if method == "None":
                    value = raw
                elif method == "Oodle" and self.decoder:
                    value = self.decoder(raw, block["size"])
                elif method in ("Zlib", "Gzip"):
                    value = zlib.decompress(raw, 31 if method == "Gzip" else 15)
                else:
                    raise ValueError(f"Unsupported chunk compression {method}")
                if len(value) != block["size"]:
                    raise ValueError("Incorrect decompressed block size")
                decoded.append(value)
        start = chunk["offset"] - first * block_size
        result = b"".join(decoded)[start:start + chunk["size"]]
        if len(result) != chunk["size"]:
            raise ValueError("Incomplete chunk")
        self.read_chunks.add(index)
        return result


def zen_names(data: bytes) -> dict:
    reader = Reader(data)
    has_version, header_size = reader.number("I"), reader.number("I")
    name_index, name_number = reader.number("I"), reader.number("I")
    flags, cooked_size = reader.number("I"), reader.number("I")
    offsets = [reader.number("i") for _ in range(7)]
    if has_version not in (0, 1) or not 52 <= header_size <= len(data):
        raise ValueError("Unsupported Zen package summary")
    versioning = None
    if has_version:
        versioning = dict(zen=reader.number("I"), ue4=reader.number("i"), ue5=reader.number("i"), licensee=reader.number("i"))
        reader.take(reader.number("i") * 20)
    name_start = reader.pos
    # Verse-capable UE5 layouts add two cell offsets before the name batch.
    errors = []
    names = []
    for pad in (0, 8):
        try:
            reader.pos = name_start + pad
            names = name_batch(reader)
            package_name = names[name_index & 0x3FFFFFFF]
            if not package_name.startswith("/") or reader.pos > offsets[0]:
                raise ValueError("Invalid package name/name map bounds")
            break
        except (ValueError, IndexError, UnicodeError) as exc:
            errors.append(str(exc))
    else:
        raise ValueError("Cannot validate Zen name batch: " + "; ".join(errors))
    export_start, bundle_start = offsets[2:4]
    if not 0 <= export_start <= bundle_start <= header_size or (bundle_start - export_start) % 72:
        raise ValueError("Invalid Zen export map bounds")
    exports = []
    for at in range(export_start, bundle_start, 72):
        serial_at, serial_size, export_name, export_number = struct.unpack_from("<QQII", data, at)
        if export_name >> 30:
            raise ValueError("Unsupported nonlocal export name map")
        exports.append(dict(name=names[export_name], serial_offset=serial_at, serial_size=serial_size,
                            class_index=f"{struct.unpack_from('<Q', data, at + 32)[0]:016x}"))
    return dict(package_name=package_name, name_count=len(names), names=names, package_flags=f"0x{flags:08x}",
                unversioned_properties=bool(flags & 0x2000), header_size=header_size,
                cooked_header_size=cooked_size, versioning=versioning,
                name_batch_offset=name_start + pad, exports=exports)


def write_index(path: Path, rows: list[dict]) -> None:
    if not rows:
        return
    with gzip.open(path, "wt", encoding="utf-8-sig", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def analyze(game: Path, output: Path, decoder_path: Path) -> None:
    game, output = game.resolve(), output.resolve()
    if game == output or game in output.parents:
        raise ValueError("Study output must be outside the game installation")
    containers = sorted((game / "FFRS/Content/Paks").glob("*"))
    if not containers:
        raise ValueError("The demo installation is missing or incomplete")
    output.mkdir(parents=True, exist_ok=True)
    (output / ".gdignore").write_text("", encoding="utf-8")
    before = {str(p.relative_to(game)): dict(bytes=p.stat().st_size, sha256=digest_file(p)) for p in containers if p.is_file()}
    decoder = Oodle(decoder_path)
    pak = Pak(game / "FFRS/Content/Paks/FFRS-Windows.pak")
    store = IoStore(game / "FFRS/Content/Paks/FFRS-Windows.utoc", decoder)
    write_index(output / "pak-index.csv.gz", [dict(path=p, size=e["size"], stored=e["stored"], offset=e["offset"], method=e["method"], encrypted=e["encrypted"]) for p, e in sorted(pak.entries.items())])
    write_index(output / "iostore-index.csv.gz", [dict(path=p, chunk_index=i, **store.chunks[i]) for p, i in sorted(store.entries.items())])
    configs, errors = {}, []
    for name in pak.entries:
        if name.startswith("FFRS/") and (name.endswith((".uproject", "DefaultEngine.ini", "DefaultGame.ini", "DefaultInput.ini", "DefaultDeviceProfiles.ini", "DefaultScalability.ini")) or name.endswith("Build.version")):
            try:
                data = pak.read(name, oodle_decoder=decoder)
                text = data.decode("utf-8-sig")
                if name.endswith((".uproject", "Build.version")):
                    findings = json.loads(text)
                    if name.endswith(".uproject"):
                        findings = {k: findings[k] for k in ("FileVersion", "EngineAssociation", "Modules", "Plugins", "TargetPlatforms") if k in findings}
                else:
                    findings = [line for line in text.splitlines() if re.search(r"^(\[|r\.|\+?TextureLODGroups|GameDefaultMap|GlobalDefaultGameMode|NearClipPlane|bUseFixedFrameRate|FixedFrameRate|MinDesiredFrameRate)", line)]
                configs[name] = dict(sha256=hashlib.sha256(data).hexdigest(), findings=findings)
            except (ValueError, UnicodeError, json.JSONDecodeError) as exc:
                errors.append(dict(path=name, error=str(exc)))
    candidates = sorted(p for p in store.entries if p.startswith("FFRS/Content/") and p.endswith((".uasset", ".umap")))
    selected = []
    for pattern, limit in ((r"/BP/Camera/", 80), (r"/(?:Data|DataTable|Tables)/|/DT_", 24),
                           (r"(flipbook|sprite|paper2d)", 8), (r"/Chara/Field_Unit/", 12), (r"(BP_Player|BP_Hero|BP_Character)", 8),
                           (r"\.umap$", 6)):
        selected += [p for p in candidates if re.search(pattern, p, re.I)][:limit]
    probes = []
    for name in dict.fromkeys(selected):
        try:
            data = store.read(store.entries[name])
            probes.append(dict(path=name, sha256=hashlib.sha256(data).hexdigest(), **zen_names(data)))
        except (ValueError, IndexError, UnicodeError, struct.error) as exc:
            errors.append(dict(path=name, error=str(exc)))
    after = {str(p.relative_to(game)): dict(bytes=p.stat().st_size, sha256=digest_file(p)) for p in containers if p.is_file()}
    if before != after:
        raise ValueError("Source container changed during study")
    manifest = dict(game="FINAL FANTASY RESONANCE DEMO", appid=4474710, source=str(game),
                    build_id=24032336, source_containers=before, source_unchanged=True,
                    pak_entry_count=pak.count, pak_footer=pak.footer, pak_verified_indexes=pak.checked_indexes,
                    pak_payloads_verified=sorted(pak.verified_payloads), iostore_header=store.header,
                    iostore_mount=store.mount, iostore_file_count=len(store.entries),
                    chunk_types=store.chunk_types, compression_blocks=store.block_methods,
                    metadata_packages_read=len(probes), iostore_chunks_decompressed=len(store.read_chunks),
                    decoder=dict(path=str(decoder.path), sha256=decoder.sha256),
                    errors=errors)
    save_json(output / "manifest.json", manifest)
    save_json(output / "configuration-study.json", configs)
    save_json(output / "package-name-study.json", probes)
    save_json(output / "content-summary.json", dict(extensions=dict(Counter(Path(p).suffix for p in store.entries)),
              top_folders=dict(Counter('/'.join(p.split('/')[:4]) for p in store.entries).most_common(50)),
              camera_paths=[p for p in candidates if re.search('camera', p, re.I)],
              table_candidate_paths=[p for p in candidates if re.search(r'/DT_|/DataTable|/Tables/', p, re.I)],
              map_paths=[p for p in candidates if p.endswith('.umap')]))
    print(json.dumps({k:manifest[k] for k in ("pak_entry_count", "iostore_file_count", "iostore_chunks_decompressed", "metadata_packages_read", "source_unchanged", "errors")}, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game", type=Path, default=GAME)
    parser.add_argument("--output", type=Path, default=Path("reference-study/ff-resonance"))
    parser.add_argument("--oodle", type=Path, default=Path(".tools/ffresonance/oodle-data-shared.dll"))
    args = parser.parse_args()
    analyze(args.game, args.output, args.oodle)
