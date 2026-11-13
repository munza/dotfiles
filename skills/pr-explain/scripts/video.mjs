// video.mjs <out-dir>: writes <out-dir>/video/index.html, a HyperFrames composition of the walkthrough
// as one light, tldraw-style canvas with a moving camera, from explain.json's `walkthrough` and the
// narration clips render.sh made in video/assets (audio-NN.wav, durations.json, timings.json).
// Each beat is one narration clip. Its actions run in order (or at the phrase named by `on`): boxes
// draw in, a labelled packet travels a line and the box it reaches appears, tags pop, the camera
// zooms to the boxes being talked about or out to the whole board.
import fs from "node:fs";
import path from "node:path";

const out = path.resolve(process.argv[2] ?? "");
const data = JSON.parse(fs.readFileSync(path.join(out, "explain.json"), "utf8"));
const wt = data.walkthrough;
const assets = path.join(out, "video", "assets");
const durations = JSON.parse(fs.readFileSync(path.join(assets, "durations.json"), "utf8"));
// Chatterbox (tts.py) writes no sentence timings: then actions run in order and there are no captions.
const timings = fs.existsSync(path.join(assets, "timings.json")) ? JSON.parse(fs.readFileSync(path.join(assets, "timings.json"), "utf8")) : [];
if (durations.length !== wt.beats.length) {
  console.error(`explain.json has ${wt.beats.length} beats but ${durations.length} were voiced; run build.mjs, then render.sh again`);
  process.exit(1);
}

const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const r1 = (n) => Math.round(n * 10) / 10;
const r3 = (n) => Math.round(n * 1000) / 1000;
// A DOM-safe id, one-to-one: "_" becomes "__" and any other character outside [A-Za-z0-9-] becomes
// _x<hex>_, so "api.v1" and "api_v1" stay apart.
const sid = (id) => Array.from(String(id), (c) => (/[a-zA-Z0-9-]/.test(c) ? c : c === "_" ? "__" : `_x${c.codePointAt(0).toString(16)}_`)).join("");

// tldraw's light palette: [stroke, fill]. Notes use the stronger sticky-note fill.
const TONE = {
  black: ["#1d1d1d", "#ffffff"], blue: ["#4465e9", "#e4e9fd"], green: ["#099268", "#dcf0e8"],
  red: ["#e03131", "#fbe4e4"], yellow: ["#e5a13a", "#fdf2dc"], violet: ["#ae3ec9", "#f2e3f7"], grey: ["#8a939c", "#f1f3f5"],
};
const NOTE = { yellow: "#ffe49c", green: "#c6ead6", blue: "#d3dcfd", red: "#fbd0d0", violet: "#ecd3f4", grey: "#e6e8eb", black: "#ffe49c" };
const tone = (t) => TONE[t] ?? TONE.black;
const CELL = [360, 240]; // one grid step of `at`, in canvas pixels
// tldraw's four styles. Only "draw" is hand-drawn; the others have clean outlines and connectors.
// CW: average character width as a share of the font size, for wrapping and sizing labels.
const STYLES = {
  draw: { font: '"Shantell Sans", system-ui, sans-serif', cw: 0.56, stroke: 3 },
  sans: { font: '"IBM Plex Sans", system-ui, sans-serif', cw: 0.52, stroke: 2.5 },
  serif: { font: '"IBM Plex Serif", Georgia, serif', cw: 0.52, stroke: 2.5 },
  mono: { font: '"IBM Plex Mono", Menlo, monospace', cw: 0.61, stroke: 2.5 },
};
const STYLE = process.env.PR_EXPLAIN_STYLE || wt.style || "draw";
if (!STYLES[STYLE]) { console.error(`style is ${STYLE}; use ${Object.keys(STYLES).join(", ")}`); process.exit(1); }
const { cw: CW, stroke: SW } = STYLES[STYLE], DRAW = STYLE === "draw";

