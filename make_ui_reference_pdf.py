from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ui = Path("UI")
output = Path("UI_reference_review.pdf")
files = sorted(ui.glob("*.png"))

W, H = 1920, 1320
BG = (13, 19, 29)
FG = (235, 240, 248)
MUTED = (180, 192, 210)

try:
    font = ImageFont.truetype("arial.ttf", 25)
    small = ImageFont.truetype("arial.ttf", 19)
except OSError:
    font = ImageFont.load_default()
    small = font

pages = []


def add_image_page(path: Path, title: str) -> None:
    """Append a single full-page image spread to the PDF."""
    page = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(page)
    draw.text((35, 20), title, fill=FG, font=font)
    with Image.open(path) as src:
        image = src.convert("RGB")
    image.thumbnail((W - 80, H - 110), Image.Resampling.LANCZOS)
    x = (W - image.width) // 2
    y = 85 + (H - 110 - image.height) // 2
    page.paste(image, (x, y))
    pages.append(page)


# Full-page spreads for overview/composite sheets (larger than standard 1600x900)
for path in files:
    with Image.open(path) as src:
        w, h = src.size
    if w > 1600 or h > 900 or path.name.startswith("R01 "):
        add_image_page(path, path.stem)

# UI screens: 8 per page, 2 columns x 4 rows
for start in range(0, len(files), 8):
    batch = files[start:start + 8]
    page = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(page)
    draw.text(
        (30, 15),
        f"UI REFERENCES — {start + 1} to {start + len(batch)}",
        fill=FG,
        font=font,
    )
    for i, path in enumerate(batch):
        col = i % 2
        row = i // 2
        x = 25 + col * 960
        y = 65 + row * 310
        with Image.open(path) as src:
            image = src.convert("RGB")
        image.thumbnail((910, 268), Image.Resampling.LANCZOS)
        page.paste(image, (x, y))
        draw.text((x, y + image.height + 6), path.stem, fill=MUTED, font=small)
    pages.append(page)

if not pages:
    raise SystemExit(f"No PNG files found in {ui.resolve()}")

pages[0].save(
    output,
    "PDF",
    resolution=100.0,
    save_all=True,
    append_images=pages[1:],
)
print(f"Created {output} with {len(pages)} pages from {len(files)} images.")
