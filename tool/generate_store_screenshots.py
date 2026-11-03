#!/usr/bin/env python3

from __future__ import annotations

import argparse
import gc
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "images"
SOURCE_ROOT = ASSETS / "temporary"
OUTPUT_ROOT = ROOT / "assets" / "temprorary"
HAND_PHONE = OUTPUT_ROOT / "source" / "hand_iphone17_side_raw.png"
HAND_ANDROID_PHONE = OUTPUT_ROOT / "source" / "hand_android_phone_side.png"
HAND_IPAD = OUTPUT_ROOT / "source" / "hand_ipad_pro_side.png"

SPECS = {
    "iPhone_1284x2778": (1284, 2778, "Iphone"),
    "iPad_2048x2732": (2048, 2732, "Ipad"),
    "Android_Phone_1920x3840": (1920, 3840, "Android"),
    "Tablet_1600x2560": (1600, 2560, "Tablet"),
}

FILES = [
    "01_tanaman_lebih_tersusun.jpg",
    "02_semua_dalam_satu_pandangan.jpg",
    "03_urus_projek_dan_plot.jpg",
    "04_tambah_tugasan.jpg",
    "05_jadual_kerja.jpg",
    "06_pantau_setiap_batas.jpg",
    "07_laporan_ladang.jpg",
    "08_rekod_sentiasa_bersama.jpg",
]

TITLES = [
    ("Tanaman lebih", "tersusun"),
    ("Semua kerja,", "satu pandangan"),
    ("Projek & plot", "lebih teratur"),
    ("Tambah tugasan", "dengan pantas"),
    ("Jadual kerja", "tanpa terlepas"),
    ("Setiap tanaman,", "mudah dipantau"),
    ("Laporan jelas,", "keputusan pantas"),
    ("Rekod kekal", "bersama anda"),
]

TAGS = [
    "PETANI APP",
    "PAPARAN UTAMA",
    "PENGURUSAN",
    "TINDAKAN PANTAS",
    "PERINGATAN",
    "REKOD PLOT",
    "LAPORAN",
    "100% OFFLINE",
]

CAPTIONS = [
    "Rekod tanaman, plot dan tugasan dalam satu aplikasi yang mudah difahami.",
    "Tugasan akan datang dan plot aktif, terus di halaman utama.",
    "Asingkan ladang mengikut lokasi, tanaman, varieti dan plot.",
    "Pilih jenis kerja dan tetapkan batas hanya dalam beberapa ketikan.",
    "Kalendar dan garis masa membantu anda bersedia lebih awal.",
    "Simpan jumlah pokok, varieti dan sejarah tugasan untuk setiap tanaman.",
    "Fahami kemajuan ladang melalui ringkasan yang kemas.",
    "Catat tanpa internet. Segerakkan apabila anda bersedia.",
]

SCREEN_INDEX = {
    "crop": 5,
    "auth": 6,
    "home": 7,
    "calendar": 8,
    "timeline": 9,
    "add_task": 10,
    "projects": 11,
    "project_detail": 12,
    "beds": 13,
    "report": 14,
    "profile": 15,
    "icons": 16,
    "task_list": 17,
    "task_detail": 18,
}

COLORS = {
    "green": "#17764E",
    "green_dark": "#0B3D2B",
    "green_deep": "#092F22",
    "mint": "#DFF3E6",
    "yellow": "#FFC94D",
    "yellow_pale": "#FFF2C8",
    "brown": "#8A7954",
    "soft_brown": "#EEE8DB",
    "cream": "#F7F4EA",
    "warm_white": "#FFFDF8",
    "ink": "#10231A",
    "muted": "#617269",
    "white": "#FFFFFF",
}


def rgba(value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def blend(a: str, b: str, amount: float) -> tuple[int, int, int, int]:
    ca, cb = rgba(a), rgba(b)
    return tuple(round(ca[i] + ((cb[i] - ca[i]) * amount)) for i in range(4))


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(ROOT / "assets" / "fonts" / name), size=size)


def paste_rgba(base: Image.Image, image: Image.Image, xy: tuple[int, int]) -> None:
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    base.alpha_composite(image, xy)