// Deterministic randomness, so a re-render draws the same wobble.
function seeded(key) {
  let h = 2166136261;
  for (const c of String(key)) h = Math.imul(h ^ c.charCodeAt(0), 16777619) >>> 0;
  return () => ((h = (Math.imul(h, 1664525) + 1013904223) >>> 0) / 4294967296);
}
const f = (p) => `${r1(p[0])} ${r1(p[1])}`;
// A smooth path through points (Catmull-Rom as cubic Béziers).
function smooth(pts) {
  let d = `M${f(pts[0])}`;
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[i - 1] ?? pts[i], p1 = pts[i], p2 = pts[i + 1], p3 = pts[i + 2] ?? p2;
    d += `C${f([p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6])} ${f([p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6])} ${f(p2)}`;
  }
  return d;
}
const polyLen = (pts) => pts.slice(1).reduce((a, p, i) => a + Math.hypot(p[0] - pts[i][0], p[1] - pts[i][1]), 0);
// Hand-drawn look: nudge each point along its normal by a slow, seeded wave.
function wobble(pts, rnd, amp, closed) {
  const [p1, p2, f1, f2] = [rnd() * 6.3, rnd() * 6.3, 0.25 + rnd() * 0.25, 0.7 + rnd() * 0.5];
  const n = pts.length;
  return pts.map(([x, y], i) => {
    const a = pts[closed ? (i - 1 + n) % n : Math.max(0, i - 1)], b = pts[closed ? (i + 1) % n : Math.min(n - 1, i + 1)];
    const tx = b[0] - a[0], ty = b[1] - a[1], l = Math.hypot(tx, ty) || 1;
    const k = amp * (0.65 * Math.sin(i * f1 + p1) + 0.35 * Math.sin(i * f2 + p2));
    return [x - (ty / l) * k, y + (tx / l) * k];
  });
}
// A closed outline drawn as one stroke that overlaps its start a little, like a pen.
function sketchClosed(pts, key, amp = 1.6) {
  if (!DRAW) { const all = [...pts, pts[0]]; return { d: smooth(all) + "Z", len: Math.ceil(polyLen(all) * 1.02) }; }
  const rnd = seeded(key);
  const s = Math.floor(rnd() * pts.length);
  const ring = [...pts.slice(s), ...pts.slice(0, s)];
  const w = wobble(ring, rnd, amp, true);
  const all = [...w, w[0], [w[1][0] + (rnd() - 0.5) * 3, w[1][1] + (rnd() - 0.5) * 3]];
  return { d: smooth(all), len: Math.ceil(polyLen(all) * 1.04) };
}
function sketchOpen(pts, key, amp = 1.2) {
  const w = DRAW ? wobble(pts, seeded(key), amp, false) : pts.map((p) => [...p]);
  w[0] = pts[0]; w[w.length - 1] = pts[pts.length - 1];
  return { d: smooth(w), len: Math.ceil(polyLen(w) * 1.04) };
}
function roundRect(x, y, w, h, r) {
  const pts = [];
  const seg = (x1, y1, x2, y2) => { const n = Math.max(2, Math.ceil(Math.hypot(x2 - x1, y2 - y1) / 24)); for (let i = 0; i < n; i++) pts.push([x1 + ((x2 - x1) * i) / n, y1 + ((y2 - y1) * i) / n]); };
  const arc = (cx, cy, a0) => { for (let i = 0; i < 4; i++) { const a = a0 + (i * Math.PI) / 8; pts.push([cx + r * Math.cos(a), cy + r * Math.sin(a)]); } };
  seg(x + r, y, x + w - r, y); arc(x + w - r, y + r, -Math.PI / 2);
  seg(x + w, y + r, x + w, y + h - r); arc(x + w - r, y + h - r, 0);
  seg(x + w - r, y + h, x + r, y + h); arc(x + r, y + h - r, Math.PI / 2);
  seg(x, y + h - r, x, y + r); arc(x + r, y + r, Math.PI);
  return pts;
}
const ellipse = (cx, cy, rx, ry, a0 = 0, a1 = Math.PI * 2, n = 28) =>
  Array.from({ length: n + (a1 - a0 < 6 ? 1 : 0) }, (_, i) => { const a = a0 + ((a1 - a0) * i) / n; return [cx + rx * Math.cos(a), cy + ry * Math.sin(a)]; });
const wrap = (text, max) => {
  const lines = [];
  for (const word of String(text ?? "").split(/\s+/).filter(Boolean)) {
    const last = lines[lines.length - 1];
    if (last != null && (last + " " + word).length <= max) lines[lines.length - 1] = last + " " + word;
    else lines.push(word);
  }
  return lines;
};

// ---- Geometry ---------------------------------------------------------------------------------
const nodes = new Map();
for (const n of wt.nodes) {
  const kind = n.kind ?? "box";
  const cx = (n.at?.[0] ?? 0) * CELL[0], cy = (n.at?.[1] ?? 0) * CELL[1];
  let w = n.w, h = n.h;
  const g = { ...n, kind, cx, cy };
  if (kind === "text") {
    g.title = wrap(n.label, 34); g.sub = n.note ? wrap(n.note, 70) : [];
    w ??= Math.max(...g.title.map((l) => l.length * 30), ...g.sub.map((l) => l.length * 13), 300);
    h ??= g.title.length * 72 + g.sub.length * 36 + 10;
  } else if (kind === "code") {
    g.lines = String(n.code ?? "").replace(/\n$/, "").split("\n");
    w ??= Math.max(380, Math.max(...g.lines.map((l) => l.length)) * 12.7 + 64);
    h ??= 74 + g.lines.length * 34 + 18;
  } else if (kind === "note") {
    w ??= 380;
    g.head = wrap(n.label, 22); g.body = (n.points ?? (n.note ? [n.note] : [])).map((p) => wrap(p, 30));
    h ??= 40 + g.head.length * 38 + 14 + g.body.reduce((a, l) => a + l.length * 30 + 10, 0) + 20;
  } else {
    w ??= kind === "device" || kind === "person" ? 230 : 240;
    const icon = ["device", "person", "server"].includes(kind) ? 50 : 0;
    const states = [{ label: n.label, note: n.note }];
    g.states = states; g.icon = icon;
    h ??= icon ? 176 : kind === "store" ? 160 : 130;
  }
  Object.assign(g, { w, h, x: cx - w / 2, y: cy - h / 2 });
  nodes.set(n.id, g);
}
// A frame with no boxes in it has no extent, so it's left out (build.mjs rejects one).
const frames = new Map((wt.frames ?? []).flatMap((fr) => {
  const inside = [...nodes.values()].filter((n) => n.frame === fr.id);
  if (!inside.length) { console.error(`warning: frame ${fr.id} has no boxes; leaving it out`); return []; }
  const pad = 56;
  const x = Math.min(...inside.map((n) => n.x)) - pad, y = Math.min(...inside.map((n) => n.y)) - pad;
  const w = Math.max(...inside.map((n) => n.x + n.w)) + pad - x, h = Math.max(...inside.map((n) => n.y + n.h)) + pad - y;
  return [[fr.id, { ...fr, x, y, w, h, members: inside.map((n) => n.id) }]];
}));
const box = (id) => nodes.get(id) ?? frames.get(id);

