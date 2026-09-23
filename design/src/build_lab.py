#!/usr/bin/env python3
import pathlib
H = pathlib.Path('.')

RED, AMBER, VIOLET, EMERALD = '#E23A2E', '#F0A030', '#8B5CF6', '#16B981'

def head(t):
    return (f'<!doctype html><html lang="en"><head><meta charset="utf-8"><title>{t}</title>'
            f'<link rel="stylesheet" href="lab.css"></head><body>')

G_FACE = ('<path d="M4 3h5v2.2H6.2V8H4V3zm11 0h5v5h-2.2V5.2H15V3zM4 16h2.2v2.8H9V21H4v-5z'
          'm14 0h2V21h-5v-2.2h3V16z"/><circle cx="9.4" cy="10.6" r="1.35"/>'
          '<circle cx="14.6" cy="10.6" r="1.35"/>'
          '<path d="M8.7 14.1a.9.9 0 0 1 1.26-.16 3.3 3.3 0 0 0 4.08 0 .9.9 0 1 1 1.1 1.42 5.1 5.1 0 0 1-6.28 0 .9.9 0 0 1-.16-1.26z"/>')
G_OBJ = '<path d="M12 2.4 20.8 7.2v9.6L12 21.6 3.2 16.8V7.2L12 2.4zm0 2.3L5.6 8 12 11.5 18.4 8 12 4.7zM5 9.6v6l6 3.3v-6l-6-3.3zm8 9.3 6-3.3v-6l-6 3.3v6z"/>'
G_INK = '<path d="M3 17.4 14.2 6.2l3.6 3.6L6.6 21H3v-3.6zM15.6 4.8l1.7-1.7a1.6 1.6 0 0 1 2.24 0l1.36 1.36a1.6 1.6 0 0 1 0 2.24L19.2 8.4l-3.6-3.6z"/>'
G_TAG = '<path d="M11.7 2.6H20a1.4 1.4 0 0 1 1.4 1.4v8.3a1.4 1.4 0 0 1-.41 1l-8.6 8.6a1.4 1.4 0 0 1-1.98 0l-8.3-8.3a1.4 1.4 0 0 1 0-1.98l8.6-8.6a1.4 1.4 0 0 1 .99-.41zM17 5.6a1.8 1.8 0 1 0 0 3.6 1.8 1.8 0 0 0 0-3.6z"/>'

def gl(path, color, size=21):
    return f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="{color}">{path}</svg>'

CHEV = ('<svg width="8" height="14" viewBox="0 0 9 15" fill="none"><path d="M1.5 1.5 7 7.5l-5.5 6" '
        'stroke="rgba(255,255,255,.32)" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>')
BACK = ('<svg width="16" height="14" viewBox="0 0 17 15" fill="none"><path d="M7.5 1 1 7.5 7.5 14M1.2 7.5H16" '
        'stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>')
ARROW = ('<svg width="14" height="12" viewBox="0 0 17 15" fill="none"><path d="M9.5 1 16 7.5 9.5 14M15.8 7.5H1" '
         'stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>')
GEAR = ('<svg width="18" height="18" viewBox="0 0 24 24" fill="#fff"><path d="M12 8.6a3.4 3.4 0 1 0 0 6.8 3.4 3.4 0 0 0 0-6.8z'
        'm9.4 3.4c0 .5 0 .9-.1 1.4l1.9 1.5a.45.45 0 0 1 .1.57l-1.8 3.1a.45.45 0 0 1-.55.2l-2.2-.9a7 7 0 0 1-2.3 1.35l-.35 2.4'
        'a.45.45 0 0 1-.44.38h-3.6a.45.45 0 0 1-.44-.38l-.35-2.4a7 7 0 0 1-2.3-1.35l-2.2.9a.45.45 0 0 1-.55-.2l-1.8-3.1'
        'a.45.45 0 0 1 .1-.57l1.9-1.5a7.2 7.2 0 0 1 0-2.8l-1.9-1.5a.45.45 0 0 1-.1-.57l1.8-3.1a.45.45 0 0 1 .55-.2l2.2.9'
        'A7 7 0 0 1 9.3 4.4l.35-2.4a.45.45 0 0 1 .44-.38h3.6a.45.45 0 0 1 .44.38l.35 2.4a7 7 0 0 1 2.3 1.35l2.2-.9'
        'a.45.45 0 0 1 .55.2l1.8 3.1a.45.45 0 0 1-.1.57l-1.9 1.5c.1.5.1.9.1 1.4z"/></svg>')
