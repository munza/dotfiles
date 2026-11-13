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
const TONES = ["blue", "violet", "green", "red", "yellow", "grey", "black"];
(data.walkthrough?.nodes ?? []).forEach((n, i) => {
  if (n.tone && !TONES.includes(n.tone)) problems.push(`walkthrough.nodes[${i}].tone is ${n.tone}`);
});
const ids = new Set([...(data.walkthrough?.nodes ?? []).map((n) => n.id), ...(data.walkthrough?.frames ?? []).map((f) => f.id)]);
(data.walkthrough?.nodes ?? []).forEach((n, i) => {
  if (!Array.isArray(n.at)) problems.push(`walkthrough.nodes[${i}] (${n.id}) has no at: [x, y]`);
  if (n.frame && !ids.has(n.frame)) problems.push(`walkthrough.nodes[${i}] is in frame ${n.frame}, which isn't in frames`);
});
if (!data.walkthrough?.beats?.length) problems.push("walkthrough has no beats");
(data.walkthrough?.beats ?? []).forEach((b, i) => {
  if (!b.narration?.trim()) problems.push(`walkthrough.beats[${i}] has no narration`);
  const refs = [b.camera, ...(b.do ?? []).flatMap((a) => [a.camera, a.show, a.send, a.tag, a.untag, a.set, a.highlight, a.strike, a.hide])].flat().filter((r) => r && r !== "all");
  for (const r of refs) if (!ids.has(r)) problems.push(`walkthrough.beats[${i}] names ${r}, which isn't a node or frame`);
});
if (problems.length) {
  console.error(problems.join("\n"));
  process.exit(1);
}

// JSON inside <script> must not be able to close the tag, whatever the PR's text says.
const json = (value) => JSON.stringify(value).replace(/</g, "\\u003c");
const diagram = template("diagram.js");
const fill = (html, marker, value) => html.replace("/*DIAGRAM_JS*/", () => diagram).replace(marker, () => json(value));

fs.writeFileSync(path.join(out, "index.html"), fill(template("report.html"), "/*DATA*/null", data));

// One narration file per beat; render.sh voices them and video.mjs animates the walkthrough.
const slides = path.join(out, "slides");
fs.rmSync(slides, { recursive: true, force: true });
fs.mkdirSync(slides);
data.walkthrough.beats.forEach((beat, i) => fs.writeFileSync(path.join(slides, `slide-${String(i).padStart(2, "0")}.txt`), beat.narration.trim() + "\n"));
console.log(`${out}/index.html and ${data.walkthrough.beats.length} beats`);