def contain(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    result = image.copy()
    result.thumbnail(size, Image.Resampling.LANCZOS)
    return result


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return ImageOps.fit(image, size, method=Image.Resampling.LANCZOS)


def soft_shadow(
    base: Image.Image,
    box: tuple[int, int, int, int],
    radius: int,
    blur: int,
    alpha: int = 42,
    offset_y: int = 12,
) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    x0, y0, x1, y1 = box
    d.rounded_rectangle(
        (x0, y0 + offset_y, x1, y1 + offset_y),
        radius=radius,
        fill=rgba(COLORS["green_deep"], alpha),
    )
    base.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))


def glass_card(
    base: Image.Image,
    box: tuple[int, int, int, int],
    radius: int,
    fill_alpha: int = 190,
    border_alpha: int = 190,
    shadow: bool = True,
) -> None:
    if shadow:
        soft_shadow(base, box, radius, max(12, radius // 2))
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.rounded_rectangle(
        box,
        radius=radius,
        fill=rgba(COLORS["white"], fill_alpha),
        outline=rgba(COLORS["white"], border_alpha),
        width=max(2, radius // 14),
    )
    x0, y0, x1, _ = box
    d.line(
        (x0 + radius, y0 + 2, x1 - radius, y0 + 2),
        fill=rgba(COLORS["white"], 215),
        width=max(2, radius // 16),
    )
    base.alpha_composite(layer)


def text_size(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont) -> tuple[int, int]:
    box = draw.textbbox((0, 0), text, font=fnt)
    return box[2] - box[0], box[3] - box[1]


def wrap_text(draw: ImageDraw.ImageDraw, text: str, fnt: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if text_size(draw, candidate, fnt)[0] <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_centered_lines(
    draw: ImageDraw.ImageDraw,
    lines: list[str],
    y: int,
    fnt: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int, int],
    width: int,
    line_gap: int,
) -> int:
    for line in lines:
        tw, th = text_size(draw, line, fnt)
        draw.text(((width - tw) // 2, y), line, font=fnt, fill=fill)
        y += th + line_gap
    return y


def draw_header(base: Image.Image, panel: int, w: int, h: int) -> None:
    d = ImageDraw.Draw(base)
    title_font = font("ProductSans-Black.ttf", max(62, round(w * 0.083)))
    line_one, line_two = TITLES[panel]
    title_y = round(h * 0.075)
    for index, line in enumerate((line_one, line_two)):
        tw, th = text_size(d, line, title_font)
        tx = (w - tw) // 2
        ty = title_y + index * round(title_font.size * 0.96)
        if index == 1:
            highlight_y = ty + round(th * 0.64)
            d.rounded_rectangle(
                (
                    tx - round(w * 0.012),
                    highlight_y,
                    tx + tw + round(w * 0.012),
                    highlight_y + round(th * 0.31),
                ),
                radius=max(5, round(w * 0.006)),
                fill=rgba(COLORS["yellow"], 235),
            )
        d.text((tx, ty), line, font=title_font, fill=rgba(COLORS["ink"]))


def draw_caption(base: Image.Image, panel: int, w: int, h: int) -> None:
    d = ImageDraw.Draw(base)
    caption_font = font("ProductSans-Regular.ttf", max(28, round(w * 0.029)))
    lines = wrap_text(d, CAPTIONS[panel], caption_font, round(w * 0.78))
    total = sum(text_size(d, line, caption_font)[1] for line in lines)
    total += max(0, len(lines) - 1) * round(caption_font.size * 0.28)
    y = round(h * 0.93) - total // 2
    draw_centered_lines(
        d,
        lines,
        y,
        caption_font,
        rgba(COLORS["muted"]),
        w,
        round(caption_font.size * 0.28),
    )


def panoramic_background(panel: int, w: int, h: int) -> Image.Image:
    t = (panel + 0.5) / 8
    stops = [
        COLORS["cream"],
        "#EEF6EE",
        COLORS["yellow_pale"],
        COLORS["soft_brown"],
        COLORS["warm_white"],
    ]
    p = t * (len(stops) - 1)
    idx = min(len(stops) - 2, int(p))
    local = p - idx
    top = blend(stops[idx], stops[idx + 1], local)
    bottom = blend(COLORS["warm_white"], stops[idx + 1], min(0.72, local + 0.18))
    vertical = Image.linear_gradient("L").resize((w, h))
    base = Image.composite(
        Image.new("RGBA", (w, h), bottom),
        Image.new("RGBA", (w, h), top),
        vertical,
    )

    d = ImageDraw.Draw(base, "RGBA")
    global_x = panel * w
    total_w = w * 8

    shapes = [
        (w * 0.92, h * 0.54, w * 0.58, rgba(COLORS["yellow"], 48)),
        (w * 2.55, h * 0.72, w * 0.73, rgba(COLORS["green"], 28)),
        (w * 4.38, h * 0.45, w * 0.55, rgba(COLORS["yellow"], 40)),
        (w * 6.2, h * 0.68, w * 0.8, rgba(COLORS["green"], 24)),
        (w * 7.65, h * 0.33, w * 0.62, rgba(COLORS["brown"], 25)),
    ]
    for cx, cy, radius, color in shapes:
        x = cx - global_x
        d.ellipse((x - radius, cy - radius, x + radius, cy + radius), fill=color)

    points: list[tuple[float, float]] = []
    for i in range(181):
        gx = total_w * i / 180
        gy = h * (0.78 + 0.035 * math.sin((gx / total_w) * math.pi * 5))
        points.append((gx - global_x, gy))
    d.line(points, fill=rgba(COLORS["green"], 36), width=max(2, round(w * 0.003)))

    for boundary in range(1, 8):
        x = (boundary * w) - global_x
        y = h * (0.78 + 0.035 * math.sin((boundary / 8) * math.pi * 5))
        r = round(w * 0.012)
        d.ellipse((x - r, y - r, x + r, y + r), fill=rgba(COLORS["yellow"], 165))

    margin = round(w * 0.028)
    card_box = (margin, round(h * 0.018), w - margin, round(h * 0.982))
    glass_card(
        base,
        card_box,
        radius=round(w * 0.045),
        fill_alpha=105,
        border_alpha=170,
        shadow=False,
    )
    return base


def open_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def rotate(image: Image.Image, degrees: float) -> Image.Image:
    return image.rotate(degrees, resample=Image.Resampling.BICUBIC, expand=True)


def device_mockup(
    screen: Image.Image,
    target_width: int,
    max_height: int,
    tablet: bool = False,
) -> Image.Image:
    ratio = screen.height / screen.width
    outer_w = target_width
    outer_h = round(outer_w * ratio)
    if outer_h > max_height:
        outer_h = max_height
        outer_w = round(outer_h / ratio)
    bezel = max(10, round(outer_w * (0.026 if tablet else 0.04)))
    radius = max(24, round(outer_w * (0.055 if tablet else 0.11)))
    canvas_pad = max(24, round(outer_w * 0.08))
    device = Image.new(
        "RGBA",
        (outer_w + canvas_pad * 2, outer_h + canvas_pad * 2),
        (0, 0, 0, 0),
    )
    shadow = Image.new("RGBA", device.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        (
            canvas_pad,
            canvas_pad + round(canvas_pad * 0.25),
            canvas_pad + outer_w,
            canvas_pad + outer_h + round(canvas_pad * 0.25),
        ),
        radius=radius,
        fill=rgba(COLORS["green_deep"], 90),
    )
    device.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(canvas_pad // 2)))
    dd = ImageDraw.Draw(device)
    dd.rounded_rectangle(
        (canvas_pad, canvas_pad, canvas_pad + outer_w, canvas_pad + outer_h),
        radius=radius,
        fill=rgba("#101715"),
        outline=rgba("#F6F5EF"),
        width=max(3, bezel // 4),
    )
    inner_size = (outer_w - bezel * 2, outer_h - bezel * 2)
    screen_img = cover(screen, inner_size)
    mask = Image.new("L", inner_size, 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle(
        (0, 0, inner_size[0], inner_size[1]),
        radius=max(18, radius - bezel),
        fill=255,
    )
    device.paste(screen_img, (canvas_pad + bezel, canvas_pad + bezel), mask)
    return device


def place_center(base: Image.Image, image: Image.Image, cx: int, cy: int) -> None:
    paste_rgba(base, image, (round(cx - image.width / 2), round(cy - image.height / 2)))


def icon_badge(
    base: Image.Image,
    xy: tuple[int, int],
    title: str,
    subtitle: str,
    w: int,
    accent: str = "green",
    icon: Image.Image | None = None,
) -> None:
    x, y = xy
    h = round(w * 0.31)
    radius = round(w * 0.08)
    box = (x, y, x + w, y + h)
    glass_card(base, box, radius=radius, fill_alpha=214)
    d = ImageDraw.Draw(base)
    circle = round(h * 0.56)
    cx = x + round(h * 0.53)
    cy = y + h // 2
    d.ellipse(
        (cx - circle // 2, cy - circle // 2, cx + circle // 2, cy + circle // 2),
        fill=rgba(COLORS[accent], 240),
    )
    if icon is not None:
        fitted = contain(icon, (round(circle * 0.78), round(circle * 0.78)))
        place_center(base, fitted, cx, cy)
    else:
        line_width = max(3, round(circle * 0.1))
        d.line(
            (
                cx - round(circle * 0.22),
                cy,
                cx - round(circle * 0.05),
                cy + round(circle * 0.17),
                cx + round(circle * 0.25),
                cy - round(circle * 0.2),
            ),
            fill=rgba(COLORS["white"]),
            width=line_width,
            joint="curve",
        )
    title_font = font("ProductSans-Bold.ttf", max(20, round(w * 0.075)))
    sub_font = font("ProductSans-Regular.ttf", max(16, round(w * 0.055)))
    tx = x + round(h * 0.98)
    d.text((tx, y + round(h * 0.23)), title, font=title_font, fill=rgba(COLORS["ink"]))
    d.text((tx, y + round(h * 0.56)), subtitle, font=sub_font, fill=rgba(COLORS["muted"]))


def solve_linear_system(matrix: list[list[float]], vector: list[float]) -> list[float]:
    size = len(vector)
    augmented = [row[:] + [value] for row, value in zip(matrix, vector)]
    for column in range(size):
        pivot = max(range(column, size), key=lambda row: abs(augmented[row][column]))
        augmented[column], augmented[pivot] = augmented[pivot], augmented[column]
        divisor = augmented[column][column]
        if abs(divisor) < 1e-10:
            raise ValueError("Unable to solve perspective transform")
        augmented[column] = [value / divisor for value in augmented[column]]
        for row in range(size):
            if row == column:
                continue
            factor = augmented[row][column]
            augmented[row] = [
                value - factor * pivot_value
                for value, pivot_value in zip(augmented[row], augmented[column])
            ]
    return [augmented[row][-1] for row in range(size)]


def perspective_coefficients(
    destination: list[tuple[float, float]],
    source: list[tuple[float, float]],
) -> list[float]:
    matrix: list[list[float]] = []
    vector: list[float] = []
    for (x, y), (u, v) in zip(destination, source):
        matrix.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        vector.append(u)
        matrix.append([0, 0, 0, x, y, 1, -v * x, -v * y])
        vector.append(v)
    return solve_linear_system(matrix, vector)


def chroma_mask(raw: Image.Image) -> Image.Image:
    rgb = raw.convert("RGB")
    alpha = raw.getchannel("A")
    source = rgb.load()
    alpha_pixels = alpha.load()
    result = Image.new("L", raw.size, 0)
    target = result.load()
    for y in range(raw.height):
        for x in range(raw.width):
            red, green, blue = source[x, y]
            if (
                alpha_pixels[x, y] > 8
                and green > 62
                and green > red * 1.34
                and green > blue * 1.24
            ):
                target[x, y] = 255
    return result


def linear_fit(points: list[tuple[float, float]]) -> tuple[float, float]:
    count = len(points)
    mean_y = sum(point[0] for point in points) / count
    mean_x = sum(point[1] for point in points) / count
    denominator = sum((point[0] - mean_y) ** 2 for point in points)
    slope = sum((y - mean_y) * (x - mean_x) for y, x in points) / denominator
    return slope, mean_x - slope * mean_y


def screen_quad(mask: Image.Image) -> list[tuple[float, float]]:
    bbox = mask.getbbox()
    if bbox is None:
        raise ValueError("No chroma screen found in hand-held device asset")
    x0, y0, x1, y1 = bbox
    span = y1 - y0
    fit_top = y0 + round(span * 0.12)
    fit_bottom = y1 - round(span * 0.12)
    left: list[tuple[float, float]] = []
    right: list[tuple[float, float]] = []
    for y in range(fit_top, fit_bottom, max(1, span // 240)):
        row_bbox = mask.crop((x0, y, x1, y + 1)).getbbox()
        if row_bbox is None:
            continue
        left.append((y, x0 + row_bbox[0]))
        right.append((y, x0 + row_bbox[2] - 1))
    left_slope, left_intercept = linear_fit(left)
    right_slope, right_intercept = linear_fit(right)
    top_y = y0 + max(2, round(span * 0.008))
    bottom_y = y1 - max(3, round(span * 0.008))
    return [
        (left_slope * top_y + left_intercept, top_y),
        (right_slope * top_y + right_intercept, top_y),
        (right_slope * bottom_y + right_intercept, bottom_y),
        (left_slope * bottom_y + left_intercept, bottom_y),
    ]


def hand_device_with_screen(hand_path: Path, screen: Image.Image) -> Image.Image:
    raw = open_rgba(hand_path)
    mask = chroma_mask(raw)
    quad = screen_quad(mask)
    source = [
        (0, 0),
        (screen.width - 1, 0),
        (screen.width - 1, screen.height - 1),
        (0, screen.height - 1),
    ]
    coefficients = perspective_coefficients(quad, source)
    warped = screen.convert("RGBA").transform(
        raw.size,
        Image.Transform.PERSPECTIVE,
        coefficients,
        resample=Image.Resampling.BICUBIC,
    )
    soft_mask = mask.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(0.65))
    warped.putalpha(soft_mask)

    cleaned = raw.copy()
    cleaned.putalpha(ImageChops.subtract(raw.getchannel("A"), soft_mask))
    result = Image.new("RGBA", raw.size, (0, 0, 0, 0))
    result.alpha_composite(warped)
    result.alpha_composite(cleaned)
    return result


def render_panel_one(base: Image.Image, w: int, h: int, source_name: str) -> None:
    hero = open_rgba(ASSETS / "walkthrough" / "plots_and_rows.png")
    hero_scale = 1.12 if source_name == "Android" else 1.0
    hero = contain(hero, (round(w * 0.9 * hero_scale), round(h * 0.49 * hero_scale)))
    place_center(base, hero, w // 2, round(h * 0.565))
    crop_assets = [
        ASSETS / "seeds" / "pineapple_fruit.png",
        ASSETS / "seeds" / "coconut_fruit.png",
        ASSETS / "seeds" / "rice_stalks.png",
    ]
    positions = [(0.12, 0.48, -10), (0.84, 0.52, 9), (0.83, 0.72, -7)]
    for path, (px, py, angle) in zip(crop_assets, positions):
        img = contain(open_rgba(path), (round(w * 0.17), round(w * 0.17)))
        img = rotate(img, angle)
        place_center(base, img, round(w * px), round(h * py))
    badge_w = round(w * 0.68)
    icon_badge(
        base,
        ((w - badge_w) // 2, round(h * 0.76)),
        "Semua rekod",
        "Satu aplikasi",
        badge_w,
        accent="green",
    )


def render_panel_two(
    base: Image.Image,
    w: int,
    h: int,
    home_screen: Image.Image,
    source_name: str,
) -> None:
    if source_name == "Iphone":
        hand_path = HAND_PHONE
    elif source_name == "Android":
        hand_path = HAND_ANDROID_PHONE
    else:
        hand_path = HAND_IPAD
    hand = hand_device_with_screen(hand_path, home_screen)
    if source_name in {"Ipad", "Tablet"}:
        hand = contain(hand, (round(w * 1.13), round(h * 0.65)))
        hand_x = -round(w * 0.035)
    else:
        hand = contain(hand, (round(w * 1.2), round(h * 0.69)))
        hand_x = -round(w * 0.065)
    hand_y = round(h * 0.875) - hand.height
    paste_rgba(base, hand, (hand_x, hand_y))
    badge_w = round(w * 0.41)
    icon_badge(
        base,
        (round(w * 0.555), round(h * 0.34)),
        "8 tugasan",
        "Minggu ini",
        badge_w,
        accent="green",
    )
    icon_badge(
        base,
        (round(w * 0.545), round(h * 0.75)),
        "3 projek",
        "Aktif sekarang",
        badge_w,
        accent="yellow",
    )


def render_panel_three(base: Image.Image, w: int, h: int, screen: Image.Image, tablet: bool) -> None:
    max_height = round(h * 0.58)
    device = device_mockup(screen, round(w * (0.88 if tablet else 0.69)), max_height, tablet=tablet)
    device = rotate(device, -3.2)
    place_center(base, device, round(w * 0.49), round(h * 0.59))
    fruit_one = open_rgba(ASSETS / "seeds" / "coconut_fruit.png")
    fruit_two = open_rgba(ASSETS / "seeds" / "pineapple_fruit.png")
    badge_w = round(w * 0.43)
    icon_badge(
        base,
        (round(w * 0.04), round(h * 0.72)),
        "Plot MATAG",
        "Kelapa",
        badge_w,
        icon=fruit_one,
    )
    icon_badge(
        base,
        (round(w * 0.53), round(h * 0.35)),
        "Plot Cobek",
        "Nanas",
        badge_w,
        icon=fruit_two,
    )


def render_panel_four(base: Image.Image, w: int, h: int, screen: Image.Image, tablet: bool) -> None:
    device = device_mockup(
        screen,
        round(w * (0.73 if not tablet else 0.9)),
        round(h * 0.59),
        tablet=tablet,
    )
    device = rotate(device, -4)
    place_center(base, device, round(w * 0.42), round(h * 0.58))

    tasks = [
        ("insect_control.png", 0.77, 0.38, -7),
        ("fertilizing.png", 0.83, 0.52, 6),
        ("fruit_harvest.png", 0.78, 0.67, -5),
        ("weed_control.png", 0.68, 0.79, 7),
        ("replanting.png", 0.84, 0.79, -4),
    ]
    for filename, px, py, angle in tasks:
        image = contain(
            open_rgba(ASSETS / "tasks" / filename),
            (round(w * (0.23 if not tablet else 0.22)), round(h * 0.145)),
        )
        image = rotate(image, angle)
        shadow = Image.new("RGBA", image.size, rgba(COLORS["green_deep"], 0))
        shadow.putalpha(
            image.getchannel("A")
            .filter(ImageFilter.GaussianBlur(max(5, round(w * 0.008))))
            .point(lambda value: round(value * 0.18))
        )
        place_center(base, shadow, round(w * px), round(h * py + w * 0.01))
        place_center(base, image, round(w * px), round(h * py))


def render_panel_five(
    base: Image.Image,
    w: int,
    h: int,
    calendar: Image.Image,
    timeline: Image.Image,
    tablet: bool,
) -> None:
    target_width = round(w * (0.95 if tablet else 0.72))
    target_height = round(h * (0.54 if tablet else 0.64))
    back = rotate(device_mockup(calendar, target_width, target_height, tablet=tablet), -4)
    front = rotate(device_mockup(timeline, target_width, target_height, tablet=tablet), 4)
    place_center(base, back, round(w * 0.37), round(h * 0.57))
    place_center(base, front, round(w * 0.63), round(h * 0.60))
    badge_w = round(w * 0.52)
    icon_badge(
        base,
        (round(w * 0.08), round(h * 0.76)),
        "12 jam awal",
        "Peringatan lalai",
        badge_w,
        accent="yellow",
    )


def render_panel_six(
    base: Image.Image,
    w: int,
    h: int,
    beds: Image.Image,
    task: Image.Image,
    tablet: bool,
) -> None:
    target_width = round(w * (0.95 if tablet else 0.72))
    target_height = round(h * (0.54 if tablet else 0.64))
    main = rotate(device_mockup(beds, target_width, target_height, tablet=tablet), -4)
    detail = rotate(device_mockup(task, target_width, target_height, tablet=tablet), 4)
    place_center(base, main, round(w * 0.37), round(h * 0.57))
    place_center(base, detail, round(w * 0.63), round(h * 0.60))
    d = ImageDraw.Draw(base)
    chip_font = font("ProductSans-Bold.ttf", max(19, round(w * 0.025)))
    labels = ["14 batas", "1,680 pokok", "Varieti tersimpan"]
    chip_y = round(h * 0.78)
    widths = [text_size(d, label, chip_font)[0] + round(w * 0.045) for label in labels]
    total = sum(widths) + round(w * 0.018) * (len(labels) - 1)
    x = (w - total) // 2
    for label, chip_w in zip(labels, widths):
        d.rounded_rectangle(
            (x, chip_y, x + chip_w, chip_y + round(w * 0.07)),
            radius=round(w * 0.035),
            fill=rgba(COLORS["white"], 220),
            outline=rgba(COLORS["green"], 90),
            width=max(2, round(w * 0.002)),
        )
        tw, th = text_size(d, label, chip_font)
        d.text((x + (chip_w - tw) // 2, chip_y + round(w * 0.035) - th // 2), label, font=chip_font, fill=rgba(COLORS["green_dark"]))
        x += chip_w + round(w * 0.018)


def render_panel_seven(base: Image.Image, w: int, h: int, report: Image.Image, tablet: bool) -> None:
    device = device_mockup(
        report,
        round(w * (0.86 if tablet else 0.68)),
        round(h * 0.59),
        tablet=tablet,
    )
    place_center(base, device, round(w * 0.5), round(h * 0.58))
    stats = [
        ("8,055", "Pokok direkod"),
        ("8", "Plot aktif"),
        ("2", "Tugasan selesai"),
    ]
    card_w = round(w * 0.34)
    ys = [0.36, 0.55, 0.74]
    xs = [0.04, 0.62, 0.05]
    d = ImageDraw.Draw(base)
    value_font = font("ProductSans-Black.ttf", max(32, round(w * 0.055)))
    label_font = font("ProductSans-Regular.ttf", max(18, round(w * 0.026)))
    for (value, label), px, py in zip(stats, xs, ys):
        x, y = round(w * px), round(h * py)
        box = (x, y, x + card_w, y + round(card_w * 0.54))
        glass_card(base, box, radius=round(w * 0.035), fill_alpha=220)
        d.text((x + round(card_w * 0.1), y + round(card_w * 0.09)), value, font=value_font, fill=rgba(COLORS["green"]))
        d.text((x + round(card_w * 0.1), y + round(card_w * 0.32)), label, font=label_font, fill=rgba(COLORS["muted"]))


def render_panel_eight(
    base: Image.Image,
    w: int,
    h: int,
    profile: Image.Image,
    records: Image.Image,
    tablet: bool,
) -> None:
    target_width = round(w * (0.95 if tablet else 0.72))
    target_height = round(h * (0.54 if tablet else 0.64))
    back = rotate(device_mockup(profile, target_width, target_height, tablet=tablet), -4)
    front = rotate(device_mockup(records, target_width, target_height, tablet=tablet), 4)
    place_center(base, back, round(w * 0.37), round(h * 0.57))
    place_center(base, front, round(w * 0.63), round(h * 0.60))
    farmer = contain(open_rgba(ASSETS / "farmer_phone.png"), (round(w * 0.3), round(h * 0.22)))
    place_center(base, farmer, round(w * 0.16), round(h * 0.77))
    badge_w = round(w * 0.5)
    icon_badge(
        base,
        (round(w * 0.46), round(h * 0.76)),
        "100% offline",
        "Rekod dahulu",
        badge_w,
        accent="green",
    )


def render_set(name: str, width: int, height: int, source_name: str) -> None:
    source_files = sorted(
        path
        for path in (SOURCE_ROOT / source_name).glob("*.png")
        if path.name != ".DS_Store"
    )
    if len(source_files) < 19:
        raise RuntimeError(f"Expected 19 screenshots in {source_name}, found {len(source_files)}")
    screens = {key: open_rgba(source_files[index]) for key, index in SCREEN_INDEX.items()}
    output_dir = OUTPUT_ROOT / name
    output_dir.mkdir(parents=True, exist_ok=True)
    tablet = source_name in {"Ipad", "Tablet"}

    for panel in range(8):
        base = panoramic_background(panel, width, height)
        draw_header(base, panel, width, height)
        if panel == 0:
            render_panel_one(base, width, height, source_name)
        elif panel == 1:
            render_panel_two(base, width, height, screens["home"], source_name)
        elif panel == 2:
            render_panel_three(base, width, height, screens["projects"], tablet)
        elif panel == 3:
            render_panel_four(base, width, height, screens["add_task"], tablet)
        elif panel == 4:
            render_panel_five(base, width, height, screens["calendar"], screens["timeline"], tablet)
        elif panel == 5:
            render_panel_six(base, width, height, screens["beds"], screens["task_detail"], tablet)
        elif panel == 6:
            render_panel_seven(base, width, height, screens["report"], tablet)
        else:
            render_panel_eight(base, width, height, screens["profile"], screens["task_list"], tablet)
        draw_caption(base, panel, width, height)
        destination = output_dir / FILES[panel]
        base.convert("RGB").save(destination, format="JPEG", quality=95, subsampling=0, optimize=True)
        print(f"{destination.relative_to(ROOT)} {width}x{height}")
        del base
        gc.collect()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--set", choices=["all", *SPECS.keys()], default="all")
    args = parser.parse_args()
    selected = SPECS.items() if args.set == "all" else [(args.set, SPECS[args.set])]
    for name, (width, height, source_name) in selected:
        render_set(name, width, height, source_name)


if __name__ == "__main__":
    main()
