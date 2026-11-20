"""Build the macOS icon family and caption image from the approved square PNG."""
from pathlib import Path
import struct
import subprocess
import sys

source, destination, scratch = map(Path, sys.argv[1:])
representations = [
    ("icp4", 16), ("ic11", 32), ("icp5", 32), ("ic12", 64),
    ("ic07", 128), ("ic13", 256), ("ic08", 256), ("ic14", 512),
    ("ic09", 512), ("ic10", 1024),
]

chunks = []
for kind, size in representations:
    png = scratch / f"{size}.png"
    if not png.exists():
        subprocess.run(
            ["sips", "-z", str(size), str(size), str(source), "--out", str(png)],
            check=True, stdout=subprocess.DEVNULL,
        )
    image = png.read_bytes()
    chunks.append(kind.encode("ascii") + struct.pack(">I", len(image) + 8) + image)

body = b"".join(chunks)
destination.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)
