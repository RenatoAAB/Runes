/* Hand-rolled SVG chart helpers.
 * Specs follow the dataviz method: bars ≤24px with 4px rounded data-ends,
 * 2px lines, hairline solid gridlines, hover tooltips that enhance (never gate),
 * and a table-view twin for every chart (built by app.js via makeCard). */
(() => {

const SVG_NS = "http://www.w3.org/2000/svg";

function el(tag, attrs = {}, parent = null) {
  const node = document.createElementNS(SVG_NS, tag);
  for (const [k, v] of Object.entries(attrs)) node.setAttribute(k, v);
  if (parent) parent.appendChild(node);
  return node;
}

function cssVar(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}

function fmt(n) {
  if (n === null || n === undefined || Number.isNaN(n)) return "–";
  const abs = Math.abs(n);
  if (abs >= 1e9) return (n / 1e9).toFixed(1) + "B";
  if (abs >= 1e6) return (n / 1e6).toFixed(1) + "M";
  if (abs >= 1e4) return (n / 1e3).toFixed(1) + "K";
  if (abs >= 100 || Number.isInteger(n)) return Math.round(n).toLocaleString("pt-BR");
  return n.toFixed(1);
}

function pct(x) {
  return (x * 100).toFixed(x >= 0.1 || x === 0 ? 0 : 1) + "%";
}

/* --- tooltip singleton (values lead, labels follow; textContent only) --- */
const tip = {
  node: null,
  ensure() {
    if (!this.node) this.node = document.getElementById("tooltip");
    return this.node;
  },
  show(evt, rows) {
    const t = this.ensure();
    t.replaceChildren();
    for (const r of rows) {
      const line = document.createElement("div");
      line.className = "tt-row";
      if (r.color) {
        const key = document.createElement("span");
        key.className = "tt-key";
        key.style.background = r.color;
        line.appendChild(key);
      }
      const value = document.createElement("span");
      value.className = r.strong === false ? "" : "tt-value";
      value.textContent = r.value;
      line.appendChild(value);
      if (r.label) {
        const label = document.createElement("span");
        label.textContent = r.label;
        line.appendChild(label);
      }
      t.appendChild(line);
    }
    t.style.display = "block";
    this.move(evt);
  },
  move(evt) {
    const t = this.ensure();
    const pad = 14;
    let x = evt.clientX + pad, y = evt.clientY + pad;
    const r = t.getBoundingClientRect();
    if (x + r.width > innerWidth - 8) x = evt.clientX - r.width - pad;
    if (y + r.height > innerHeight - 8) y = evt.clientY - r.height - pad;
    t.style.left = x + "px";
    t.style.top = y + "px";
  },
  hide() {
    this.ensure().style.display = "none";
  },
};

function hover(node, rowsFn) {
  node.addEventListener("pointerenter", (e) => tip.show(e, rowsFn()));
  node.addEventListener("pointermove", (e) => tip.move(e));
  node.addEventListener("pointerleave", () => tip.hide());
}

function niceTicks(max, count = 4) {
  if (max <= 0) return [0, 1];
  const step = Math.pow(10, Math.floor(Math.log10(max / count)));
  const err = max / count / step;
  const mult = err >= 7.5 ? 10 : err >= 3.5 ? 5 : err >= 1.5 ? 2 : 1;
  const s = step * mult;
  const ticks = [];
  for (let v = 0; v <= max + s * 0.001; v += s) ticks.push(v);
  return ticks;
}

/* --- horizontal bar chart -------------------------------------------------
 * rows: [{label, value, hint?, img?}] — single series, slot-1 hue, value at tip */
function hbar(container, rows, opts = {}) {
  container.replaceChildren();
  if (!rows.length) return;
  const color = opts.color || cssVar("--series-1");
  const barH = 18, gap = 8, labelW = opts.labelW ?? 150, valueW = 56;
  const width = Math.max(container.clientWidth || 560, 320);
  const plotW = width - labelW - valueW - 8;
  const height = rows.length * (barH + gap) + 4;
  const max = opts.max ?? Math.max(...rows.map((r) => r.value), 1e-9);

  const svg = el("svg", { width, height, viewBox: `0 0 ${width} ${height}` }, container);
  rows.forEach((r, i) => {
    const y = i * (barH + gap) + 2;
    const w = Math.max((r.value / max) * plotW, r.value > 0 ? 2 : 0);
    const label = el("text", { x: labelW - 8, y: y + barH - 5, "text-anchor": "end" }, svg);
    label.textContent = r.label.length > 24 ? r.label.slice(0, 23) + "…" : r.label;
    // rounded data-end, square baseline: right-corner radius via path
    const rr = Math.min(4, w);
    el("path", {
      d: `M${labelW},${y} h${w - rr} a${rr},${rr} 0 0 1 ${rr},${rr} v${barH - 2 * rr} a${rr},${rr} 0 0 1 ${-rr},${rr} h${-(w - rr)} z`,
      fill: color,
    }, svg);
    const val = el("text", { x: labelW + w + 6, y: y + barH - 5, class: "val-label" }, svg);
    val.textContent = opts.format ? opts.format(r.value) : fmt(r.value);
    // hit target wider than the mark
    const hit = el("rect", { x: 0, y: y - gap / 2, width, height: barH + gap, fill: "transparent" }, svg);
    hover(hit, () => [
      { value: opts.format ? opts.format(r.value) : fmt(r.value), label: r.label },
      ...(r.hint ? [{ value: r.hint, strong: false }] : []),
    ]);
  });
}

/* --- histogram (column) ---------------------------------------------------
 * bins: [{label, count}] */
function histogram(container, bins, opts = {}) {
  container.replaceChildren();
  if (!bins.length) return;
  const color = opts.color || cssVar("--series-1");
  const width = Math.max(container.clientWidth || 560, 320);
  const plotH = 160, axisH = 34, padL = 34;
  const height = plotH + axisH;
  const max = Math.max(...bins.map((b) => b.count), 1);
  const bw = Math.min(24, (width - padL) / bins.length - 4);
  const slot = (width - padL) / bins.length;

  const svg = el("svg", { width, height, viewBox: `0 0 ${width} ${height}` }, container);
  for (const t of niceTicks(max)) {
    const y = plotH - (t / max) * (plotH - 10);
    el("line", { x1: padL, y1: y, x2: width, y2: y, class: "gridline" }, svg);
    const lab = el("text", { x: padL - 6, y: y + 3, "text-anchor": "end" }, svg);
    lab.textContent = fmt(t);
  }
  el("line", { x1: padL, y1: plotH, x2: width, y2: plotH, class: "baseline" }, svg);
  bins.forEach((b, i) => {
    const x = padL + i * slot + (slot - bw) / 2;
    const h = (b.count / max) * (plotH - 10);
    if (b.count > 0) {
      const rr = Math.min(4, bw / 2, h);
      el("path", {
        d: `M${x},${plotH} v${-(h - rr)} a${rr},${rr} 0 0 1 ${rr},${-rr} h${bw - 2 * rr} a${rr},${rr} 0 0 1 ${rr},${rr} v${h - rr} z`,
        fill: color,
      }, svg);
    }
    if (i % Math.ceil(bins.length / 8) === 0 || bins.length <= 8) {
      const lab = el("text", { x: x + bw / 2, y: plotH + 16, "text-anchor": "middle" }, svg);
      lab.textContent = b.label;
    }
    const hit = el("rect", { x: padL + i * slot, y: 0, width: slot, height: plotH + axisH, fill: "transparent" }, svg);
    hover(hit, () => [
      { value: fmt(b.count), label: b.count === 1 ? "run" : "runs" },
      { value: b.label, strong: false },
    ]);
  });
}

/* --- grouped funnel columns ------------------------------------------------
 * levels: [1..N]; series: [{name, color, values[]}] (values = % 0..1 per level) */
function funnel(container, levels, series, opts = {}) {
  container.replaceChildren();
  const width = Math.max(container.clientWidth || 700, 320);
  const plotH = 190, axisH = 30, padL = 40;
  const height = plotH + axisH;
  const slot = (width - padL) / levels.length;
  const bw = Math.min(18, Math.max(6, (slot - 6) / Math.max(series.length, 1) - 2));

  const svg = el("svg", { width, height, viewBox: `0 0 ${width} ${height}` }, container);
  for (const t of [0, 0.25, 0.5, 0.75, 1]) {
    const y = plotH - t * (plotH - 12);
    el("line", { x1: padL, y1: y, x2: width, y2: y, class: "gridline" }, svg);
    const lab = el("text", { x: padL - 6, y: y + 3, "text-anchor": "end" }, svg);
    lab.textContent = pct(t);
  }
  el("line", { x1: padL, y1: plotH, x2: width, y2: plotH, class: "baseline" }, svg);

  levels.forEach((lv, i) => {
    const groupW = series.length * (bw + 2) - 2;
    const x0 = padL + i * slot + (slot - groupW) / 2;
    series.forEach((s, j) => {
      const v = s.values[i] ?? 0;
      const h = v * (plotH - 12);
      const x = x0 + j * (bw + 2); // 2px surface gap between adjacent bars
      if (h > 0) {
        const rr = Math.min(4, bw / 2, h);
        el("path", {
          d: `M${x},${plotH} v${-(h - rr)} a${rr},${rr} 0 0 1 ${rr},${-rr} h${bw - 2 * rr} a${rr},${rr} 0 0 1 ${rr},${rr} v${h - rr} z`,
          fill: s.color,
        }, svg);
      }
    });
    const lab = el("text", { x: padL + i * slot + slot / 2, y: plotH + 16, "text-anchor": "middle" }, svg);
    lab.textContent = String(lv);
    if (opts.deadliest === lv) {
      const skull = el("text", { x: padL + i * slot + slot / 2, y: plotH + 29, "text-anchor": "middle" }, svg);
      skull.textContent = "\u{1F480}";
    }
    const hit = el("rect", { x: padL + i * slot, y: 0, width: slot, height: plotH + axisH, fill: "transparent" }, svg);
    hover(hit, () => [
      { value: "Nível " + lv, strong: false },
      ...series.map((s) => ({ value: pct(s.values[i] ?? 0), label: s.name, color: s.color })),
    ]);
  });
}

/* --- line chart with crosshair ----------------------------------------------
 * xs: numeric x positions (levels); series: [{name, color, values[], dashedNo—never}] */
function lines(container, xs, series, opts = {}) {
  container.replaceChildren();
  if (!xs.length) return;
  const width = Math.max(container.clientWidth || 700, 320);
  const plotH = 190, axisH = 30, padL = 46, padR = 12;
  const height = plotH + axisH;
  const plotW = width - padL - padR;
  const allValues = series.flatMap((s) => s.values.filter((v) => v !== null && v !== undefined));
  const maxY = opts.log ? Math.max(...allValues.map((v) => Math.log10(Math.max(v, 1)))) : Math.max(...allValues, 1);
  const yPos = (v) => {
    const val = opts.log ? Math.log10(Math.max(v, 1)) : v;
    return plotH - (val / maxY) * (plotH - 14);
  };
  const xPos = (i) => padL + (xs.length === 1 ? plotW / 2 : (i / (xs.length - 1)) * plotW);

  const svg = el("svg", { width, height, viewBox: `0 0 ${width} ${height}` }, container);
  const tickVals = opts.log
    ? Array.from({ length: Math.ceil(maxY) + 1 }, (_, i) => i)
    : niceTicks(maxY);
  for (const t of tickVals) {
    const y = plotH - (t / maxY) * (plotH - 14);
    el("line", { x1: padL, y1: y, x2: width - padR, y2: y, class: "gridline" }, svg);
    const lab = el("text", { x: padL - 6, y: y + 3, "text-anchor": "end" }, svg);
    lab.textContent = opts.log ? fmt(Math.pow(10, t)) : fmt(t);
  }
  el("line", { x1: padL, y1: plotH, x2: width - padR, y2: plotH, class: "baseline" }, svg);
  xs.forEach((x, i) => {
    if (i % Math.ceil(xs.length / 10) === 0 || xs.length <= 10) {
      const lab = el("text", { x: xPos(i), y: plotH + 16, "text-anchor": "middle" }, svg);
      lab.textContent = String(x);
    }
  });

  for (const s of series) {
    const pts = [];
    s.values.forEach((v, i) => {
      if (v !== null && v !== undefined) pts.push([xPos(i), yPos(v)]);
    });
    if (pts.length > 1) {
      el("path", {
        d: "M" + pts.map((p) => p.join(",")).join(" L"),
        fill: "none", stroke: s.color, "stroke-width": 2,
        "stroke-linejoin": "round", "stroke-linecap": "round",
      }, svg);
    }
    // end marker with 2px surface ring
    if (pts.length) {
      const last = pts[pts.length - 1];
      el("circle", { cx: last[0], cy: last[1], r: 6, fill: cssVar("--surface") }, svg);
      el("circle", { cx: last[0], cy: last[1], r: 4, fill: s.color }, svg);
    }
  }

  // crosshair snapping to nearest x, one tooltip listing every series
  const cross = el("line", { y1: 8, y2: plotH, class: "baseline", visibility: "hidden" }, svg);
  const hit = el("rect", { x: padL, y: 0, width: plotW, height: plotH + axisH, fill: "transparent" }, svg);
  hit.addEventListener("pointermove", (e) => {
    const rect = svg.getBoundingClientRect();
    const rel = ((e.clientX - rect.left - padL) / plotW) * (xs.length - 1);
    const i = Math.max(0, Math.min(xs.length - 1, Math.round(rel)));
    cross.setAttribute("x1", xPos(i));
    cross.setAttribute("x2", xPos(i));
    cross.setAttribute("visibility", "visible");
    tip.show(e, [
      { value: (opts.xLabel || "x") + " " + xs[i], strong: false },
      ...series
        .filter((s) => s.values[i] !== null && s.values[i] !== undefined)
        .map((s) => ({ value: fmt(s.values[i]), label: s.name, color: s.color })),
    ]);
  });
  hit.addEventListener("pointerleave", () => {
    cross.setAttribute("visibility", "hidden");
    tip.hide();
  });
}

/* legend builder (rect swatch for bars, line key for lines) */
function legend(container, entries, kind = "rect") {
  const box = document.createElement("div");
  box.className = "legend";
  for (const e of entries) {
    const key = document.createElement("span");
    key.className = "key";
    const swatch = document.createElement("span");
    swatch.className = kind === "line" ? "swatch linekey" : "swatch";
    swatch.style.background = e.color;
    key.appendChild(swatch);
    key.appendChild(document.createTextNode(e.name));
    box.appendChild(key);
  }
  container.appendChild(box);
}

window.RunesCharts = { hbar, histogram, funnel, lines, legend, fmt, pct };
})();