// `set` actions give a box more text states, in order.
for (const b of wt.beats) for (const a of b.do ?? []) if (a.set && nodes.get(a.set)?.states) {
  const g = nodes.get(a.set), last = g.states[g.states.length - 1];
  g.states.push({ label: a.label ?? last.label, note: a.note ?? last.note });
}

// Arrows: one per direction a packet ever travels, each offset to its own side of the centre line,
// so a request and its response run side by side. Each keeps its latest label beside it.
const links = new Map();
const pillWidth = (label) => String(label).length * 19 * CW + 34;
function edgePoint(n, tx, ty, pad = 14) {
  const dx = tx - n.cx, dy = ty - n.cy;
  const t = Math.min((n.w / 2 + pad) / Math.abs(dx || 1e-6), (n.h / 2 + pad) / Math.abs(dy || 1e-6));
  return [n.cx + dx * t, n.cy + dy * t];
}
for (const b of wt.beats) for (const a of b.do ?? []) if (a.send) {
  const [from, to] = a.send, k = `${from}>${to}`;
  if (links.has(k) || !nodes.has(from) || !nodes.has(to)) continue;
  const A = nodes.get(from), B = nodes.get(to);
  const p0 = edgePoint(A, B.cx, B.cy), q0 = edgePoint(B, A.cx, A.cy);
  const dx = q0[0] - p0[0], dy = q0[1] - p0[1], len = Math.hypot(dx, dy) || 1;
  const u = [dx / len, dy / len], n = [u[1], -u[0]], off = 13; // n: this direction's side
  const p = [p0[0] + n[0] * off, p0[1] + n[1] * off], q = [q0[0] + n[0] * off - u[0] * 3, q0[1] + n[1] * off - u[1] * 3];
  const pts = Array.from({ length: 16 }, (_, i) => [p[0] + ((q[0] - p[0]) * i) / 15, p[1] + ((q[1] - p[1]) * i) / 15]);
  const head = `M${f([q[0] - u[0] * 15 + n[0] * 8, q[1] - u[1] * 15 + n[1] * 8])}L${f(q)}L${f([q[0] - u[0] * 15 - n[0] * 8, q[1] - u[1] * 15 - n[1] * 8])}`;
  // Labels and tags fade rather than scale: GSAP's SVG scale origin left them shifted by a quarter of their size.
  links.set(k, { id: `l${links.size}`, from, to, head, p, q, n, ...sketchOpen(pts, k, 1.1) });
}

// Label placement: a label sits beside its own arrow, on the arrow's side, at the first point along it
// (middle first, then towards the ends) where it touches no box, no other label and no other arrow.
const placed = new Map(); // owner (arrow or box id) -> rect of its current label or tag
const pillRect = (c, label) => { const w = pillWidth(label) / 2 + 6; return { x0: c[0] - w, y0: c[1] - 25, x1: c[0] + w, y1: c[1] + 25 }; };
const hits = (a, b) => a.x0 < b.x1 && b.x0 < a.x1 && a.y0 < b.y1 && b.y0 < a.y1;
const crosses = (r, l) => { for (let i = 0; i <= 24; i++) { const x = l.p[0] + ((l.q[0] - l.p[0]) * i) / 24, y = l.p[1] + ((l.q[1] - l.p[1]) * i) / 24; if (x > r.x0 && x < r.x1 && y > r.y0 && y < r.y1) return true; } return false; };
function clashes(r, owner, skipLink) {
  let n = 0;
  for (const g of nodes.values()) if (hits(r, { x0: g.x, y0: g.y, x1: g.x + g.w, y1: g.y + g.h })) n += 3;
  for (const [o, pr] of placed) if (o !== owner && hits(r, pr)) n += 2;
  for (const l of links.values()) if (l !== skipLink && crosses(r, l)) n += 2;
  return n;
}
function choose(owner, label, candidates, skipLink) {
  let best = null;
  for (const c of candidates) {
    const r = pillRect(c, label), score = clashes(r, owner, skipLink);
    if (!best || score < best.score) best = { c, r, score };
    if (score === 0) break;
  }
  placed.set(owner, best.r);
  return best.c;
}
function placeLabel(l, label) {
  const d = Math.abs(l.n[0]) * (pillWidth(label) / 2) + Math.abs(l.n[1]) * 19 + 12;
  return choose(l.id, label, [0.5, 0.4, 0.6, 0.3, 0.7, 0.22, 0.78].map((t) => [l.p[0] + (l.q[0] - l.p[0]) * t + l.n[0] * d, l.p[1] + (l.q[1] - l.p[1]) * t + l.n[1] * d]), l);
}
function placeTag(g, label) {
  const hw = pillWidth(label) / 2;
  return choose(`tag:${g.id}`, label, [[g.x + g.w - 18, g.y - 2], [g.x + 18, g.y - 2], [g.cx, g.y - 24], [g.cx, g.y + g.h + 24], [g.x + g.w + hw - 10, g.cy], [g.x - hw + 10, g.cy]]);
}

