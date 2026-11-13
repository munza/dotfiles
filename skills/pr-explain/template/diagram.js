// diagramSVG(d): boxes and arrows laid out in ranks, left to right (or top down), as an SVG
// string. Shared by the report and the video; build.mjs and video.mjs inline it.
// d = { direction?: "right" | "down", nodes: [{ id, label, note?, tone? }], edges: [{ from, to, label?, note? }] }
// Edges are steps, in order: a request travels each one in turn and lights up its target.
// label sits on the line; note is the step's caption.
// tone: "new" | "changed" | "removed" | "external"; anything else is plain.
// Every node is a <g class="dg-n" data-rank> and every edge a <g class="dg-e" data-rank> holding
// its line (.dg-line, with data-len for drawing it in) and arrowhead (.dg-head), with data-k
// (step order), data-from, data-to and data-note, so the report's player can send a request
// along each step. Labels (<g class="dg-lab" data-k>) are drawn last, above every box and line:
// the gap between ranks widens to fit the longest label, and a label that would cover another
// label or a box moves across the line until it's clear.
function diagramSVG(d, opt = {}) {
  const W = opt.nodeW ?? 230, H = opt.nodeH ?? 74, F = opt.font ?? 17, P = 24, A = 9;
  let GX = opt.gapX ?? 96, GY = opt.gapY ?? 30;
  const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  const down = d.direction === "down";
  const nodes = (d.nodes ?? []).filter((n) => n && n.id != null);
  const byId = Object.fromEntries(nodes.map((n) => [n.id, n]));
  const edges = (d.edges ?? []).filter((e) => byId[e.from] && byId[e.to] && e.from !== e.to);
  // Rank = longest path from a source. Bounded passes, so a cycle can't loop forever.
  const rank = Object.fromEntries(nodes.map((n) => [n.id, 0]));
  for (let i = 0; i < nodes.length; i++)
    for (const e of edges) if (rank[e.to] < rank[e.from] + 1 && rank[e.from] + 1 < nodes.length) rank[e.to] = rank[e.from] + 1;
  const cols = [];
  for (const n of nodes) (cols[rank[n.id]] ??= []).push(n);
  const ranks = cols.filter(Boolean);
  ranks.forEach((col, r) => col.forEach((n) => { rank[n.id] = r; }));
  const most = Math.max(1, ...ranks.map((c) => c.length));
  // Labels are monospace at 0.72 of the font: about 0.6 of that per character, plus padding.
  const labelW = (t) => String(t).length * F * 0.72 * 0.62 + 18, LH = F * 1.5;
  const longest = Math.max(0, ...edges.filter((e) => e.label).map((e) => labelW(e.label)));
  if (down) GY = Math.max(GY, (LH + 28) / 1.6);
  else GX = Math.max(GX, longest + A + 28);
  const pos = {};
  ranks.forEach((col, c) => col.forEach((n, r) => {
    const along = c * (down ? H + GY * 1.6 : W + GX);
    const across = (r + (most - col.length) / 2) * ((down ? W : H) + (down ? GX / 2 : GY));
    pos[n.id] = down ? { x: P + across, y: P + along } : { x: P + along, y: P + across };
  }));
  const width = P * 2 + (down ? most * W + (most - 1) * (GX / 2) : ranks.length * W + (ranks.length - 1) * GX);
  const height = P * 2 + (down ? ranks.length * H + (ranks.length - 1) * GY * 1.6 : most * H + (most - 1) * GY);
  const wrap = (text, size, lines) => {
    const max = Math.max(6, Math.floor((W - 24) / (size * 0.56)));
    const out = [];
    for (const word of String(text ?? "").split(/\s+/).filter(Boolean)) {
      const last = out[out.length - 1];
      if (last != null && (last + " " + word).length <= max) out[out.length - 1] = last + " " + word;
      else out.push(word);
    }
    if (out.length > lines) { out.length = lines; out[lines - 1] = out[lines - 1].replace(/.{0,1}$/, "…"); }
    return out;
  };
  // Length of a cubic Bézier by sampling, so a line can be drawn in with stroke-dashoffset.
  const bezierLength = (p) => {
    let len = 0, [px, py] = [p[0], p[1]];
    for (let i = 1; i <= 24; i++) {
      const t = i / 24, u = 1 - t;
      const x = u * u * u * p[0] + 3 * u * u * t * p[2] + 3 * u * t * t * p[4] + t * t * t * p[6];
      const y = u * u * u * p[1] + 3 * u * u * t * p[3] + 3 * u * t * t * p[5] + t * t * t * p[7];
      len += Math.hypot(x - px, y - py); [px, py] = [x, y];
    }
    return Math.ceil(len);
  };
  let svg = `<svg class="dg" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="${esc(d.title ?? "Diagram")}">`;
  // Boxes first, so a label never sits on one; then each placed label.
  const taken = nodes.map((n) => ({ x: pos[n.id].x, y: pos[n.id].y, w: W, h: H }));
  let labels = "";
  edges.forEach((e, k) => {
    const a = pos[e.from], b = pos[e.to];
    const [x1, y1, x2, y2] = down ? [a.x + W / 2, a.y + H, b.x + W / 2, b.y - A] : [a.x + W, a.y + H / 2, b.x - A, b.y + H / 2];
    const c = down ? [x1, y1, x1, (y1 + y2) / 2, x2, (y1 + y2) / 2, x2, y2] : [x1, y1, (x1 + x2) / 2, y1, (x1 + x2) / 2, y2, x2, y2];
    const len = bezierLength(c);
    const head = down ? `M${x2 - A * 0.7} ${y2}L${x2 + A * 0.7} ${y2}L${x2} ${y2 + A}Z` : `M${x2} ${y2 - A * 0.7}L${x2} ${y2 + A * 0.7}L${x2 + A} ${y2}Z`;
    svg += `<g class="dg-e" data-rank="${rank[e.to]}" data-k="${k}" data-from="${esc(e.from)}" data-to="${esc(e.to)}" data-note="${esc(e.note ?? e.label ?? "")}"><path class="dg-line" d="M${c[0]} ${c[1]}C${c[2]} ${c[3]} ${c[4]} ${c[5]} ${c[6]} ${c[7]}" data-len="${len}" stroke-dasharray="${len}" stroke-dashoffset="0"/><path class="dg-head" d="${head}"/>`;
    if (e.label) {
      const t = String(e.label), w = labelW(t);
      let mx = (x1 + x2) / 2, my = (y1 + y2) / 2;
      // Move across the line (up/down, or left/right when it runs down) until nothing is covered.
      const hits = (x, y) => taken.some((r) => x - w / 2 < r.x + r.w + 4 && x + w / 2 > r.x - 4 && y - LH / 2 < r.y + r.h + 4 && y + LH / 2 > r.y - 4);
      const stepBy = down ? w + 8 : LH + 6;
      for (let i = 1; i < 12 && hits(mx, my); i++) {
        const off = Math.ceil(i / 2) * stepBy * (i % 2 ? -1 : 1);
        const [tx, ty] = down ? [(x1 + x2) / 2 + off, my] : [mx, (y1 + y2) / 2 + off];
        if (!hits(tx, ty)) { mx = tx; my = ty; break; }
      }
      taken.push({ x: mx - w / 2, y: my - LH / 2, w, h: LH });
      labels += `<g class="dg-lab" data-k="${k}"><rect class="dg-tag" x="${mx - w / 2}" y="${my - LH / 2}" width="${w}" height="${LH}" rx="${F * 0.4}"/><text class="dg-tagt" x="${mx}" y="${my + F * 0.3}" font-size="${F * 0.72}" text-anchor="middle">${esc(t)}</text></g>`;
    }
    svg += `</g>`;
  });
  for (const n of nodes) {
    const { x, y } = pos[n.id];
    const label = wrap(n.label, F, n.note ? 1 : 2), note = n.note ? wrap(n.note, F * 0.78, 2) : [];
    const lines = [...label.map((t) => ({ t, s: F, c: "dg-label" })), ...note.map((t) => ({ t, s: F * 0.78, c: "dg-note" }))];
    const total = lines.reduce((h, l) => h + l.s * 1.3, 0);
    let ty = y + H / 2 - total / 2;
    svg += `<g class="dg-n ${esc(n.tone ?? "")}" data-id="${esc(n.id)}" data-rank="${rank[n.id]}" style="transform-origin:${x + W / 2}px ${y + H / 2}px"><rect class="dg-node ${esc(n.tone ?? "")}" x="${x}" y="${y}" width="${W}" height="${H}" rx="12"/>`;
    for (const l of lines) { ty += l.s * 1.3; svg += `<text class="${l.c}" x="${x + W / 2}" y="${ty - l.s * 0.28}" font-size="${l.s}" text-anchor="middle">${esc(l.t)}</text>`; }
    svg += `</g>`;
  }
  return svg + labels + "</svg>";
}
if (typeof module !== "undefined") module.exports = { diagramSVG };
