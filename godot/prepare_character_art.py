from pathlib import Path
from urllib.request import urlretrieve
from PIL import Image

URL = "https://d2ol7oe51mr4n9.cloudfront.net/user_3KVjsYRNFpU20FJN3DkQrjG4WtZ/a0f83349-0ea9-4a7c-845e-f1d7805eb619.png"
root = Path(__file__).resolve().parent
assets = root / "assets"
assets.mkdir(exist_ok=True)
source = assets / "jia_turnaround_source.png"
urlretrieve(URL, source)
image = Image.open(source).convert("RGBA")
# Four-view sheet: isolate the frontal standing figure.
front = image.crop((0, 0, 370, 1536))
pixels = front.load()
for y in range(front.height):
    for x in range(front.width):
        r, g, b, a = pixels[x, y]
        brightness = max(r, g, b)
        if brightness < 18:
            pixels[x, y] = (r, g, b, 0)
        elif brightness < 42:
            pixels[x, y] = (r, g, b, int((brightness - 18) / 24 * 255))
bbox = front.getbbox()
if bbox:
    front = front.crop(bbox)
front.save(assets / "jia_front.png", optimize=True)
print(f"Prepared Jia frontal sprite: {front.size}")
