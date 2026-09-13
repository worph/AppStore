"""MetaMesh icon v2 — procedural low-poly mesh sphere, pure Python → SVG.

Spirit of the v1 art: a wireframe ball of round nodes of varying size, thick
edges, teal (top-left) → blue → purple (bottom) gradient, on white.
"""
import math, random, sys

TEAL, BLUE, PURPLE = (38, 205, 181), (61, 126, 205), (130, 78, 212)

def lerp(a, b, t): return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))
def grad(t):
    t = max(0.0, min(1.0, t))
    return lerp(TEAL, BLUE, t / 0.55) if t < 0.55 else lerp(BLUE, PURPLE, (t - 0.55) / 0.45)
def hexc(c): return "#%02x%02x%02x" % c

def sphere_points(n, seed):
    rnd = random.Random(seed)
    pts, ga = [], math.pi * (3 - math.sqrt(5))
    for i in range(n):
        y = 1 - (i + 0.5) / n * 2
        r = math.sqrt(1 - y * y)
        th = ga * i + rnd.uniform(-0.25, 0.25)
        x, z = math.cos(th) * r, math.sin(th) * r
        y += rnd.uniform(-0.05, 0.05)
        l = math.sqrt(x * x + y * y + z * z)
        pts.append((x / l, y / l, z / l))
    return pts

def rotate(p, ax, ay):
    x, y, z = p
    y, z = y * math.cos(ax) - z * math.sin(ax), y * math.sin(ax) + z * math.cos(ax)
    x, z = x * math.cos(ay) + z * math.sin(ay), -x * math.sin(ay) + z * math.cos(ay)
    return (x, y, z)

def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]

def hull_faces(pts, eps=1e-9):
    n, faces = len(pts), []
    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                nrm = cross(sub(pts[j], pts[i]), sub(pts[k], pts[i]))
                pos = neg = False
                for m in range(n):
                    if m in (i, j, k): continue
                    d = dot(nrm, sub(pts[m], pts[i]))
                    if d > eps: pos = True
                    elif d < -eps: neg = True
                    if pos and neg: break
                if not (pos and neg):
                    if dot(nrm, pts[i]) < 0: nrm = (-nrm[0], -nrm[1], -nrm[2])
                    faces.append(((i, j, k), nrm))
    return faces

def mesh_svg(cx, cy, R, n=30, seed=7, ax=-0.35, ay=0.5, stroke=13, size=1024, background=True):
    pts = [rotate(p, ax, ay) for p in sphere_points(n, seed)]
    faces = hull_faces(pts)
    edges = set()
    for (i, j, k), nrm in faces:
        if nrm[2] > -0.05:                        # front-facing + silhouette
            for a, b in ((i, j), (j, k), (i, k)):
                edges.add((min(a, b), max(a, b)))
    used = sorted({v for e in edges for v in e})
    proj = {i: (cx + R * pts[i][0], cy - R * pts[i][1], pts[i][2]) for i in used}
    def colour(i):
        x, y, _ = proj[i]
        return grad(((x - (cx - R)) * 0.3 + (y - (cy - R)) * 0.7) / (2 * R))
    rnd = random.Random(seed * 31)
    radius = {i: (9 + 10 * (0.5 + 0.5 * proj[i][2])) * rnd.choice([1.0, 1.0, 1.0, 1.6, 2.1]) for i in used}
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 {size} {size}">', "<defs>"]
    body = []
    for idx, (a, b) in enumerate(sorted(edges, key=lambda e: proj[e[0]][2] + proj[e[1]][2])):
        (x1, y1, z1), (x2, y2, z2) = proj[a], proj[b]
        out.append(f'<linearGradient id="e{idx}" gradientUnits="userSpaceOnUse" x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}">'
                   f'<stop offset="0" stop-color="{hexc(colour(a))}"/><stop offset="1" stop-color="{hexc(colour(b))}"/></linearGradient>')
        w = stroke * (0.75 + 0.25 * (0.5 + 0.25 * (z1 + z2)))
        body.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="url(#e{idx})" stroke-width="{w:.1f}" stroke-linecap="round"/>')
    for i in sorted(used, key=lambda i: proj[i][2]):
        x, y, _ = proj[i]
        body.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{radius[i]:.1f}" fill="{hexc(colour(i))}"/>')
    out.append("</defs>")
    if background:
        out.append(f'<rect width="{size}" height="{size}" fill="#fefefe"/>')
    out += body + ["</svg>"]
    return "\n".join(out), len(used), len(edges)

if __name__ == "__main__":
    svg, nv, ne = mesh_svg(512, 512, 360)
    open(sys.argv[1], "w").write(svg)
    print(f"nodes={nv} edges={ne}")
