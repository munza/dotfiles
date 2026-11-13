// build.mjs <explain.json>: writes index.html (the report) and slides/slide-NN.txt
// next to it. render.sh voices the narration and renders walkthrough.mp4 with video.mjs.
import fs from "node:fs";
import path from "node:path";
import url from "node:url";

const file = process.argv[2];
if (!file) {
  console.error("usage: node build.mjs <explain.json>");
  process.exit(1);
}
const out = path.dirname(path.resolve(file));
const data = JSON.parse(fs.readFileSync(file, "utf8"));
const here = path.dirname(url.fileURLToPath(import.meta.url));
const template = (name) => fs.readFileSync(path.join(here, "..", "template", name), "utf8");

const problems = [];
for (const key of ["repo", "number", "title", "about", "levels", "how", "walkthrough", "review"])
  if (data[key] == null) problems.push(`missing ${key}`);
for (const level of ["five", "ten", "grownup"])
  for (const part of ["what", "why"]) if (!data.levels?.[level]?.[part]) problems.push(`missing levels.${level}.${part}`);
if (!["merge", "changes", "reject"].includes(data.review?.verdict)) problems.push("review.verdict must be merge, changes or reject");
(data.review?.findings ?? []).forEach((f, i) => {
  if (!["critical", "high", "medium", "low"].includes(f.severity)) problems.push(`review.findings[${i}].severity is ${f.severity}`);
  for (const key of ["title", "impact", "explanation"]) if (!f[key]) problems.push(`review.findings[${i}] has no ${key}`);
});
(data.review?.checkFirst ?? []).forEach((c, i) => {
  if (!["critical", "high", "medium", "low"].includes(c.severity)) problems.push(`review.checkFirst[${i}].severity is ${c.severity}`);
  for (const key of ["file", "code"]) if (!c[key]) problems.push(`review.checkFirst[${i}] has no ${key}`);
});
const flow = data.how?.diagram;
if (flow) {
  const nodeIds = new Set((flow.nodes ?? []).map((n) => n.id));
  (flow.nodes ?? []).forEach((n, i) => {
    if (n.tone && !["new", "changed", "removed", "external"].includes(n.tone)) problems.push(`how.diagram.nodes[${i}].tone is ${n.tone}`);
  });
  (flow.edges ?? []).forEach((e, i) => {
    for (const end of [e.from, e.to]) if (!nodeIds.has(end)) problems.push(`how.diagram.edges[${i}] names ${end}, which isn't a node`);
  });
}
const style = data.walkthrough?.style;
if (style && !["draw", "sans", "serif", "mono"].includes(style)) problems.push(`walkthrough.style is ${style}; use draw, sans, serif or mono`);
// components.json holds the kinds, colours and sizes video.mjs draws.
const rules = JSON.parse(fs.readFileSync(path.join(here, "..", "components.json"), "utf8"));
const KINDS = [...Object.keys(rules.kinds), ...Object.keys(rules.aliases), "code", "note", "text"];
(data.walkthrough?.nodes ?? []).forEach((n, i) => {
  if (n.kind && !KINDS.includes(n.kind)) problems.push(`walkthrough.nodes[${i}].kind is ${n.kind}; use one of ${KINDS.join(", ")}`);
  if (n.tone && !rules.colors[n.tone]) problems.push(`walkthrough.nodes[${i}].tone is ${n.tone}; use one of ${Object.keys(rules.colors).join(", ")}`);
  if (n.size && !rules.sizes[n.size]) problems.push(`walkthrough.nodes[${i}].size is ${n.size}; use ${Object.keys(rules.sizes).join(", ")} or leave it out`);
});
const wtNodes = data.walkthrough?.nodes ?? [], wtFrames = data.walkthrough?.frames ?? [];
const nodeIds = new Set(wtNodes.map((n) => n.id)), frameIds = new Set(wtFrames.map((f) => f.id));
// video.mjs turns each id into a DOM id with sid(); it's injective, but two boxes still can't share an id.
const seen = new Set();
for (const id of [...wtNodes.map((n) => n.id), ...wtFrames.map((f) => f.id)]) {
  if (id == null || id === "") problems.push("walkthrough has a node or frame with no id");
  else if (seen.has(id)) problems.push(`walkthrough has two nodes or frames with id ${id}`);
  seen.add(id);
}
wtNodes.forEach((n, i) => {
  if (!Array.isArray(n.at)) problems.push(`walkthrough.nodes[${i}] (${n.id}) has no at: [x, y]`);
  if (n.frame && !frameIds.has(n.frame)) problems.push(`walkthrough.nodes[${i}] is in frame ${n.frame}, which isn't in frames`);
});
wtFrames.forEach((fr, i) => {
  if (!wtNodes.some((n) => n.frame === fr.id)) problems.push(`walkthrough.frames[${i}] (${fr.id}) has no nodes; give a node "frame": "${fr.id}" or drop the frame`);
});
if (!data.walkthrough?.beats?.length) problems.push("walkthrough has no beats");
// camera, show, hide and strike take frames too; the other actions need a box.
const ANY = ["camera", "show", "hide", "strike"], BOX = ["send", "tag", "untag", "set", "highlight"];
(data.walkthrough?.beats ?? []).forEach((b, i) => {
  if (!b.narration?.trim()) problems.push(`walkthrough.beats[${i}] has no narration`);
  for (const a of [{ camera: b.camera }, ...(b.do ?? [])]) {
    for (const key of ANY) for (const r of [a[key]].flat().filter((r) => r && r !== "all"))
      if (!nodeIds.has(r) && !frameIds.has(r)) problems.push(`walkthrough.beats[${i}] ${key} names ${r}, which isn't a node or frame`);
    for (const key of BOX) for (const r of [a[key]].flat().filter((r) => r != null))
      if (!nodeIds.has(r)) problems.push(`walkthrough.beats[${i}] ${key} names ${r}, which isn't a node${frameIds.has(r) ? " (frames only work with camera, show, hide and strike)" : ""}`);
  }
});
if (problems.length) {
  console.error(problems.join("\n"));
  process.exit(1);
}

// JSON inside <script> must not be able to close the tag, whatever the PR's text says.
const json = (value) => JSON.stringify(value).replace(/</g, "\\u003c");
const fill = (html, marker, value) => html.replace(marker, () => json(value));

fs.writeFileSync(path.join(out, "index.html"), fill(template("report.html"), "/*DATA*/null", data));

// One narration file per beat; render.sh voices them and video.mjs animates the walkthrough.
const slides = path.join(out, "slides");
fs.rmSync(slides, { recursive: true, force: true });
fs.mkdirSync(slides);
data.walkthrough.beats.forEach((beat, i) => fs.writeFileSync(path.join(slides, `slide-${String(i).padStart(2, "0")}.txt`), beat.narration.trim() + "\n"));
console.log(`${out}/index.html and ${data.walkthrough.beats.length} beats`);
