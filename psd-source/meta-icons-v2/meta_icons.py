"""MetaMesh icon family v2 — one procedural mesh sphere + a badge per app.

  python3 meta_icons.py <out_dir> [APP ...]      # render icons (default: all)

Neutral icon = the sphere alone (MetaCore). Every other app = sphere + a dark
badge bottom-right: coloured ring (family colour), a white glyph, a label that
shrinks to fit. Spirit of v1, regenerated from code so nothing is ever lost again.
"""
import subprocess, sys, os
from gen_mesh import mesh_svg

MESH = dict(n=46, seed=8, ax=-0.35, ay=0.35)
FONT_IM = "DejaVu-Sans-Bold"                       # ImageMagick name, for measuring
FONT_SVG = "DejaVu Sans, Helvetica, Arial, sans-serif"
DARK = "#2c3038"
ORANGE, TEAL, GOLD, GREEN, PURPLE = "#e8821e", "#00b4b4", "#dca000", "#3ca050", "#8c50c8"
W = "#ffffff"

# Glyphs live in a 160x128 box, drawn white on the dark badge.
G = {
 "nodes":   f'<g stroke="{W}" stroke-width="11" stroke-linecap="round"><line x1="34" y1="64" x2="126" y2="22"/><line x1="34" y1="64" x2="126" y2="106"/></g>'
            f'<g fill="{W}"><circle cx="34" cy="64" r="20"/><circle cx="126" cy="22" r="17"/><circle cx="126" cy="106" r="17"/></g>',
 "arrow":   f'<g fill="none" stroke="{W}" stroke-width="22" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="64" x2="134" y2="64"/><polyline points="94,26 136,64 94,102"/></g>',
 "layers":  f'<g fill="{W}" stroke="{DARK}" stroke-width="7"><polygon points="80,78 152,100 80,122 8,100"/><polygon points="80,42 152,64 80,86 8,64"/><polygon points="80,6 152,28 80,50 8,28"/></g>',
 "folder":  f'<path fill="{W}" d="M14 16 h46 l14 16 h72 a10 10 0 0 1 10 10 v66 a10 10 0 0 1 -10 10 H14 a10 10 0 0 1 -10 -10 V26 a10 10 0 0 1 10 -10z"/>',
 "play":    f'<polygon fill="{W}" points="46,6 46,122 140,64"/>',
 "cards":   f'<rect x="14" y="8" width="84" height="110" rx="12" fill="none" stroke="{W}" stroke-width="11"/>'
            f'<rect x="56" y="16" width="92" height="110" rx="12" fill="{DARK}" stroke="{W}" stroke-width="11"/>'
            f'<circle cx="84" cy="48" r="10" fill="{W}"/><polygon fill="{W}" points="70,110 98,74 116,94 126,84 136,110"/>',
 "search":  f'<circle cx="64" cy="54" r="40" fill="none" stroke="{W}" stroke-width="17"/><line x1="94" y1="84" x2="140" y2="124" stroke="{W}" stroke-width="22" stroke-linecap="round"/>',
 "caption": f'<rect x="10" y="10" width="140" height="104" rx="20" fill="none" stroke="{W}" stroke-width="14"/>'
            f'<g stroke="{W}" stroke-width="14" stroke-linecap="round"><line x1="42" y1="56" x2="118" y2="56"/><line x1="58" y1="82" x2="102" y2="82"/></g>',
 "book":    f'<path fill="{W}" d="M80 30 C60 14 32 12 6 16 V112 C32 108 60 110 80 124 C100 110 128 108 154 112 V16 C128 12 100 14 80 30Z"/>'
            f'<line x1="80" y1="32" x2="80" y2="122" stroke="{DARK}" stroke-width="7"/>',
 "photo":   f'<rect x="8" y="12" width="144" height="104" rx="14" fill="none" stroke="{W}" stroke-width="12"/>'
            f'<circle cx="52" cy="46" r="13" fill="{W}"/><polygon fill="{W}" points="22,104 66,60 94,86 112,68 140,104"/>',
 "gif":     f'<rect x="6" y="18" width="148" height="92" rx="16" fill="{W}"/>'
            f'<text x="80" y="84" text-anchor="middle" font-family="{FONT_SVG}" font-weight="bold" font-size="56" fill="{DARK}">GIF</text>',
 "paper":   f'<path d="M36 6 h66 l32 32 v80 a8 8 0 0 1 -8 8 H36 a8 8 0 0 1 -8 -8 V14 a8 8 0 0 1 8 -8z" fill="none" stroke="{W}" stroke-width="11" stroke-linejoin="round"/>'
            f'<g stroke="{W}" stroke-width="10" stroke-linecap="round"><line x1="52" y1="56" x2="110" y2="56"/><line x1="52" y1="78" x2="110" y2="78"/><line x1="52" y1="100" x2="90" y2="100"/></g>',
 "medical": f'<path d="M36 6 h88 a8 8 0 0 1 8 8 v104 a8 8 0 0 1 -8 8 H36 a8 8 0 0 1 -8 -8 V14 a8 8 0 0 1 8 -8z" fill="none" stroke="{W}" stroke-width="11"/>'
            f'<g stroke="{W}" stroke-width="18" stroke-linecap="round"><line x1="80" y1="36" x2="80" y2="96"/><line x1="50" y1="66" x2="110" y2="66"/></g>',
 "flask":   f'<path d="M60 8 h40 M68 8 v36 L22 110 a9 9 0 0 0 8 14 h100 a9 9 0 0 0 8 -14 L92 44 V8" fill="none" stroke="{W}" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<polygon fill="{W}" points="44,82 116,82 136,116 24,116"/>',
 "idcard":  f'<rect x="6" y="14" width="148" height="100" rx="16" fill="none" stroke="{W}" stroke-width="12"/>'
            f'<circle cx="50" cy="54" r="16" fill="{W}"/><path fill="{W}" d="M24 100 a26 24 0 0 1 52 0z"/>'
            f'<g stroke="{W}" stroke-width="11" stroke-linecap="round"><line x1="96" y1="46" x2="136" y2="46"/><line x1="96" y1="70" x2="136" y2="70"/><line x1="96" y1="94" x2="122" y2="94"/></g>',
 "pages":   f'<rect x="46" y="4" width="98" height="84" rx="10" fill="none" stroke="{W}" stroke-width="11"/>'
            f'<rect x="30" y="22" width="98" height="84" rx="10" fill="{DARK}" stroke="{W}" stroke-width="11"/>'
            f'<rect x="14" y="40" width="98" height="84" rx="10" fill="{W}"/>',
 "news":    f'<rect x="6" y="12" width="148" height="104" rx="12" fill="none" stroke="{W}" stroke-width="12"/>'
            f'<rect x="26" y="32" width="50" height="38" rx="4" fill="{W}"/>'
            f'<g stroke="{W}" stroke-width="11" stroke-linecap="round"><line x1="94" y1="38" x2="136" y2="38"/><line x1="94" y1="62" x2="136" y2="62"/><line x1="26" y1="94" x2="136" y2="94"/></g>',
 "magnet":  f'<path d="M26 8 v56 a54 54 0 0 0 108 0 v-56" fill="none" stroke="{W}" stroke-width="32"/>'
            f'<rect x="8" y="30" width="36" height="12" fill="{DARK}"/><rect x="116" y="30" width="36" height="12" fill="{DARK}"/>',
}

