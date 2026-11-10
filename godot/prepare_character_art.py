from pathlib import Path
from urllib.request import urlretrieve
from PIL import Image, ImageDraw

URL = "https://d2ol7oe51mr4n9.cloudfront.net/user_3KVjsYRNFpU20FJN3DkQrjG4WtZ/a0f83349-0ea9-4a7c-845e-f1d7805eb619.png"
root = Path(__file__).resolve().parent
assets = root / "assets"
assets.mkdir(exist_ok=True)
source = assets / "jia_turnaround_source.png"
urlretrieve(URL, source)
sheet = Image.open(source).convert("RGBA")
front = sheet.crop((0, 0, 370, 1536))
px = front.load()
for y in range(front.height):
    for x in range(front.width):
        r, g, b, a = px[x, y]
        v = max(r, g, b)
        if v < 18:
            px[x, y] = (r, g, b, 0)
        elif v < 42:
            px[x, y] = (r, g, b, int((v - 18) / 24 * 255))
front.save(assets / "jia_front.png", optimize=True)

# Approximate overlapping cut-out masks in the frontal view. Each stays on
# the same 370x1536 canvas so all parts retain exact registration.
masks = {
    "head": [(65,5),(260,0),(310,60),(300,175),(265,235),(220,265),(135,260),(75,220),(45,145),(48,65)],
    "torso": [(105,205),(145,190),(205,190),(265,205),(300,260),(292,390),(270,470),(235,525),(130,525),(95,465),(75,350),(78,260)],
    "arm_l": [(92,215),(118,235),(108,355),(92,475),(72,600),(52,690),(28,690),(18,645),(38,520),(50,390),(58,270)],
    "arm_r": [(270,215),(295,235),(315,280),(325,410),(345,540),(365,645),(355,695),(330,695),(310,610),(292,480),(275,350)],
    "thigh_l": [(95,455),(165,485),(185,565),(180,720),(150,835),(105,850),(60,780),(35,650),(48,540)],
    "thigh_r": [(205,485),(275,455),(320,540),(335,650),(300,780),(255,850),(210,835),(185,720),(180,565)],
    "shin_l": [(105,805),(150,805),(165,880),(155,1040),(150,1180),(125,1240),(100,1200),(92,1080),(95,930)],
    "shin_r": [(220,805),(265,805),(275,930),(278,1080),(270,1200),(245,1240),(220,1180),(215,1040),(205,880)],
}
for name, polygon in masks.items():
    mask = Image.new("L", front.size, 0)
    ImageDraw.Draw(mask).polygon(polygon, fill=255)
    # Feather only a tiny amount to avoid hard cut seams while preserving pixel-art edges.
    layer = front.copy()
    layer.putalpha(Image.eval(mask, lambda value: value))
    layer.save(assets / f"jia_{name}.png", optimize=True)
print("Prepared registered cutouts:", ", ".join(masks))
