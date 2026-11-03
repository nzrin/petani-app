#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ANDROID_SCREENSHOTS = Path(
    "/Volumes/Development/Assets/Petani/screenshot/Actual/Android"
)
FONTS = ROOT / "assets" / "fonts"


def rgba(hex_value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_value.lstrip("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4)) + (alpha,)


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / name), size=size)


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    from PIL import ImageOps

    return ImageOps.fit(image, size, method=Image.Resampling.LANCZOS)


def device_mockup(screen: Image.Image, target_width: int) -> Image.Image:
    ratio = screen.height / screen.width
    outer_width = target_width
    outer_height = round(target_width * ratio)
    bezel = max(12, round(target_width * 0.034))
    radius = max(30, round(target_width * 0.105))
    padding = max(28, round(target_width * 0.09))
    result = Image.new(
        "RGBA",
        (outer_width + padding * 2, outer_height + padding * 2),
        (0, 0, 0, 0),
    )

    shadow = Image.new("RGBA", result.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        (
            padding,
            padding + round(padding * 0.34),
            padding + outer_width,
            padding + outer_height + round(padding * 0.34),
        ),
        radius=radius,
        fill=rgba("#001E15", 145),
    )
    result.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(max(15, padding // 2))))

    draw = ImageDraw.Draw(result)
    draw.rounded_rectangle(
        (padding, padding, padding + outer_width, padding + outer_height),
        radius=radius,
        fill=rgba("#101614"),
        outline=rgba("#50645B"),
        width=max(4, bezel // 4),
    )
    inner_size = (outer_width - bezel * 2, outer_height - bezel * 2)
    fitted = cover(screen.convert("RGBA"), inner_size)
    mask = Image.new("L", inner_size, 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle(
        (0, 0, inner_size[0], inner_size[1]),
        radius=max(22, radius - bezel),
        fill=255,
    )
    result.paste(fitted, (padding + bezel, padding + bezel), mask)
    return result


def draw_multiline(
    draw: ImageDraw.ImageDraw,
    lines: list[str],
    position: tuple[int, int],
    face,
    fill: tuple[int, int, int, int],
    line_height: int,
) -> None:
    x, y = position
    for line in lines:
        draw.text((x, y), line, font=face, fill=fill)
        y += line_height


def render(background_path: Path, output_path: Path) -> None:
    scale = 2
    width, height = 1024 * scale, 500 * scale
    background = Image.open(background_path).convert("RGB")
    canvas = cover(background, (width, height)).convert("RGBA")

    # Improve text contrast while retaining the generated organic light on the right.
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    overlay_pixels = overlay.load()
    for x in range(width):
        amount = int(116 * max(0.0, 1.0 - x / (width * 0.7)))
        for y in range(height):
            overlay_pixels[x, y] = (0, 42, 28, amount)
    canvas.alpha_composite(overlay)

    draw = ImageDraw.Draw(canvas)
    left = 52 * scale
    tag_y = 34 * scale
    tag_font = font("ProductSans-Bold.ttf", 17 * scale)
    tag_text = "APLIKASI PETANI"
    tag_box = draw.textbbox((0, 0), tag_text, font=tag_font)
    tag_width = tag_box[2] - tag_box[0]
    tag_height = tag_box[3] - tag_box[1]
    tag_padding_x = 14 * scale
    tag_padding_y = 7 * scale
    draw.rectangle(
        (
            left,
            tag_y,
            left + tag_width + tag_padding_x * 2,
            tag_y + tag_height + tag_padding_y * 2,
        ),
        fill=rgba("#FFC94D"),
    )
    draw.text(
        (left + tag_padding_x, tag_y + tag_padding_y - 2 * scale),
        tag_text,
        font=tag_font,
        fill=rgba("#143124"),
    )

    title_font = font("ProductSans-Black.ttf", 45 * scale)
    draw_multiline(
        draw,
        ["Satu aplikasi", "untuk pengurusan", "tanaman yang", "lebih teratur"],
        (left, 84 * scale),
        title_font,
        rgba("#FFFFFF"),
        49 * scale,
    )

    description_font = font("ProductSans-Regular.ttf", 17 * scale)
    draw_multiline(
        draw,
        ["Urus plot, rancang tugasan dan simpan", "perkembangan kebun dalam satu tempat."],
        (left, 305 * scale),
        description_font,
        rgba("#F4F8F5", 235),
        25 * scale,
    )

    chip_box = (left, 390 * scale, 397 * scale, 438 * scale)
    chip = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    chip_draw = ImageDraw.Draw(chip)
    chip_draw.rounded_rectangle(
        chip_box,
        radius=24 * scale,
        fill=rgba("#FFFFFF", 34),
        outline=rgba("#FFFFFF", 72),
        width=1 * scale,
    )
    canvas.alpha_composite(chip)
    chip_font = font("ProductSans-Medium.ttf", 16 * scale)
    chip_text = "Plot  •  Tugasan  •  Laporan"
    chip_text_box = draw.textbbox((0, 0), chip_text, font=chip_font)
    chip_text_width = chip_text_box[2] - chip_text_box[0]
    draw.text(
        ((chip_box[0] + chip_box[2] - chip_text_width) // 2, 404 * scale),
        chip_text,
        font=chip_font,
        fill=rgba("#FFFFFF"),
    )

    source_files = sorted(ANDROID_SCREENSHOTS.glob("*.png"))
    if len(source_files) < 19:
        raise RuntimeError(f"Expected Android screenshots, found {len(source_files)}")
    timeline = Image.open(source_files[9]).convert("RGBA")
    add_task = Image.open(source_files[10]).convert("RGBA")

    back = device_mockup(add_task, 300 * scale).rotate(
        -7,
        resample=Image.Resampling.BICUBIC,
        expand=True,
    )
    front = device_mockup(timeline, 315 * scale).rotate(
        7,
        resample=Image.Resampling.BICUBIC,
        expand=True,
    )
    canvas.alpha_composite(back, (500 * scale, 164 * scale))
    canvas.alpha_composite(front, (730 * scale, 155 * scale))

    final = canvas.convert("RGB").resize((1024, 500), Image.Resampling.LANCZOS)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    final.save(output_path, format="JPEG", quality=96, subsampling=0, optimize=True)
    print(f"{output_path} {final.width}x{final.height} {final.mode}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--background", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    render(args.background, args.output)


if __name__ == "__main__":
    main()