// ---- SVG ----------------------------------------------------------------------------------------
const ICON = {
  device: (x, y, c) => `<rect x="${x - 14}" y="${y - 21}" width="28" height="42" rx="6"/><path d="M${x - 5} ${y + 14}h10"/>`,
  person: (x, y) => `<circle cx="${x}" cy="${y - 9}" r="9"/><path d="M${x - 17} ${y + 20}c0-12 8-17 17-17s17 5 17 17"/>`,
  server: (x, y) => `<rect x="${x - 21}" y="${y - 19}" width="42" height="16" rx="4"/><rect x="${x - 21}" y="${y + 3}" width="42" height="16" rx="4"/><path d="M${x - 13} ${y - 11}h.1M${x - 13} ${y + 11}h.1"/>`,
};
function textLines(lines, x, y, size, weight, color, lh, anchor = "middle", family = "var(--font)") {
  return lines.map((l, i) => `<text x="${r1(x)}" y="${r1(y + i * lh)}" font-size="${size}" font-weight="${weight}" fill="${color}" text-anchor="${anchor}" font-family="${family}">${esc(l)}</text>`).join("");
}
function stateSvg(g, s, k) {
  const label = wrap(s.label, Math.floor((g.w - 30) / (25 * CW))).slice(0, 2), note = s.note ? wrap(s.note, Math.floor((g.w - 26) / (18 * CW))).slice(0, 2) : [];
  const top = g.kind === "store" ? g.y + 22 : g.y;
  const area = g.h - (g.kind === "store" ? 22 : 0);
  const block = g.icon + label.length * 31 + (note.length ? 6 + note.length * 24 : 0);
  let y = top + (area - block) / 2;
  const icon = g.icon ? `<g class="icon" fill="none" stroke="${tone(g.tone)[0]}" stroke-width="${SW}" stroke-linecap="round" stroke-linejoin="round">${ICON[g.kind](g.cx, y + 22, tone(g.tone)[0])}</g>` : "";
  y += g.icon;
  const txt = textLines(label, g.cx, y + 24, 25, 600, "#1d1d1d", 31) + textLines(note, g.cx, y + label.length * 31 + 24, 18, 400, "#6b7280", 24);
  return `<g class="st st${k}"${k ? ' opacity="0"' : ""}>${icon}${txt}</g>`;
}
function nodeSvg(g) {
  const id = sid(g.id), [stroke, fill] = tone(g.tone);
  const hl = `<rect class="hl" x="${g.x - 16}" y="${g.y - 16}" width="${g.w + 32}" height="${g.h + 32}" rx="22" fill="#fff0a0" opacity="0"/>`;
  const origin = `transform-origin:${r1(g.cx)}px ${r1(g.cy)}px`;
  if (g.kind === "text")
    return `<g class="node" id="n-${id}" style="${origin}">${textLines(g.title, g.cx, g.y + 56, 58, 700, "#1d1d1d", 72)}${textLines(g.sub, g.cx, g.y + g.title.length * 72 + 30, 26, 400, "#6b7280", 36, "middle", "var(--sans)")}</g>`;
  if (g.kind === "note") {
    let y = g.y + 40 + 28;
    let body = textLines(g.head, g.x + 30, y, 30, 700, "#1d1d1d", 38, "start");
    y += g.head.length * 38 + 12;
    for (const lines of g.body) { body += textLines(lines.map((l, i) => (i ? "   " : "• ") + l), g.x + 30, y, 22, 400, "#2b2b2b", 30, "start"); y += lines.length * 30 + 10; }
    return `<g class="node note" id="n-${id}" style="${origin}"><g style="transform:rotate(-1.2deg);transform-origin:${r1(g.cx)}px ${r1(g.cy)}px"><rect x="${g.x}" y="${g.y}" width="${g.w}" height="${g.h}" rx="6" fill="${NOTE[g.tone] ?? NOTE.yellow}" filter="url(#shadow)"/>${body}</g></g>`;
  }
  if (g.kind === "code") {
    const o = sketchClosed(roundRect(g.x, g.y, g.w, g.h, 14), g.id);
    const bands = (g.highlight ?? []).map((n) => `<rect class="band" x="${g.x + 12}" y="${g.y + 74 + (n - 1) * 34 - 4}" width="${g.w - 24}" height="34" rx="6" fill="#fff0a0" opacity="0"/>`).join("");
    const code = g.lines.map((l, i) => `<text class="cl" x="${g.x + 30}" y="${g.y + 96 + i * 34}" font-size="21" fill="#1d1d1d" font-family="var(--mono)" xml:space="preserve">${esc(l)}</text>`).join("");
    return `<g class="node" id="n-${id}" style="${origin}">${hl}<rect class="fill" x="${g.x}" y="${g.y}" width="${g.w}" height="${g.h}" rx="14" fill="#ffffff"/>
      <path class="draw" d="${o.d}" data-len="${o.len}" stroke-dasharray="${o.len} ${o.len}" fill="none" stroke="${stroke}" stroke-width="${SW}" stroke-linecap="round"/>
      <g class="st st0"><text x="${g.x + 26}" y="${g.y + 38}" font-size="17" fill="#6b7280" font-family="var(--mono)">${esc(g.label ?? "")}</text><path d="M${g.x + 14} ${g.y + 56}H${g.x + g.w - 14}" stroke="#e5e7eb" stroke-width="2"/>${bands}${code}</g></g>`;
  }
  let fillD, o, extra = "";
  if (g.kind === "store") {
    const ry = 18, top = g.y + ry, bot = g.y + g.h - ry;
    fillD = `M${g.x} ${top}A${g.w / 2} ${ry} 0 0 1 ${g.x + g.w} ${top}V${bot}A${g.w / 2} ${ry} 0 0 1 ${g.x} ${bot}Z`;
    const body = [...ellipse(g.cx, top, g.w / 2, ry, Math.PI, 0, 14), ...ellipse(g.cx, bot, g.w / 2, ry, 0, Math.PI, 18)];
    o = sketchClosed(body, g.id);
    const lid = sketchClosed(ellipse(g.cx, top, g.w / 2, ry, 0, Math.PI * 2, 24), g.id + "lid", 1.2);
    extra = `<path class="draw" d="${lid.d}" data-len="${lid.len}" stroke-dasharray="${lid.len} ${lid.len}" fill="none" stroke="${stroke}" stroke-width="${SW}" stroke-linecap="round"/>`;
  } else {
    fillD = `M${g.x + 16} ${g.y}H${g.x + g.w - 16}Q${g.x + g.w} ${g.y} ${g.x + g.w} ${g.y + 16}V${g.y + g.h - 16}Q${g.x + g.w} ${g.y + g.h} ${g.x + g.w - 16} ${g.y + g.h}H${g.x + 16}Q${g.x} ${g.y + g.h} ${g.x} ${g.y + g.h - 16}V${g.y + 16}Q${g.x} ${g.y} ${g.x + 16} ${g.y}Z`;
    o = sketchClosed(roundRect(g.x, g.y, g.w, g.h, 16), g.id);
  }
  return `<g class="node" id="n-${id}" style="${origin}">${hl}<path class="fill" d="${fillD}" fill="${fill}"/>
    <path class="draw" d="${o.d}" data-len="${o.len}" stroke-dasharray="${o.len} ${o.len}" fill="none" stroke="${stroke}" stroke-width="${SW}" stroke-linecap="round" stroke-linejoin="round"/>${extra}
    ${g.states.map((s, k) => stateSvg(g, s, k)).join("")}</g>`;
}
const frameSvg = (fr) => `<g class="frame" id="f-${sid(fr.id)}"><rect x="${fr.x}" y="${fr.y}" width="${fr.w}" height="${fr.h}" rx="12" fill="#ffffff" fill-opacity=".72" stroke="#d3d8de" stroke-width="2"/>
  <text x="${fr.x + 4}" y="${fr.y - 16}" font-size="24" font-weight="600" fill="#6b7280" font-family="var(--font)">${esc(fr.label)}</text></g>`;
