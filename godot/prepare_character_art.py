from pathlib import Path
from urllib.request import urlretrieve
from PIL import Image

URL = "https://d2ol7oe51mr4n9.cloudfront.net/user_3KVjsYRNFpU20FJN3DkQrjG4WtZ/26e54013-4374-4b8d-8ee2-3de15df0d3f6.png"
root = Path(__file__).resolve().parent
assets = root / "assets"
assets.mkdir(exist_ok=True)
source = assets / "jia_turnaround_source.png"
urlretrieve(URL, source)
image = Image.open(source).convert("RGBA")
# The first quarter of the turnaround is the full frontal view.
front = image.crop((0, 0, 380, 1260))
pixels = front.load()
for y in range(front.height):
    for x in range(front.width):
        r, g, b, a = pixels[x, y]
        # Remove the pure black presentation background while preserving dark line art.
        if max(r, g, b) < 18:
            pixels[x, y] = (r, g, b, 0)
        elif max(r, g, b) < 42:
            pixels[x, y] = (r, g, b, int((max(r, g, b) - 18) / 24 * 255))
front.save(assets / "jia_front.png", optimize=True)
print(f"Prepared frontal character texture: {front.size}")
