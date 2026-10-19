// Theme follows the system, live. The toggle overrides it for this visit only,
// and a change of system theme hands control back to the system.
const root = document.documentElement;
const systemDark = matchMedia("(prefers-color-scheme: dark)");
document.querySelector(".theme").addEventListener("click", () => {
  const dark = root.dataset.theme ? root.dataset.theme === "ink" : systemDark.matches;
  root.dataset.theme = dark ? "paper" : "ink";
});
systemDark.addEventListener("change", () => delete root.dataset.theme);

// Copy buttons copy the command, not the prompt characters around it.
for (const block of document.querySelectorAll(".cmd")) {
  const button = block.querySelector(".copy");
  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(block.dataset.copy);
      button.textContent = "copied";
      button.dataset.copied = "";
    } catch (e) {
      button.textContent = "select & copy";
    }
    setTimeout(() => {
      button.textContent = "copy";
      delete button.dataset.copied;
    }, 1600);
  });
}

// Tabs, with arrow keys between them.
const tabs = [...document.querySelectorAll('[role="tab"]')];
function select(tab) {
  for (const t of tabs) {
    const on = t === tab;
    t.setAttribute("aria-selected", on);
    t.tabIndex = on ? 0 : -1;
    document.getElementById(t.getAttribute("aria-controls")).hidden = !on;
  }
}
tabs.forEach((tab, i) => {
  tab.addEventListener("click", () => select(tab));
  tab.addEventListener("keydown", (e) => {
    const step = { ArrowRight: 1, ArrowLeft: -1 }[e.key];
    if (!step) return;
    const next = tabs[(i + step + tabs.length) % tabs.length];
    select(next);
    next.focus();
  });
});

// The rebuild: a typed command, the package diff, then a confirm that gets answered.
const script = [
  { type: "nh darwin switch --ask" },
  { line: '<span class="t-blue">&gt;</span> Building Darwin configuration', wait: 900 },
  { line: '<span class="t-dim">  built 54 paths, fetched 23 from cache.nixos.org</span>', wait: 1100 },
  { line: '<span class="t-blue">&gt;</span> Comparing changes', wait: 500 },
  { line: '<span class="t-dim">&lt;&lt;&lt; /run/current-system</span>' },
  { line: '<span class="t-dim">&gt;&gt;&gt; /tmp/nh-darwin/result</span>', wait: 300 },
  { line: '<span class="t-bold">Added packages:</span>' },
  { line: '<span class="t-add">[A.]</span>  #1  colima        0.10.3' },
  { line: '<span class="t-add">[A.]</span>  #2  lima-full     2.2.0' },
  { line: '<span class="t-add">[A.]</span>  #3  qemu          11.1.2' },
  { line: '<span class="t-bold">Selection state changes:</span>' },
  { line: '<span class="t-upd">[C-]</span>  #1  docker        29.8.2' },
  { line: '<span class="t-dim">Closure size: 592 -&gt; 623 (+31 paths, +1.0 GiB)</span>', wait: 700 },
  { line: '<span class="t-upd">?</span> Apply the config? <span class="t-dim">[y/N]</span> ', ask: "y", wait: 1200 },
  { line: '<span class="t-blue">&gt;</span> Activating configuration', wait: 700 },
  { line: '<span class="t-dim">  Homebrew bundle… done</span>', wait: 600 },
  { line: '<span class="t-dim">  Activating home-manager configuration for munza</span>', wait: 900 },
  { line: '<span class="t-add">✓</span> Switched to the new generation', wait: 400 },
  { prompt: true },
];

const term = document.getElementById("term");
const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
const prompt = '<span class="t-dim">~/.dotfiles</span> <span class="t-add">❯</span> ';
let run = 0;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function play() {
  const id = ++run;
  const live = () => id === run;
  term.innerHTML = "";

  if (reduced) {
    term.innerHTML = script
      .map((s) => (s.type ? prompt + s.type : s.prompt ? prompt : s.line + (s.ask || "")))
      .join("\n");
    return;
  }

  for (const step of script) {
    if (!live()) return;
    if (step.type) {
      term.innerHTML = prompt;
      for (const ch of step.type) {
        if (!live()) return;
        term.insertAdjacentText("beforeend", ch);
        await sleep(45 + Math.random() * 45);
      }
      await sleep(350);
      term.insertAdjacentHTML("beforeend", "\n");
    } else if (step.prompt) {
      term.insertAdjacentHTML("beforeend", prompt + '<span class="caret"></span>');
    } else {
      term.insertAdjacentHTML("beforeend", step.line);
      if (step.ask) {
        term.insertAdjacentHTML("beforeend", '<span class="caret"></span>');
        await sleep(1300);
        if (!live()) return;
        term.querySelector(".caret").remove();
        term.insertAdjacentText("beforeend", step.ask);
      }
      term.insertAdjacentHTML("beforeend", "\n");
      await sleep(step.wait ?? 140);
    }
  }
}

document.querySelector(".replay").addEventListener("click", play);
play();
