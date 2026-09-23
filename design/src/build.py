#!/usr/bin/env python3
"""Rebuild every mockup HTML file from the shared parts."""
import pathlib

HERE = pathlib.Path(__file__).parent
VP = (HERE / '_viewport.svg.html').read_text()

def head(title, extra=''):
    return (f'<!doctype html>\n<html lang="en"><head><meta charset="utf-8">'
            f'<title>{title}</title>\n<link rel="stylesheet" href="base.css">{extra}</head><body>')

BACK = ('<a class="back" href="#"><svg width="11" height="17" viewBox="0 0 11 17" fill="none">'
        '<path d="M9 1.5L2 8.5L9 15.5" stroke="currentColor" stroke-width="2.2" '
        'stroke-linecap="round" stroke-linejoin="round"/></svg>Detectors</a>')
CHEV = ('<svg class="chev" width="8" height="13" viewBox="0 0 8 13" fill="none">'
        '<path d="M1.5 1L6.5 6.5L1.5 12" stroke="currentColor" stroke-width="2" '
        'stroke-linecap="round" stroke-linejoin="round"/></svg>')

NAV = f'<div class="nav">{BACK}<div class="title">Face</div><a class="action" href="#">Options</a></div>'
SOURCE = '''<div class="sourcebar">
  <div class="seg"><span class="on">Camera</span><span>Photo</span></div>
  <div class="lens">Front <svg width="15" height="15" viewBox="0 0 16 16" fill="none"><path d="M4 5H12L10.5 3M12 11H4L5.5 13" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/></svg></div>
</div>'''

def viewport(h=340, readout='<span>2 faces</span><span class="sep">&middot;</span><span class="mono">24 ms</span><span class="sep">&middot;</span><span class="mono">38 fps</span>'):
    style = '' if h == 340 else f' style="height:{h}px"'
    return f'<div class="viewport"{style}>{VP}<div class="readout">{readout}</div></div>'

def tabs(active):
    names = ['Faces', 'Landmarks', 'Contours', 'JSON']
    return '<div class="tabs">' + ''.join(
        f'<button class="{"on" if n == active else ""}">{n}</button>' for n in names) + '</div>'

def metric(k, v, pct, warn=False, flag=''):
    cls = ' class="warn"' if warn else ''
    return (f'<div class="metric"><div class="k">{k}</div>'
            f'<div class="bar"><i{cls} style="width:{pct}%"></i></div>'
            f'<div class="v mono">{v}</div><div class="flag">{flag}</div></div>')

# ── 02 / 05 · the detector screen ───────────────────────────────────────────
INSPECTOR = f'''<div class="inspector">
<div class="facehead"><div class="chip on">1</div><div class="name">Face 1</div>
  <div class="meta mono">tracking 7</div></div>
{metric('Smile', '0.941', 94)}
{metric('Left eye', '0.981', 98)}
{metric('Right eye', '0.110', 11, warn=True, flag='closed')}
<div class="pose">
  <div><div class="k">Yaw</div><div class="v mono">&minus;12.4&deg;</div></div>
  <div><div class="k">Pitch</div><div class="v mono">+3.1&deg;</div></div>
  <div><div class="k">Roll</div><div class="v mono">+0.8&deg;</div></div>
</div>
<div class="kv"><b>Box</b><span class="mono">118, 240</span><span>&middot;</span>
  <span class="mono">164 &times; 201</span><b style="margin-left:auto">133 contour points</b></div>
<div class="rule"></div>
<div class="facehead"><div class="chip off">2</div>
  <div class="name" style="font-weight:500;color:var(--ink-2)">Face 2</div>
  <div class="meta mono">tracking 9</div></div>
{metric('Smile', '0.213', 21)}
{metric('Left eye', '0.884', 88)}
{metric('Right eye', '0.902', 90)}
</div>'''

FACE = NAV + SOURCE + viewport() + tabs('Faces') + INSPECTOR

DARK = '''
<style>
:root{ --paper:#0E0E10; --surface:#151518; --sunken:#212127; --line:#2B2B31; --line-soft:#232329;
       --ink:#F2F1EE; --ink-2:#9BA0A6; --ink-3:#71767C; --ink-4:#4A4E54;
       --accent:#F4633A; --warn:#D2921F; --blue:#7EA0FF; --ok:#4FBF95; }
.seg span.on{box-shadow:0 1px 2px rgba(0,0,0,.55),0 0 0 .5px rgba(255,255,255,.08)}
.sw.on{background:#F2F1EE}.sw.on::after{background:#151518}
</style>'''

(HERE / '02-face-live.html').write_text(head('Face') + FACE + '</body></html>')
(HERE / '05-face-dark.html').write_text(head('Face', DARK) + FACE + '</body></html>')

# ── 01 · Detectors ──────────────────────────────────────────────────────────
def det(t, s, trail, dim=False):
    return (f'<div class="row{" dim" if dim else ""}"><div class="grow">'
            f'<div class="t">{t}</div><div class="s">{s}</div></div>{trail}</div>')

def run(t, s, ms):
    return (f'<div class="row"><div class="grow"><div class="t" style="font-weight:400">{t}</div>'
            f'<div class="s">{s}</div></div><div class="trail mono">{ms}</div></div>')