const linkSvg = (l) => `<path class="link" id="${l.id}" d="${l.d}" data-len="${l.len}" stroke-dasharray="${l.len} ${l.len}" stroke-dashoffset="${l.len}" fill="none" stroke="#1d1d1d" stroke-width="${SW - 0.4}" stroke-linecap="round"/><path id="${l.id}h" d="${l.head}" opacity="0" fill="none" stroke="#1d1d1d" stroke-width="${SW - 0.4}" stroke-linecap="round" stroke-linejoin="round"/>`;
const dot = (t, id) => `<g class="pkt" id="${id}" opacity="0"><circle r="17" fill="${tone(t)[0]}" opacity=".18"/><circle r="8" fill="${tone(t)[0]}"/></g>`;
function pill(label, t, cls, id, at) {
  const [stroke, fill] = tone(t), w = pillWidth(label);
  const pos = at ? ` transform="translate(${r1(at[0])} ${r1(at[1])})"` : "";
  return `<g class="${cls}" id="${id}" opacity="0"${pos}><g class="in"><rect x="${r1(-w / 2)}" y="-19" width="${r1(w)}" height="38" rx="19" fill="${fill}" stroke="${stroke}" stroke-width="2.5"/><text y="7" font-size="19" font-weight="600" fill="${stroke}" text-anchor="middle" font-family="var(--font)">${esc(label)}</text></g></g>`;
}

// ---- Timeline -----------------------------------------------------------------------------------
const js = [], extras = [], caps = [], audio = [];
const add = (s) => js.push(s);
const shown = new Set(), framesShown = new Set(), drawn = new Set(), tagOf = {}, stateOf = {}, labelOf = {};
let pkt = 0, tagN = 0, strikeN = 0;