SWAP = ('<svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M5 8.5h13l-3.2-3.2M19 15.5H6l3.2 3.2" '
        'stroke="#fff" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/></svg>')
PHOTO = ('<svg width="17" height="17" viewBox="0 0 24 24" fill="#fff"><path d="M4 5h4l1.4-2h5.2L16 5h4a1.6 1.6 0 0 1 1.6 1.6'
         'v11.8A1.6 1.6 0 0 1 20 20H4a1.6 1.6 0 0 1-1.6-1.6V6.6A1.6 1.6 0 0 1 4 5zm8 3.6a4.4 4.4 0 1 0 0 8.8 4.4 4.4 0 0 0 0-8.8z"/></svg>')

# Line-art face used as the featured card's artwork.
ART = '''<svg width="190" height="200" viewBox="0 0 190 200" fill="none">
 <g stroke="#FF6B5A" stroke-width="1.15" fill="none" opacity="0.95">
  <ellipse cx="95" cy="100" rx="52" ry="65"/>
  <ellipse cx="95" cy="100" rx="38" ry="52" opacity=".45"/>
  <path d="M60 78c7-6 21-7 30-2M100 76c9-5 23-4 30 4"/>
  <path d="M62 95c7 6 20 6 27 0M103 95c7-8 21-8 28 0"/>
  <path d="M97 84l-3 36M79 126c7-6 25-6 33 0M79 126c8 11 25 11 33 0"/>
  <path d="M43 100h-14M147 100h14M95 35V22M95 165v13" opacity=".5"/>
 </g>
 <g fill="#fff" opacity=".95">
  <circle cx="72" cy="88" r="2.4"/><circle cx="118" cy="87" r="2.4"/>
  <circle cx="95" cy="120" r="2.4"/><circle cx="79" cy="126" r="2.4"/>
  <circle cx="112" cy="126" r="2.4"/><circle cx="66" cy="112" r="2.4"/>
  <circle cx="124" cy="111" r="2.4"/>
 </g>
</svg>'''

LOCK = ('<svg width="20" height="20" viewBox="0 0 24 24" fill="#fff"><path d="M12 1.8a5.2 5.2 0 0 1 5.2 5.2v2.4h.8'
        'A2 2 0 0 1 20 11.4v8.4a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-8.4a2 2 0 0 1 2-2h.8V7A5.2 5.2 0 0 1 12 1.8zm0 2.2'
        'A3 3 0 0 0 9 7v2.4h6V7a3 3 0 0 0-3-3zm0 10a1.9 1.9 0 0 0-.9 3.6v1.7a.9.9 0 0 0 1.8 0v-1.7A1.9 1.9 0 0 0 12 14z"/></svg>')

# ── Screen 1 · Home ─────────────────────────────────────────────────────────
def row(glyph, color, label, sub, trail):
    return (f'<div class="row"><div class="chipicon" style="background:{color}22">'
            f'{gl(glyph, color)}</div>'
            f'<div style="flex:1"><div class="label">{label}</div>'
            f'<div class="sub">{sub}</div></div>{trail}</div>')