HOME = f'''<div class="h1">Detectors</div>
<div class="card">
  {det('Face', 'Boxes, contours, landmarks, head pose, expression', CHEV)}
  {det('Objects', 'Boxes and tracking ids, up to five per frame', '<div class="trail">Not built</div>', True)}
  {det('Ink', 'Handwritten strokes to text, 300+ locales', '<div class="trail">Not built</div>', True)}
  {det('Labels', 'Confidence-scored labels from a 400-concept set', '<div class="trail">Not built</div>', True)}
</div>
<div class="sect">Recent</div>
<div class="card">
  {run('Face &middot; front camera', '2 faces &middot; fast &middot; contours on', '24 ms')}
  {run('Face &middot; IMG_4021.HEIC', '1 face &middot; accurate &middot; contours on', '61 ms')}
  {run('Face &middot; rear camera', '0 faces &middot; fast &middot; min size 25%', '9 ms')}
</div>
<div class="foot">Runs are kept for this session only.</div>'''
(HERE / '01-detectors.html').write_text(head('Detectors') + HOME + '</body></html>')

# ── 03 · JSON ───────────────────────────────────────────────────────────────
def j(cls, txt):
    return f'<span class="{cls}">{txt}</span>'
K, N, S, P = (lambda t: j('k', t)), (lambda t: j('n', t)), (lambda t: j('s', t)), (lambda t: j('p', t))
JSON = f'''{NAV}{SOURCE}{viewport(214, '<span>2 faces</span><span class="sep">&middot;</span><span class="mono">24 ms</span>')}
{tabs('JSON')}
<div class="jsonbar"><span class="c">Frame 1,284 &middot; held</span><a href="#">Copy</a></div>
<pre class="json mono">{P('[')}
  {P('{')}
    {K('"trackingId"')}{P(':')} {N('7')}{P(',')}
    {K('"boundingBox"')}{P(':')} {P('{')} {K('"left"')}{P(':')} {N('118')}{P(',')} {K('"top"')}{P(':')} {N('240')}{P(',')}
                      {K('"width"')}{P(':')} {N('164')}{P(',')} {K('"height"')}{P(':')} {N('201')} {P('},')}
    {K('"headEulerAngleX"')}{P(':')} {N('3.1')}{P(',')}
    {K('"headEulerAngleY"')}{P(':')} {N('-12.4')}{P(',')}
    {K('"headEulerAngleZ"')}{P(':')} {N('0.8')}{P(',')}
    {K('"smilingProbability"')}{P(':')} {N('0.9412')}{P(',')}
    {K('"leftEyeOpenProbability"')}{P(':')} {N('0.9807')}{P(',')}
    {K('"rightEyeOpenProbability"')}{P(':')} {N('0.1102')}{P(',')}
    {K('"landmarks"')}{P(':')} {P('{')}
      {K('"leftEye"')}{P(':')} {P('[')}{N('202')}{P(',')} {N('148')}{P('],')}
      {K('"rightEye"')}{P(':')} {P('[')}{N('152')}{P(',')} {N('151')}{P('],')}
      {K('"noseBase"')}{P(':')} {P('[')}{N('176')}{P(',')} {N('186')}{P('],')}
      {P('…')} {S('"7 more"')}
    {P('},')}
    {K('"contours"')}{P(':')} {P('{')} {K('"face"')}{P(':')} {S('"36 points"')}{P(',')} {P('… }')}
  {P('},')}
  {P('{')} {K('"trackingId"')}{P(':')} {N('9')}{P(',')} {P('… }')}
{P(']')}</pre>'''
(HERE / '03-face-json.html').write_text(head('Face — JSON') + JSON + '</body></html>')

# ── 04 · Options ────────────────────────────────────────────────────────────
def sw(t, on, cost='', sub=''):
    subline = f'<div class="s">{sub}</div>' if sub else ''
    return (f'<div class="row"><div class="grow"><div class="t">{t}</div>{subline}</div>'
            f'<div class="cost mono">{cost}</div><div class="sw{" on" if on else ""}"></div></div>')

OPTS = f'''<div class="nav"><div style="width:64px"></div><div class="title">Options</div>
  <a class="action" href="#">Done</a></div>
<div class="sect">Model</div>
<div class="card">
  <div class="row"><div class="grow"><div class="t">Performance</div></div>
    <div class="seg"><span class="on">Fast</span><span>Accurate</span></div></div>
  <div class="row"><div class="grow"><div class="t">Minimum face size</div>
    <div class="s">Share of the frame width a face must fill</div></div>
    <div class="trail mono">15%</div>{CHEV}</div>
</div>
<div class="sect">Outputs<span class="note">cost per frame</span></div>
<div class="card">
  {sw('Contours', True, '+18 ms')}
  {sw('Landmarks', True, '+2 ms')}
  {sw('Classification', True, '+3 ms')}
  {sw('Tracking', True, '&mdash;')}
</div>
<div class="foot">Measured on this device over the last 120 frames.
  Turning contours off roughly doubles throughput.</div>
<div class="sect">Overlay</div>
<div class="card">
  {sw('Bounding boxes', True)}
  {sw('Contour mesh', True)}
  {sw('Landmark points', False)}
  {sw('Mirror front camera', True)}
</div>'''
(HERE / '04-options.html').write_text(head('Options') + OPTS + '</body></html>')
print('built 5 screens')