// Which boxes are on the board by the end of each beat, so "all" frames everything that's there.
const shownBy = [];
{
  const s = new Set();
  for (const b of wt.beats) {
    for (const a of b.do ?? []) {
      for (const id of [].concat(a.show ?? [])) s.add(id);
      if (a.send) a.send.forEach((id) => s.add(id));
      for (const id of [].concat(a.hide ?? [])) s.delete(id);
    }
    shownBy.push(new Set(s));
  }
}
function fit(target, beat) {
  let ids = target === "all" ? [...shownBy[beat]] : [].concat(target);
  const rects = ids.map(box).filter(Boolean);
  if (target === "all") for (const fr of frames.values()) if (fr.members.some((m) => shownBy[beat].has(m))) rects.push(fr);
  if (!rects.length) return null;
  const pad = 70;
  const x0 = Math.min(...rects.map((r) => r.x)) - pad, y0 = Math.min(...rects.map((r) => r.y)) - pad - 30;
  const x1 = Math.max(...rects.map((r) => r.x + r.w)) + pad, y1 = Math.max(...rects.map((r) => r.y + r.h)) + pad;
  const s = Math.max(0.3, Math.min(1.45, 1680 / (x1 - x0), 760 / (y1 - y0)));
  return { x: r1(960 - s * (x0 + x1) / 2), y: r1(490 - s * (y0 + y1) / 2), scale: r3(s) };
}
function showFrame(id, at) {
  if (framesShown.has(id)) return;
  framesShown.add(id);
  add(`tl.fromTo("#f-${sid(id)}", { opacity: 0 }, { opacity: 1, duration: 0.6, ease: "power1.out" }, ${r3(at)});`);
}
function showNode(id, at) {
  const g = nodes.get(id);
  if (!g || shown.has(id)) return 0;
  shown.add(id);
  if (g.frame) showFrame(g.frame, at - 0.3);
  const S = `#n-${sid(id)}`;
  if (g.kind === "note" || g.kind === "text") {
    add(`tl.fromTo("${S}", { opacity: 0, scale: 0.92, y: 10 }, { opacity: 1, scale: 1, y: 0, duration: 0.6, ease: "back.out(1.6)", transformOrigin: "50% 50%" }, ${r3(at)});`);
    return 0.6;
  }
  add(`tl.set("${S}", { opacity: 1 }, ${r3(at)});`);
  add(`drawIn("${S} .draw", ${r3(at)}, 0.7);`);
  add(`tl.fromTo("${S} .fill", { opacity: 0 }, { opacity: 1, duration: 0.5, ease: "power1.out" }, ${r3(at + 0.3)});`);
  add(`tl.fromTo("${S} .st0", { opacity: 0, y: 6 }, { opacity: 1, y: 0, duration: 0.45, ease: "power2.out" }, ${r3(at + 0.4)});`);
  if (g.kind === "code") {
    add(`tl.fromTo("${S} .cl", { opacity: 0, x: -8 }, { opacity: 1, x: 0, duration: 0.3, stagger: 0.06 }, ${r3(at + 0.5)});`);
    add(`tl.to("${S} .band", { opacity: 1, duration: 0.5 }, ${r3(at + 0.9 + g.lines.length * 0.06)});`);
  }
  return 0.9;
}
function phraseTime(phrase, segs, speak) {
  const want = String(phrase).toLowerCase();
  for (const s of segs) {
    const i = s.text.toLowerCase().indexOf(want);
    if (i >= 0) return speak + s.start + (i / Math.max(1, s.text.length)) * (s.end - s.start) - 0.15;
  }
  // No timings at all (Chatterbox) means every `on` runs in order; that's expected, not worth a warning.
  if (segs.length) console.error(`warning: "${phrase}" isn't in the narration; running it in order instead`);
  return null;
}
function camera(target, at, beat, first) {
  const c = fit(target, beat);
  if (!c) return;
  add(first ? `tl.set("#world", ${JSON.stringify(c)}, 0);` : `tl.to("#world", { x: ${c.x}, y: ${c.y}, scale: ${c.scale}, duration: 1.6, ease: "power2.inOut" }, ${r3(at)});`);
}

