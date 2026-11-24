"""Checks for malformed inputs and the explicit encryption boundary of the study reader."""
import hashlib
from contextlib import contextmanager
import os
from pathlib import Path
import struct
import tempfile
import unittest

from inspect_wandering_sword import Pak, Reader, package_names, property_tags


@contextmanager
def fixture(data):
    root = Path(__file__).resolve().parents[1] / ".qa-runtime/wandering-sword-reader-tests"
    root.mkdir(parents=True, exist_ok=True)
    descriptor, name = tempfile.mkstemp(suffix=".pak", dir=root)
    os.close(descriptor)
    path = Path(name)
    try:
        path.write_bytes(data)
        yield path
    finally:
        path.unlink()


class StudyReaderTests(unittest.TestCase):
    def test_utf16_and_utf8_fstrings(self):
        text = "água"
        utf16 = text.encode("utf-16-le") + b"\0\0"
        self.assertEqual(Reader(struct.pack("<i", -5) + utf16).string(), text)
        utf8 = text.encode("utf-8") + b"\0"
        self.assertEqual(Reader(struct.pack("<i", len(utf8)) + utf8).string(), text)

    def test_truncated_string(self):
        with self.assertRaises(ValueError):
            Reader(struct.pack("<i", 100) + b"x").string()

    def test_unterminated_string(self):
        with self.assertRaises(ValueError):
            Reader(struct.pack("<i", 2) + b"xx").string()

    def test_negative_read(self):
        with self.assertRaises(ValueError):
            Reader(b"abc").take(-1)

    def test_non_package(self):
        with self.assertRaises(ValueError):
            package_names(b"test" + b"\0" * 64)

    def test_tagged_float_and_boolean(self):
        names = ["None", "Speed", "FloatProperty", "Visible", "BoolProperty"]
        data = struct.pack("<iiiiiiBf", 1, 0, 2, 0, 4, 0, 0, 10.0)
        data += struct.pack("<iiiiiiBB", 3, 0, 4, 0, 0, 0, 1, 0)
        data += struct.pack("<ii", 0, 0)
        reader = Reader(data)
        tags = property_tags(reader, names)
        self.assertEqual([t["value"] for t in tags], [10.0, True])
        self.assertEqual(reader.pos, len(data))

    def test_invalid_property_name(self):
        with self.assertRaises(ValueError):
            property_tags(Reader(struct.pack("<ii", 100, 0)), ["None"])

    def test_corrupt_index_hash(self):
        with fixture(b"index") as path:
            pak = object.__new__(Pak)
            pak.path, pak.size, pak.checked_indexes = path, 5, []
            self.assertEqual(pak.region(0, 5, hashlib.sha1(b"index").hexdigest(), "test"), b"index")
            with self.assertRaises(ValueError):
                pak.region(0, 5, "0" * 40, "test")
            with self.assertRaises(ValueError):
                pak.region(1, 5, "0" * 40, "test")

    def test_encrypted_index_is_not_read(self):
        footer = b"\0" * 16 + b"\x01" + struct.pack("<IIQQ", 0x5A6F12E1, 11, 0, 0)
        footer += b"\0" * (20 + 160)
        self.assertEqual(len(footer), 221)
        with fixture(footer) as path:
            with self.assertRaisesRegex(ValueError, "Encrypted index"):
                Pak(path)


if __name__ == "__main__":
    unittest.main()