HOME = f'''<div class="glow"></div><div class="page">
<div style="display:flex;align-items:flex-end;padding:26px 20px 0">
  <div style="flex:1">
    <div class="eyebrow">Google ML Kit &middot; on device</div>
    <div class="h1" style="margin-top:6px">Vision Lab</div>
  </div>
  <a class="circlebtn" href="#">{GEAR}</a>
</div>

<div style="margin-top:24px"><div class="feature">
  <div class="bloom"></div>
  <div class="art">{ART}</div>
  <div class="inner">
    <div class="eyebrow" style="color:rgba(255,255,255,.62)">Model 01</div>
    <div class="h2" style="font-size:24px;margin-top:5px">Face<br>Detection</div>
    <div style="flex:1"></div>
    <a class="pill" href="#"><span>Open</span><span class="arrow">{ARROW}</span></a>
  </div>
</div></div>

<div style="padding:26px 20px 12px" class="eyebrow">More models</div>
<div class="card">
  {row(G_OBJ, AMBER,   'Object Detection', 'Boxes and tracking, five per frame', '<div class="tag">Soon</div>')}
  {row(G_INK, VIOLET,  'Digital Ink',      'Handwriting in 300+ locales',        '<div class="tag">Soon</div>')}
  {row(G_TAG, EMERALD, 'Image Labeling',   '400+ concepts with confidence',      '<div class="tag">Soon</div>')}
</div>

<div style="margin-top:22px"><div class="card"><div class="row" style="height:78px">
  <div class="chipicon" style="background:rgba(255,255,255,.08)">{LOCK}</div>
  <div style="flex:1">
    <div class="label">Private by design</div>
    <div class="sub" style="margin-top:3px">Frames are processed locally and never leave this device.</div>
  </div>
</div></div></div>
</div>'''
(H/'30-home.html').write_text(head('Vision Lab') + HOME + '</body></html>')

# ── Camera artwork ──────────────────────────────────────────────────────────
STAGE = '''<svg width="390" height="530" viewBox="0 0 390 530" fill="none" xmlns="http://www.w3.org/2000/svg">
 <rect width="390" height="530" fill="#0C0C0F"/>
 <ellipse cx="195" cy="250" rx="250" ry="250" fill="#16161B"/>
 <ellipse cx="195" cy="250" rx="150" ry="160" fill="#E23A2E" fill-opacity="0.07"/>
 <ellipse cx="195" cy="612" rx="200" ry="130" fill="#1F1F26"/>
 <rect x="168" y="330" width="54" height="72" fill="#2A2A33"/>
 <ellipse cx="121" cy="258" rx="9" ry="18" fill="#2F2F3A"/>
 <ellipse cx="269" cy="258" rx="9" ry="18" fill="#2F2F3A"/>
 <ellipse cx="195" cy="234" rx="86" ry="100" fill="#1B1B21"/>
 <ellipse cx="195" cy="254" rx="72" ry="88" fill="#36363F"/>
 <ellipse cx="195" cy="184" rx="74" ry="46" fill="#1B1B21"/>

 <g stroke="#FF6B5A" fill="none" stroke-width="1.3" stroke-opacity="0.85">
  <ellipse cx="195" cy="254" rx="72" ry="88" stroke-opacity="0.32"/>
  <path d="M147 220c10-7 28-8 40-2M203 218c12-6 30-5 39 5"/>
  <path d="M150 243c10 7 28 7 38-1"/>
  <path d="M203 242c9-11 28-11 38 0-10 11-29 11-38 0z"/>
  <path d="M198 227l-4 48M177 284c9-8 30-8 40 0M177 284c10 14 30 14 40 0"/>
  <path d="M170 312c12-9 34-9 46 1M170 312c13 16 34 16 46 1"/>
 </g>
 <g fill="#fff">
  <circle cx="168" cy="245" r="2.6"/><circle cx="222" cy="242" r="2.6"/>
  <circle cx="155" cy="284" r="2.6"/><circle cx="235" cy="281" r="2.6"/>
  <circle cx="195" cy="286" r="2.6"/>
  <circle cx="172" cy="313" r="2.6"/><circle cx="218" cy="311" r="2.6"/>
  <circle cx="195" cy="323" r="2.6"/>
 </g>
 <g stroke="#E23A2E" stroke-width="2.6" fill="none" stroke-linecap="round">
  <path d="M118 182v-18a8 8 0 0 1 8-8h18M264 156h18a8 8 0 0 1 8 8v18"/>
  <path d="M290 330v18a8 8 0 0 1-8 8h-18M144 356h-18a8 8 0 0 1-8-8v-18"/>
 </g>
</svg>'''

