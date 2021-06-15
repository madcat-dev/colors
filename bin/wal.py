#!/usr/bin/env python

import os
import sys
import re
import colorsys
import subprocess
import shutil

"""
This code based on pywal project
https://github.com/dylanaraps/pywal
"""

TERMINAL_COLORS = [
    '# black',
    '# red',
    '# green',
    '# yellow',
    '# blue',
    '# magenta',
    '# cyan',
    '# white',
]

THEME_PATTERN = """#!/usr/bin/env bash

declare -A COLOR

# -----------------------------------------------------------------------------
# ... color cheme
# -----------------------------------------------------------------------------

export COLOR=(
    [name]=""
    [description]=""
    [image]="{image}"

    ## terminal colors+
    {terminal}
)
"""


def imagemagick(color_count, img, magick_command):
    """Call Imagemagick to generate a scheme."""
    flags = ["-resize", "25%", "-colors", str(color_count),
             "-unique-colors", "txt:-"]
    img += "[0]"

    return subprocess.check_output([*magick_command, img, *flags]).splitlines()


def has_im():
    """Check to see if the user has im installed."""
    if shutil.which("magick"):
        return ["magick", "convert"]

    if shutil.which("convert"):
        return ["convert"]

    print("\033[31mImagemagick wasn't found on your system.\033[0m")
    print("\033[31mTry another backend. (wal --backend)\033[0m")
    sys.exit(1)


def gen_colors(img):
    """Format the output from imagemagick into a list
       of hex colors."""
    magick_command = has_im()

    for i in range(0, 20, 1):
        raw_colors = imagemagick(16 + i, img, magick_command)

        if len(raw_colors) > 16:
            break

        if i == 19:
            print("\033[31mImagemagick couldn't generate a suitable palette.\033[0m")
            sys.exit(1)

        else:
            print("\033[33mImagemagick couldn't generate a palette.\033[0m")
            print("\033[33mTrying a larger palette size %s\033[0m", 16 + i)

    return [re.search("#.{6}", str(col)).group(0) for col in raw_colors[1:]]


def darken_color(color, amount):
    """Darken a hex color."""
    color = [int(col * (1 - amount)) for col in hex_to_rgb(color)]
    return rgb_to_hex(color)


def lighten_color(color, amount):
    """Lighten a hex color."""
    color = [int(col + (255 - col) * amount) for col in hex_to_rgb(color)]
    return rgb_to_hex(color)


def blend_color(color, color2):
    """Blend two colors together."""
    r1, g1, b1 = hex_to_rgb(color)
    r2, g2, b2 = hex_to_rgb(color2)

    r3 = int(0.5 * r1 + 0.5 * r2)
    g3 = int(0.5 * g1 + 0.5 * g2)
    b3 = int(0.5 * b1 + 0.5 * b2)

    return rgb_to_hex((r3, g3, b3))


def adjust(colors, light):
    """Adjust the generated colors and store them in a dict that
       we will later save in json format."""
    raw_colors = colors[:1] + colors[8:16] + colors[8:-1]

    # Manually adjust colors.
    if light:
        for color in raw_colors:
            color = saturate_color(color, 0.5)

        raw_colors[0] = lighten_color(colors[-1], 0.85)
        raw_colors[7] = colors[0]
        raw_colors[8] = darken_color(colors[-1], 0.4)
        raw_colors[15] = colors[0]

    else:
        # Darken the background color slightly.
        if raw_colors[0][1] != "0":
            raw_colors[0] = darken_color(raw_colors[0], 0.40)

        raw_colors[7] = blend_color(raw_colors[7], "#EEEEEE")
        raw_colors[8] = darken_color(raw_colors[7], 0.30)
        raw_colors[15] = blend_color(raw_colors[15], "#EEEEEE")

    return raw_colors


def get(img, light=False):
    """Get colorscheme."""
    colors = gen_colors(img)
    return adjust(colors, light)


def hex_to_rgb(color):
    """Convert a hex color to rgb."""
    return tuple(bytes.fromhex(color.strip("#")))


def rgb_to_hex(color):
    """Convert an rgb color to hex."""
    return "#%02X%02X%02X" % (*color,)


def saturate_color(color, amount):
    """Saturate a hex color."""
    r, g, b = hex_to_rgb(color)
    r, g, b = [x / 255.0 for x in (r, g, b)]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    s = amount
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    r, g, b = [x * 255.0 for x in (r, g, b)]

    return rgb_to_hex((int(r), int(g), int(b)))


def main():
    """Main script function."""
    if len(sys.argv) < 2:
        print('Usage:')
        return

    amount = ""
    light = False

    img = os.path.realpath(sys.argv[1])

    try:
        light = (sys.argv[2] == 'true')
    except IndexError:
        pass

    out = sys.stdout
    try:
        out = open(sys.argv[3], 'w')
    except IndexError:
        pass

    colors = get(img, light)

    """Saturate all colors."""
    if amount and float(amount) <= 1.0:
        for i, _ in enumerate(colors):
            if i not in [0, 7, 8, 15]:
                colors[i] = saturate_color(colors[i], float(amount))

    terminal = []

    for i, _ in enumerate(TERMINAL_COLORS):
        terminal.append(TERMINAL_COLORS[i])

        terminal.append('[{}]={}'.format(
            i, colors[i]
        ))

        terminal.append('[{}]={}'.format(
            i + 8, colors[i + 8]
        ))

        terminal.append("")

    print(THEME_PATTERN.format(
        image=os.path.basename(img),
        terminal='\n    '.join(terminal)
    ), file=out)


if __name__ == "__main__":
    main()
