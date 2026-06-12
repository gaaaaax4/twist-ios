"""
Twist app icon – two helical arrows intertwining like a DNA double helix.
They wind around a shared vertical axis and alternate front/back at each
crossing, giving a spiral "twist" appearance.
4x supersampling → downscale to 1024 for smooth edges.
"""
from PIL import Image, ImageDraw, ImageFilter
import math

FINAL = 1024
SCALE = 4
S     = FINAL * SCALE

# ── Geometry helpers ──────────────────────────────────────────────────────────

def normals(pts):
    norms = []
    for i in range(len(pts)):
        if i == 0:
            dx,dy = pts[1][0]-pts[0][0], pts[1][1]-pts[0][1]
        elif i == len(pts)-1:
            dx,dy = pts[-1][0]-pts[-2][0], pts[-1][1]-pts[-2][1]
        else:
            dx,dy = pts[i+1][0]-pts[i-1][0], pts[i+1][1]-pts[i-1][1]
        L = math.hypot(dx,dy) or 1
        norms.append((-dy/L, dx/L))
    return norms

def stroke_poly(pts, half):
    nms = normals(pts)
    left  = [(p[0]+n[0]*half, p[1]+n[1]*half) for p,n in zip(pts,nms)]
    right = [(p[0]-n[0]*half, p[1]-n[1]*half) for p,n in zip(pts,nms)]
    return left + list(reversed(right))

def cap(draw, pt, color, r):
    draw.ellipse([pt[0]-r, pt[1]-r, pt[0]+r, pt[1]+r], fill=color)

def arrowhead(tip, prev, size):
    dx,dy = tip[0]-prev[0], tip[1]-prev[1]
    L = math.hypot(dx,dy) or 1
    dx/=L; dy/=L
    px,py = -dy, dx
    bx,by = tip[0]-dx*size, tip[1]-dy*size
    return [tip, (bx+px*size*0.55, by+py*size*0.55),
                 (bx-px*size*0.55, by-py*size*0.55)]

# ── Colours ───────────────────────────────────────────────────────────────────
BG        = (13,  13,  18)
GREEN     = (52,  199,  89)   # Spotify green
RED       = (252,  60,  68)   # Apple Music red
RED_DIM   = (180,  30,  38)   # dimmer Apple Music red

HALF  = int(62 * SCALE / 2)
ASIZ  = 88 * SCALE

cx, cy = S//2, S//2

# ── Helix curves ──────────────────────────────────────────────────────────────
# The helix is parameterised along the icon's diagonal.
# Horizontal axis  = diagonal direction (lower-left to upper-right).
# The two strands oscillate transversely with a phase offset of π.

N     = 1200        # samples per curve
TURNS = 1.5         # number of full revolutions
DIAG  = S * 0.80    # total length of diagonal axis
AMPL  = S * 0.155   # transverse oscillation amplitude

# Rotation of the whole helix (45° tilted diagonal)
ANGLE = math.radians(-45)
ca, sa = math.cos(ANGLE), math.sin(ANGLE)

def helix_curve(phase_offset):
    pts = []
    for i in range(N+1):
        t   = i / N                      # 0 → 1 along axis
        axial  = (t - 0.5) * DIAG       # distance along axis, centred
        transv = AMPL * math.sin(2 * math.pi * TURNS * t + phase_offset)
        # Rotate into canvas coords
        x = cx + axial * ca - transv * sa
        y = cy + axial * sa + transv * ca
        pts.append((x, y))
    return pts

curve1 = helix_curve(0)          # strand 1: starts left-transverse
curve2 = helix_curve(math.pi)    # strand 2: starts right-transverse (180° off)

# ── Find crossings (where strands swap front/back) ───────────────────────────
# Crossings occur every half-turn ⇒ at t = k / (2*TURNS), k=1..floor(2*TURNS)
crossing_indices = []
for k in range(1, int(2 * TURNS)):
    t_cross = k / (2 * TURNS)
    crossing_indices.append(int(t_cross * N))

# Build alternating segments: odd k → curve1 in front, even k → curve2 in front
GAP = 36   # indices to hide on each side of a crossing

segments = []   # list of (curve, color, start_i, end_i)

prev = 0
for seg_idx, ci in enumerate(crossing_indices + [N]):
    seg_end = ci
    # Before crossing ci: which is in front?
    if seg_idx % 2 == 0:
        front, fcol = curve1, GREEN
        back,  bcol = curve2, RED_DIM
    else:
        front, fcol = curve2, RED
        back,  bcol = curve1, GREEN

    start = prev
    end   = seg_end

    # Draw back first, then front
    segments.append(('back',  back,  bcol, start, end))
    segments.append(('front', front, fcol, start, end))
    prev = ci

# ── Render ────────────────────────────────────────────────────────────────────
img  = Image.new('RGB', (S, S), BG)

# Glow (use curve1 for both as a combined soft halo)
glow = Image.new('RGB', (S, S), BG)
gd   = ImageDraw.Draw(glow)
gd.polygon(stroke_poly(curve1, HALF + 70), fill=(55, 190, 85))
gd.polygon(stroke_poly(curve2, HALF + 70), fill=(230, 60, 65))
glow = glow.filter(ImageFilter.GaussianBlur(radius=80))
img  = Image.blend(img, glow, alpha=0.38)

draw = ImageDraw.Draw(img)

# Start caps
cap(draw, curve1[0], GREEN, HALF)
cap(draw, curve2[0], RED,   HALF)

# Draw all segments in order (back before front at each crossing)
# Re-sort so all "back" entries for a given segment come before "front"
# We already appended them in (back, front) order — process sequentially.
for (layer, curve, col, si, ei) in segments:
    if layer == 'back':
        seg = curve[si : ei - GAP] if ei - GAP > si else curve[si:si+1]
    else:
        seg = curve[si + GAP : ei] if si + GAP < ei else curve[ei-1:ei]
    if len(seg) > 1:
        draw.polygon(stroke_poly(seg, HALF), fill=col)

# Arrowheads at the ends
draw.polygon(arrowhead(curve1[-1], curve1[-40], ASIZ), fill=GREEN)
draw.polygon(arrowhead(curve2[-1], curve2[-40], ASIZ), fill=RED)

# ── Downscale → 1024 ─────────────────────────────────────────────────────────
img = img.resize((FINAL, FINAL), Image.LANCZOS)

out = 'Twist/Assets.xcassets/AppIcon.appiconset/AppIcon.png'
img.save(out)
print(f'Saved → {out}')