let t = 0.4, firstCamera = true;
wt.beats.forEach((b, i) => {
  const voice = durations[i], segs = timings[i] ?? [];
  const start = t, speak = start + (b.camera ? 0.8 : 0.35);
  if (b.camera) { camera(b.camera, start, i, firstCamera); firstCamera = false; }
  let cursor = speak + 0.15;
  const highlighted = [];
  for (const a of b.do ?? []) {
    const at = (a.on ? phraseTime(a.on, segs, speak) : null) ?? cursor;
    let dur = 0;
    if (a.camera) { camera(a.camera, at, i, firstCamera); firstCamera = false; continue; }
    if (a.show) [].concat(a.show).forEach((id, k) => { if (frames.has(id)) showFrame(id, at + k * 0.2); else dur = Math.max(dur, k * 0.2 + showNode(id, at + k * 0.2)); });
    if (a.send) {
      const [from, to] = a.send, l = links.get(`${from}>${to}`);
      if (!l) { console.error(`warning: send ${from} → ${to}: no such box`); continue; }
      let t0 = at;
      if (!shown.has(from)) t0 += showNode(from, t0) * 0.7;
      const travel = 1.15;
      if (!drawn.has(l.id)) {
        drawn.add(l.id);
        add(`tl.fromTo("#${l.id}", { attr: { "stroke-dashoffset": ${l.len} } }, { attr: { "stroke-dashoffset": 0 }, duration: ${travel}, ease: "power1.inOut" }, ${r3(t0)});`);
        add(`tl.to("#${l.id}h", { opacity: 1, duration: 0.2 }, ${r3(t0 + travel - 0.15)});`);
      }
      const id = `p${pkt++}`;
      extras.push(dot(a.tone ?? "blue", id));
      add(`tl.set("#${id}", { opacity: 1 }, ${r3(t0)});`);
      add(`tl.to("#${id}", { motionPath: { path: "#${l.id}" }, duration: ${travel}, ease: "power1.inOut", immediateRender: true }, ${r3(t0)});`);
      add(`tl.to("#${id}", { opacity: 0, duration: 0.25 }, ${r3(t0 + travel)});`);
      if (a.label) {
        const lab = `b${pkt}`;
        extras.push(pill(a.label, a.tone ?? "blue", "lab", lab, placeLabel(l, a.label)));
        if (labelOf[l.id]) add(`tl.to("#${labelOf[l.id]}", { opacity: 0, duration: 0.25 }, ${r3(t0 + travel * 0.4)});`);
        labelOf[l.id] = lab;
        add(`tl.set("#${lab}", { opacity: 1 }, ${r3(t0 + travel * 0.45)});`);
        add(`tl.fromTo("#${lab} .in", { opacity: 0 }, { opacity: 1, duration: 0.35, ease: "power1.out" }, ${r3(t0 + travel * 0.45)});`);
      }
      let arrive = t0 + travel;
      if (!shown.has(to)) arrive += showNode(to, arrive - 0.1) * 0.8;
      else add(`tl.to("#n-${sid(to)}", { scale: 1.04, duration: 0.18, yoyo: true, repeat: 1, ease: "power1.inOut", transformOrigin: "50% 50%" }, ${r3(arrive - 0.05)});`);
      dur = arrive - at + 0.2;
    }
    if (a.tag && !nodes.has(a.tag)) console.error(`warning: tag ${a.tag}: no such box`);
    else if (a.tag) {
      const g = nodes.get(a.tag), id = `t${tagN++}`;
      extras.push(pill(a.text ?? "", a.tone ?? "grey", "tag", id, placeTag(g, a.text ?? "")));
      if (tagOf[a.tag]) add(`tl.to("#${tagOf[a.tag]}", { opacity: 0, duration: 0.25 }, ${r3(at)});`);
      tagOf[a.tag] = id;
      add(`tl.set("#${id}", { opacity: 1 }, ${r3(at)});`);
      add(`tl.fromTo("#${id} .in", { opacity: 0 }, { opacity: 1, duration: 0.35, ease: "power1.out" }, ${r3(at)});`);
      dur = 0.5;
    }
    if (a.untag && tagOf[a.untag]) { placed.delete(`tag:${a.untag}`); add(`tl.to("#${tagOf[a.untag]}", { opacity: 0, duration: 0.3 }, ${r3(at)});`); delete tagOf[a.untag]; dur = 0.3; }
    if (a.set && nodes.get(a.set)?.states) {
      const S = `#n-${sid(a.set)}`, k = (stateOf[a.set] ?? 0) + 1;
      stateOf[a.set] = k;
      add(`tl.to("${S} .st${k - 1}", { opacity: 0, y: -6, duration: 0.3 }, ${r3(at)});`);
      add(`tl.fromTo("${S} .st${k}", { opacity: 0, y: 6 }, { opacity: 1, y: 0, duration: 0.4 }, ${r3(at + 0.25)});`);
      dur = 0.7;
    }
    if (a.highlight) {
      for (const id of [].concat(a.highlight)) { add(`tl.to("#n-${sid(id)} .hl", { opacity: 0.85, duration: 0.4 }, ${r3(at)});`); highlighted.push(id); }
      dur = 0.4;
    }
    if (a.strike) {
      const g = box(a.strike), id = `x${strikeN++}`;
      const pts = Array.from({ length: 7 }, (_, k) => [g.x + 10 + ((g.w - 20) * k) / 6, g.y + g.h * (k % 2 ? 0.72 : 0.3)]);
      const s = sketchOpen(pts, id, 2);
      extras.push(`<path class="strike" id="${id}" d="${s.d}" data-len="${s.len}" stroke-dasharray="${s.len} ${s.len}" stroke-dashoffset="${s.len}" fill="none" stroke="#e03131" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>`);
      add(`drawIn("#${id}", ${r3(at)}, 0.6);`);
      dur = 0.6;
    }
    // Forget hidden boxes and frames, so a later show or send draws them in again.
    if (a.hide) for (const id of [].concat(a.hide)) {
      add(`tl.to("#n-${sid(id)}, #f-${sid(id)}", { opacity: 0, duration: 0.4 }, ${r3(at)});`);
      shown.delete(id); framesShown.delete(id);
    }
    if (!a.on) cursor = at + dur + 0.25;
    else cursor = Math.max(cursor, at + dur + 0.25);
  }
  const end = Math.max(speak + voice, cursor) + 0.55;
  for (const id of highlighted) add(`tl.to("#n-${sid(id)} .hl", { opacity: 0, duration: 0.4 }, ${r3(end - 0.3)});`);
  audio.push(`<audio class="clip" id="a${i}" data-start="${r3(speak)}" data-duration="${r3(voice)}" data-track-index="100" data-volume="1" src="assets/audio-${String(i).padStart(2, "0")}.wav"></audio>`);
  segs.forEach((s, k) => {
    const next = segs[k + 1]?.start ?? s.end + 0.3;
    caps.push({ text: s.text, start: r3(speak + s.start), dur: r3(Math.max(0.6, next - s.start)) });
  });
  t = end;
});
const total = r3(t + 0.6);