# app dir → (label, glyph, ring colour); None = neutral (no badge)
APPS = {
 "MetaCore": None,
 "MetaShare": ("SHARE", "nodes", TEAL),
 "MetaGateway": ("GATEWAY", "arrow", ORANGE),
 "MetaSort": ("SORT", "layers", GOLD),
 "MetaFuse": ("FUSE", "folder", GREEN),
 "MetaStremio": ("PLAY", "play", PURPLE),
 "MetaFeederTMDB": ("TMDB", "cards", ORANGE),
 "MetaFeederProwlarr": ("PROWLARR", "search", ORANGE),
 "MetaFeederOpenSubtitles": ("OPENSUBS", "caption", ORANGE),
 "MetaFeederGutenberg": ("GUTENBERG", "book", ORANGE),
 "MetaFeederWikiCommons": ("COMMONS", "photo", ORANGE),
 "MetaFeederGiphy": ("GIPHY", "gif", ORANGE),
 "MetaFeederArxiv": ("ARXIV", "paper", ORANGE),
 "MetaFeederEuropePMC": ("EUROPE PMC", "medical", ORANGE),
 "MetaFeederSciHub": ("SCI-HUB", "flask", ORANGE),
 "MetaFeederAniList": ("ANILIST", "idcard", ORANGE),
 "MetaFeederSuwayomi": ("SUWAYOMI", "pages", ORANGE),
 "MetaFeederUsenet": ("USENET", "news", ORANGE),
 "MetaFeederTribler": ("TRIBLER", "magnet", ORANGE),
}

BADGE_C, BADGE_R, RING = (770, 770), 226, 18
LABEL_MAX_W, LABEL_MAX_PT = 340, 72

def label_size(text):
    w = int(subprocess.run(["convert", "-font", FONT_IM, "-pointsize", str(LABEL_MAX_PT), f"label:{text}",
                            "-format", "%w", "info:"], capture_output=True, text=True, check=True).stdout)
    return min(LABEL_MAX_PT, LABEL_MAX_PT * LABEL_MAX_W / w)

def icon_svg(spec):
    if spec is None:
        svg, _, _ = mesh_svg(512, 512, 385, stroke=11, **MESH)
        return svg
    label, glyph, ring = spec
    svg, _, _ = mesh_svg(500, 500, 340, stroke=10, **MESH)
    cx, cy = BADGE_C
    size = label_size(label)
    badge = (f'<circle cx="{cx}" cy="{cy}" r="{BADGE_R}" fill="{ring}"/>'
             f'<circle cx="{cx}" cy="{cy}" r="{BADGE_R - RING}" fill="{DARK}"/>'
             f'<g transform="translate({cx - 80},{cy - 128})">{G[glyph]}</g>'
             f'<text x="{cx}" y="{cy + 112}" text-anchor="middle" font-family="{FONT_SVG}" font-weight="bold" '
             f'font-size="{size:.1f}" fill="{W}">{label}</text>')
    return svg.replace("</svg>", badge + "</svg>")

def render(app, out_dir):
    svg_path = os.path.join(out_dir, f"{app}.svg")
    png_path = os.path.join(out_dir, f"{app}.png")
    open(svg_path, "w").write(icon_svg(APPS[app]))
    subprocess.run(["rsvg-convert", "-w", "1024", "-h", "1024", svg_path, "-o", png_path], check=True)
    return png_path

if __name__ == "__main__":
    out = sys.argv[1]; os.makedirs(out, exist_ok=True)
    for app in (sys.argv[2:] or list(APPS)):
        print(render(app, out))
