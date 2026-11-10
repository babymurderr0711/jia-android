from pathlib import Path
from urllib.request import urlretrieve
from PIL import Image, ImageDraw, ImageChops

URL = "https://d2ol7oe51mr4n9.cloudfront.net/user_3KVjsYRNFpU20FJN3DkQrjG4WtZ/a0f83349-0ea9-4a7c-845e-f1d7805eb619.png"
root = Path(__file__).resolve().parent
assets = root / "assets"
assets.mkdir(exist_ok=True)
source = Path("/tmp/jia_turnaround_source.img")
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
    "head": [(40,0),(300,0),(330,60),(315,190),(280,250),(220,280),(120,275),(65,230),(35,150)],
    "torso": [(65,200),(310,200),(310,430),(290,500),(270,550),(100,550),(75,500),(55,420)],
    "upper_arm_l": [(65,205),(130,210),(125,330),(115,410),(90,460),(55,450),(50,370),(55,270)],
    "forearm_l": [(55,400),(105,400),(90,520),(75,630),(55,710),(15,710),(12,640),(35,510)],
    "upper_arm_r": [(245,205),(310,200),(320,270),(320,370),(315,450),(280,460),(255,410),(245,330)],
    "forearm_r": [(280,400),(325,400),(340,510),(360,640),(365,710),(325,710),(305,630),(285,520)],
    "thigh_l": [(35,470),(190,470),(200,600),(190,760),(160,870),(100,880),(45,820),(20,670)],
    "thigh_r": [(180,470),(335,470),(350,650),(315,820),(270,880),(210,870),(180,760),(170,600)],
    "shin_l": [(90,820),(180,820),(185,1020),(175,1220),(160,1320),(110,1320),(85,1220),(85,1020)],
    "shin_r": [(200,820),(290,820),(295,1020),(285,1220),(270,1320),(220,1320),(200,1220),(195,1020)],
    "foot_l": [(90,1190),(165,1190),(180,1320),(185,1450),(170,1518),(105,1518),(85,1450)],
    "foot_r": [(205,1190),(285,1190),(295,1450),(275,1518),(210,1518),(195,1450)],

}
for name, polygon in masks.items():
    mask = Image.new("L", front.size, 0)
    ImageDraw.Draw(mask).polygon(polygon, fill=255)
    # Feather only a tiny amount to avoid hard cut seams while preserving pixel-art edges.
    layer = front.copy()
    # Intersect the body-part mask with the source transparency. Never turn
    # transparent background pixels opaque inside a polygon.
    layer.putalpha(ImageChops.multiply(front.getchannel("A"), mask))
    layer.save(assets / f"jia_{name}.png", optimize=True)
print("Prepared registered cutouts:", ", ".join(masks))