// The board's extent, so the SVG covers everything the camera can see.
const all = [...nodes.values(), ...frames.values()];
const bx = Math.min(...all.map((n) => n.x)) - 200, by = Math.min(...all.map((n) => n.y)) - 200;
const bw = Math.max(...all.map((n) => n.x + n.w)) + 200 - bx, bh = Math.max(...all.map((n) => n.y + n.h)) + 200 - by;

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Shantell+Sans:wght@400;600;700&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Serif:wght@400;600;700&family=IBM+Plex+Mono:wght@400;500;600&display=block" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/gsap@3.14.2/dist/gsap.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3.14.2/dist/MotionPathPlugin.min.js"></script>
<style>
:root { --font: ${STYLES[STYLE].font}; --sans: "IBM Plex Sans", system-ui, sans-serif; --mono: "IBM Plex Mono", Menlo, monospace; }
* { box-sizing: border-box; }
html, body { margin: 0; width: 1920px; height: 1080px; overflow: hidden; background: #f8f9fa; }
#root { position: relative; width: 1920px; height: 1080px; overflow: hidden; background: #f8f9fa; font-family: var(--sans); }
#world { position: absolute; left: 0; top: 0; transform-origin: 0 0; will-change: transform; }
.dots { position: absolute; left: ${bx - 3000}px; top: ${by - 3000}px; width: ${bw + 6000}px; height: ${bh + 6000}px;
  background-image: radial-gradient(circle, #cfd4da 1.6px, transparent 1.9px); background-size: 28px 28px; background-position: 14px 14px; }
#board { position: absolute; left: ${bx}px; top: ${by}px; overflow: visible; }
.node { opacity: 0; }
.chip { position: absolute; left: 32px; top: 28px; display: flex; align-items: center; gap: 12px; height: 52px; padding: 0 20px; border-radius: 14px; background: #fff;
  box-shadow: 0 0 0 1px rgba(0,0,0,.06), 0 4px 16px rgba(0,0,0,.06); font: 500 20px var(--sans); color: #1d1d1d; max-width: 1400px; z-index: 5; }
.chip b { font: 500 18px var(--mono); color: #6b7280; }
.chip span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.caption { position: absolute; left: 0; right: 0; bottom: 56px; display: flex; justify-content: center; z-index: 6; }
.caption span { max-width: 1400px; padding: 16px 30px; border-radius: 16px; background: rgba(255,255,255,.94); box-shadow: 0 0 0 1px rgba(0,0,0,.06), 0 8px 28px rgba(0,0,0,.08);
  font: 500 30px/1.4 var(--sans); color: #1d1d1d; text-align: center; }
</style>
</head>
<body>
<div id="root" data-composition-id="main" data-start="0" data-duration="${total}" data-width="1920" data-height="1080">
  <div class="clip" id="canvas" data-start="0" data-duration="${total}" data-track-index="0" style="position:absolute;inset:0">
    <div id="world">
      <div class="dots"></div>
      <svg id="board" width="${bw}" height="${bh}" viewBox="${bx} ${by} ${bw} ${bh}" xmlns="http://www.w3.org/2000/svg">
        <defs><filter id="shadow" x="-10%" y="-10%" width="120%" height="130%"><feDropShadow dx="0" dy="6" stdDeviation="8" flood-color="#000" flood-opacity=".12"/></filter></defs>
        ${[...frames.values()].map(frameSvg).join("\n")}
        ${[...links.values()].map(linkSvg).join("\n")}
        ${[...nodes.values()].map(nodeSvg).join("\n")}
        ${extras.join("\n")}
      </svg>
    </div>
  </div>
  <div class="clip chip" id="chip" data-start="0" data-duration="${total}" data-track-index="1"><b>#${esc(data.number)}</b><span>${esc(data.title)}</span></div>
${caps.map((c, k) => `  <div class="clip caption" id="c${k}" data-start="${c.start}" data-duration="${c.dur}" data-track-index="${60 + (k % 4)}"><span>${esc(c.text)}</span></div>`).join("\n")}
${audio.join("\n")}
</div>
<script>
gsap.registerPlugin(MotionPathPlugin);
window.__timelines = window.__timelines || {};
const tl = gsap.timeline({ paused: true });
gsap.set(".frame", { opacity: 0 });
// Draw a pen stroke in: its dash offset runs from its length to zero.
function drawIn(sel, at, dur) {
  document.querySelectorAll(sel).forEach((p) => tl.fromTo(p, { attr: { "stroke-dashoffset": p.dataset.len } }, { attr: { "stroke-dashoffset": 0 }, duration: dur, ease: "power1.inOut" }, at));
}
${js.join("\n")}
window.__timelines["main"] = tl;
</script>
</body>
</html>
`;
fs.writeFileSync(path.join(out, "video", "index.html"), html);
fs.writeFileSync(path.join(out, "video", "hyperframes.json"), JSON.stringify({ paths: { assets: "assets" } }, null, 2));
fs.writeFileSync(path.join(out, "video", "meta.json"), JSON.stringify({ id: "pr-explain", name: "pr-explain" }));
console.log(`video/index.html: ${wt.beats.length} beats, ${total}s`);