# ── Screen 2 · Face detection ───────────────────────────────────────────────
def stat(k, v, pct, color=RED):
    return (f'<div class="stat"><div class="k">{k}</div><div class="v">{v}</div>'
            f'<div class="bar"><i style="width:{pct}%;background:{color}"></i></div></div>')

FACE = f'''<div class="stage">{STAGE}</div>
<div class="topbar">
  <a class="circlebtn" href="#">{BACK}</a>
  <div class="t">Face Detection</div>
  <a class="circlebtn" href="#">{SWAP}</a>
</div>
<div class="livechip"><span class="dot"></span>1 face &middot; 24 ms</div>

<div class="sheet">
  <div class="grab"></div>
  <div class="stats">
    {stat('Smile', '94%', 94)}
    {stat('Left eye', '98%', 98)}
    {stat('Right eye', '11%', 11, AMBER)}
  </div>
  <div class="pose">
    <div><div class="k">Yaw</div><div class="v">&minus;12.4&deg;</div></div>
    <div><div class="k">Pitch</div><div class="v">+3.1&deg;</div></div>
    <div><div class="k">Roll</div><div class="v">+0.8&deg;</div></div>
  </div>
  <div class="controls">
    <div class="ctl on">{PHOTO}<span>Photo</span></div>
    <div class="ctl">{GEAR}<span>Settings</span></div>
  </div>
</div>'''
(H/'31-face.html').write_text(head('Face Detection') + FACE + '</body></html>')

# ── Screen 3 · Settings ─────────────────────────────────────────────────────
def swrow(label, sub, on, cost=''):
    return (f'<div class="row"><div style="flex:1"><div class="label">{label}</div>'
            f'<div class="sub">{sub}</div></div>'
            f'<div class="cost">{cost}</div><div class="sw{" on" if on else ""}"></div></div>')

SETTINGS = f'''<div class="stage">{STAGE}</div>
<div class="topbar">
  <a class="circlebtn" href="#">{BACK}</a><div class="t">Face Detection</div>
</div>
<div class="scrim"></div>
<div class="modal">
  <div class="grab"></div>
  <div style="display:flex;align-items:center;padding:0 2px 18px">
    <div class="h2" style="flex:1;font-size:22px">Settings</div>
    <a class="circlebtn" href="#" style="width:34px;height:34px">
      <svg width="13" height="13" viewBox="0 0 14 14" fill="none"><path d="M1 1l12 12M13 1L1 13"
        stroke="#fff" stroke-width="2.2" stroke-linecap="round"/></svg></a>
  </div>

  <div class="eyebrow" style="padding:0 2px 10px">Accuracy</div>
  <div class="seg"><span class="on">Fast</span><span>Accurate</span></div>

  <div class="eyebrow" style="padding:22px 2px 10px">What the model returns</div>
  <div class="card" style="margin:0">
    {swrow('Contours', '133 outline points', True, '+18 ms')}
    {swrow('Landmarks', 'Eyes, nose, mouth, ears', True, '+2 ms')}
    {swrow('Expression', 'Smile and eye-open scores', True, '+3 ms')}
    {swrow('Tracking', 'Stable ids across frames', True)}
  </div>
  <div class="body" style="padding:12px 4px 0">Timings measured on this device over
    the last 120 frames.</div>

  <div class="eyebrow" style="padding:20px 2px 10px">Overlay</div>
  <div class="card" style="margin:0">
    {swrow('Mesh', 'Draw contours over the face', True)}
    {swrow('Mirror', 'Flip the front camera', True)}
  </div>
</div>'''
(H/'32-settings.html').write_text(head('Settings') + SETTINGS + '</body></html>')
print('built 3 screens')
