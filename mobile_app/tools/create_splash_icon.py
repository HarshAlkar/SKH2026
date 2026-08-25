"""Create a square splash icon from the VitalReach logo (heart + pill only)."""
from PIL import Image
import numpy as np

SRC = r"assets/images/VitalReach_logo.png"
OUT = r"assets/images/splash_icon.png"
SIZE = 1024
PADDING_RATIO = 0.30  # ~30% padding for Android 12 circular mask

img = Image.open(SRC).convert("RGBA")
arr = np.array(img)

# Non-black, visible pixels
visible = (arr[:, :, 3] > 10) & ~(
    (arr[:, :, 0] < 25) & (arr[:, :, 1] < 25) & (arr[:, :, 2] < 25)
)

# Icon lives in the upper portion (above the wordmark)
height = arr.shape[0]
icon_region = visible & (np.arange(height)[:, None] < int(height * 0.42))

ys, xs = np.where(icon_region)
if ys.size == 0:
    raise SystemExit("Could not detect icon region in logo")

left, top, right, bottom = xs.min(), ys.min(), xs.max(), ys.max()
icon = img.crop((left, top, right + 1, bottom + 1))

# Make square canvas with transparent background
icon_w, icon_h = icon.size
max_dim = max(icon_w, icon_h)
inner = int(SIZE * (1 - 2 * PADDING_RATIO))
scale = inner / max_dim
new_w = max(1, int(icon_w * scale))
new_h = max(1, int(icon_h * scale))
icon = icon.resize((new_w, new_h), Image.Resampling.LANCZOS)

canvas = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
offset = ((SIZE - new_w) // 2, (SIZE - new_h) // 2)
canvas.paste(icon, offset, icon)
canvas.save(OUT)
print(f"Saved {OUT} ({SIZE}x{SIZE})")
