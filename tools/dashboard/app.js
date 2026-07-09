/* Runes balancing dashboard — data layer + views.
 * Data comes from Supabase REST (anon/publishable key, stored only in localStorage),
 * a snapshot JSON file, or the built-in demo generator. All aggregation is client-side. */

const { hbar, histogram, funnel, lines, legend, fmt, pct } = window.RunesCharts;

const LS = { url: "runes_dash_url", key: "runes_dash_key", cache: "runes_dash_cache" };
const MANIFEST = window.RUNES_MANIFEST || {};
const TYPE_LABEL = { rune: "Runa", relic: "Relíquia", slot_piece: "Peça", slot_modifier: "Modificador" };
const TYPE_GLYPH = { rune: "◈", relic: "♦", slot_piece: "▦", slot_modifier: "✦" };
const RARITY_VAR = {
  COMMON: "--rar-common", UNCOMMON: "--rar-uncommon", RARE: "--rar-rare",
  EPIC: "--rar-epic", LEGENDARY: "--rar-legendary",
};
// The target curve is NOT hardcoded here — the game's params are @export-overridable
// per scene/version, so a copied constant drifts (it did: accel 0.05 vs real 0.01).
// Source of truth order: (1) target observed per round in the data, (2) the curve
// params the run carries in summary.curve, (3) these legacy defaults as last resort.
const CURVE_FALLBACK = { base: 100, growth_initial: 1.5, growth_acceleration: 0.05 };
// Target(n) = base × (growth_initial + growth_acceleration·(n-1))^(n-1), n = level.
const curveTarget = (lv, c = CURVE_FALLBACK) =>
  Math.floor(c.base * Math.pow(c.growth_initial + c.growth_acceleration * (lv - 1), lv - 1));
// Pick the curve params from the data (most recent run that carries them wins, so
// the newest balancing shows), falling back to the legacy constants for old runs.
function resolveCurve(runs) {
  let best = null, bestAt = "";
  for (const r of runs) {
    const c = r.summary?.curve;
    if (!c || typeof c.base !== "number") continue;
    const at = r.ended_at || r.created_at || "";
    if (best === null || at >= bestAt) { best = c; bestAt = at; }
  }
  return best || CURVE_FALLBACK;
}

const state = {
  runs: [],
  items: [],
  tab: "items",
  sortBy: "pickRate",
  itemType: "all",
  filters: { versions: new Set(), outcome: "all", days: 0, threshold: 8, minLevel: 0, maxLevel: 0 },
};

/* ---------------- manifest helpers ---------------- */

function itemInfo(key) {
  let info = MANIFEST[key];
  if (!info) {
    const [type, id] = splitKey(key);
    // runtime-generated variants (e.g. "anomalous_<id>") fall back to their base item
    if (id.startsWith("anomalous_")) {
      const base = MANIFEST[type + ":" + id.slice("anomalous_".length)];
      if (base) info = { ...base, name: "Anômalo " + base.name };
    }
  }
  return info || null;
}

function splitKey(key) {
  const i = key.indexOf(":");
  return [key.slice(0, i), key.slice(i + 1)];
}

function spriteNode(key, size = "") {
  const info = itemInfo(key);
  const [type] = splitKey(key);
  if (info && info.sprite) {
    const img = document.createElement("img");
    img.className = "sprite" + size;
    img.src = "assets/" + info.sprite;
    img.alt = info.name || key;
    return img;
  }
  const ph = document.createElement("div");
  ph.className = "sprite placeholder" + size;
  ph.textContent = TYPE_GLYPH[type] || "?";
  return ph;
}

/* One panel's 5x5 grid as a snapshot (row-major, index = y*5 + x).
   `type` is the item type each cell id maps to (rune / slot_modifier). */
function gridNode(cells, type) {
  const g = document.createElement("div");
  g.className = "grid-snapshot";
  for (let i = 0; i < 25; i++) {
    const cell = document.createElement("div");
    cell.className = "gcell";
    const id = cells && cells[i];
    if (id) {
      const key = type + ":" + id;
      const s = spriteNode(key);
      s.title = displayName(key);
      cell.appendChild(s);
      cell.classList.add("filled");
    }
    g.appendChild(cell);
  }
  return g;
}

/* A labelled panel snapshot: the 5x5 grid with a small caption above. */
function labelledGrid(cells, type, label) {
  const wrap = document.createElement("div");
  wrap.className = "grid-labelled";
  const cap = document.createElement("div");
  cap.className = "grid-cap";
  cap.textContent = label;
  wrap.append(cap, gridNode(cells, type));
  return wrap;
}

/* Final loadout: the rune grid and (beside it) the slot-modifier grid, plus a
   row of the off-grid items (relics / pieces). Falls back to a flat row for old
   runs that predate final_grid. */
function loadoutSnapshot(r) {
  const wrap = document.createElement("div");
  wrap.className = "snapshot";
  const grids = r.summary?.final_grid;
  const modGrids = r.summary?.final_modifier_grid;
  if (grids && grids.length) {
    const grow = document.createElement("div");
    grow.className = "grid-row";
    grids.forEach((cells, i) => {
      grow.appendChild(labelledGrid(cells, "rune", "Runas"));
      const mods = modGrids && modGrids[i];
      if (mods && mods.some((c) => c)) grow.appendChild(labelledGrid(mods, "slot_modifier", "Modificadores"));
    });
    wrap.appendChild(grow);
    // relics and pieces are not positional → show them in a row
    const extras = (r.summary?.final_loadout || [])
      .filter((k) => k.startsWith("relic:") || k.startsWith("slot_piece:"));
    if (extras.length) {
      const strip = document.createElement("div");
      strip.className = "extras";
      for (const key of extras.slice(0, 12)) {
        const s = spriteNode(key);
        s.title = displayName(key);
        strip.appendChild(s);
      }
      wrap.appendChild(strip);
    }
  } else {
    const flat = document.createElement("div");
    flat.className = "loadout";
    for (const key of (r.summary?.final_loadout || []).slice(0, 14)) {
      const s = spriteNode(key);
      s.title = displayName(key);
      flat.appendChild(s);
    }
    wrap.appendChild(flat);
  }
  return wrap;
}

function displayName(key) {
  const info = itemInfo(key);
  if (info && info.name) return info.name;
  return splitKey(key)[1];
}

/* ---------------- data access ---------------- */

async function fetchAll(table, orderCol) {
  const url = localStorage.getItem(LS.url) || "";
  const key = localStorage.getItem(LS.key) || "";
  const page = 1000;
  let from = 0, out = [];
  for (;;) {
    // deterministic order (primary key) so Range pagination never skips/duplicates
    const res = await fetch(`${url.replace(/\/$/, "")}/rest/v1/${table}?select=*&order=${orderCol}`, {
      headers: {
        apikey: key,
        Authorization: "Bearer " + key,
        Range: `${from}-${from + page - 1}`,
        Prefer: "count=exact",
      },
    });
    if (!res.ok) throw new Error(`${table}: HTTP ${res.status} ${await res.text()}`);
    const chunk = await res.json();
    out = out.concat(chunk);
    if (chunk.length < page) return out;
    from += page;
  }
}

async function refresh() {
  const status = document.getElementById("status");
  try {
    status.textContent = "carregando…";
    document.getElementById("content").style.opacity = 0.5;
    const [runs, items] = await Promise.all([fetchAll("runs", "run_id"), fetchAll("run_items", "id")]);
    state.runs = runs;
    state.items = items;
    try {
      localStorage.setItem(LS.cache, JSON.stringify({ runs, items, at: Date.now() }));
    } catch (_) { /* cache too big for localStorage: skip silently */ }
    initFilters();
    render();
  } catch (err) {
    status.textContent = "erro: " + err.message;
  } finally {
    document.getElementById("content").style.opacity = 1;
  }
}

function loadCache() {
  try {
    const cached = JSON.parse(localStorage.getItem(LS.cache) || "null");
    if (cached) {
      state.runs = cached.runs;
      state.items = cached.items;
      return new Date(cached.at);
    }
  } catch (_) {}
  return null;
}

function downloadSnapshot() {
  const blob = new Blob([JSON.stringify({ runs: state.runs, items: state.items, at: Date.now() })],
    { type: "application/json" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = "runes_stats_snapshot.json";
  a.click();
  URL.revokeObjectURL(a.href);
}

function loadSnapshot(file) {
  const reader = new FileReader();
  reader.onload = () => {
    try {
      const data = JSON.parse(reader.result);
      state.runs = data.runs || [];
      state.items = data.items || [];
      initFilters();
      render();
      document.getElementById("status").textContent =
        `snapshot: ${state.runs.length} runs`;
    } catch (err) {
      alert("Snapshot inválido: " + err.message);
    }
  };
  reader.readAsText(file);
}

/* ---------------- filters ---------------- */

function initFilters() {
  const box = document.getElementById("version-chips");
  box.replaceChildren();
  const versions = [...new Set(state.runs.map((r) => r.client_version))].sort().reverse();
  if (state.filters.versions.size === 0) versions.forEach((v) => state.filters.versions.add(v));
  for (const v of versions) {
    const chip = document.createElement("span");
    chip.className = "chip" + (state.filters.versions.has(v) ? " on" : "");
    const check = document.createElement("span");
    check.className = "check";
    check.textContent = "✓";
    chip.appendChild(check);
    chip.appendChild(document.createTextNode(v));
    chip.onclick = () => {
      state.filters.versions.has(v) ? state.filters.versions.delete(v) : state.filters.versions.add(v);
      chip.classList.toggle("on");
      render();
    };
    box.appendChild(chip);
  }
}

function filteredRuns() {
  const f = state.filters;
  const cutoff = f.days > 0 ? Date.now() - f.days * 86400e3 : 0;
  return state.runs.filter((r) =>
    f.versions.has(r.client_version) &&
    (f.outcome === "all" || r.outcome === f.outcome) &&
    (!f.minLevel || r.final_level >= f.minLevel) &&
    (!f.maxLevel || r.final_level <= f.maxLevel) &&
    (!cutoff || new Date(r.created_at).getTime() >= cutoff));
}

function filteredItems(runs) {
  const ids = new Set(runs.map((r) => r.run_id));
  return state.items.filter((it) => ids.has(it.run_id));
}

/* ---------------- aggregation ---------------- */

function aggregateItems(runs, items) {
  const deepIds = new Set(runs.filter((r) => r.final_level >= state.filters.threshold).map((r) => r.run_id));
  const byKey = new Map();
  for (const it of items) {
    const key = it.item_type + ":" + it.item_id;
    let agg = byKey.get(key);
    if (!agg) {
      agg = { key, type: it.item_type, offered: 0, bought: 0, acquired: 0, sold: 0,
        upgradedInto: 0, activations: 0, score: 0, loadouts: 0, runsWith: 0, deepWith: 0,
        byAcqLevel: new Map() };
      byKey.set(key, agg);
    }
    agg.offered += it.times_offered;
    agg.bought += it.times_bought;
    agg.acquired += it.times_acquired;
    agg.sold += it.times_sold;
    agg.upgradedInto += it.times_upgraded_into;
    agg.activations += it.activations;
    agg.score += Number(it.score_contribution);
    if (it.in_final_loadout) agg.loadouts++;
    // temporal progression: value of this item grouped by the level it was taken at
    const lvl = it.acquired_at_level;
    if (lvl != null && lvl >= 1 && (it.times_bought > 0 || it.times_acquired > 0)) {
      const b = agg.byAcqLevel.get(lvl) || { n: 0, score: 0 };
      b.n++;
      b.score += Number(it.score_contribution);
      agg.byAcqLevel.set(lvl, b);
    }
    const has = it.times_acquired > 0 || it.in_final_loadout;
    if (has) {
      agg.runsWith++;
      if (deepIds.has(it.run_id)) agg.deepWith++;
    }
  }
  const total = Math.max(runs.length, 1);
  const baseline = deepIds.size / total;
  for (const agg of byKey.values()) {
    agg.pickRate = agg.runsWith / total;
    agg.conversion = agg.offered > 0 ? agg.bought / agg.offered : null;
    agg.actPerRun = agg.runsWith > 0 ? agg.activations / agg.runsWith : 0;
    agg.scorePerRun = agg.runsWith > 0 ? agg.score / agg.runsWith : 0;
    agg.deepRate = agg.runsWith > 0 ? agg.deepWith / agg.runsWith : null;
    agg.lift = agg.deepRate !== null ? agg.deepRate - baseline : null;
  }
  return { list: [...byKey.values()], baseline };
}

/* ---------------- shared UI ---------------- */

function makeCard(parent, title, sub, renderChart, tableSpec) {
  const card = document.createElement("div");
  card.className = "card";
  const head = document.createElement("div");
  head.className = "card-head";
  const h3 = document.createElement("h3");
  h3.textContent = title;
  head.appendChild(h3);
  const body = document.createElement("div");
  body.className = "chart-wrap";
  let showTable = false;
  if (tableSpec) {
    const toggle = document.createElement("button");
    toggle.className = "toggle";
    toggle.textContent = "tabela";
    toggle.onclick = () => {
      showTable = !showTable;
      toggle.textContent = showTable ? "gráfico" : "tabela";
      body.replaceChildren();
      if (showTable) body.appendChild(buildTable(tableSpec.cols, tableSpec.rows));
      else renderChart(body);
    };
    head.appendChild(toggle);
  }
  card.appendChild(head);
  if (sub) {
    const subEl = document.createElement("div");
    subEl.className = "sub";
    subEl.textContent = sub;
    card.appendChild(subEl);
  }
  card.appendChild(body);
  parent.appendChild(card);
  renderChart(body);
  return card;
}

function buildTable(cols, rows) {
  const table = document.createElement("table");
  const thead = document.createElement("thead");
  const trh = document.createElement("tr");
  for (const c of cols) {
    const th = document.createElement("th");
    th.textContent = c.label;
    if (c.num) th.className = "num";
    trh.appendChild(th);
  }
  thead.appendChild(trh);
  table.appendChild(thead);
  const tbody = document.createElement("tbody");
  for (const r of rows) {
    const tr = document.createElement("tr");
    r.forEach((cell, i) => {
      const td = document.createElement("td");
      if (cell instanceof Node) td.appendChild(cell);
      else td.textContent = cell;
      if (cols[i].num) td.className = "num";
      tr.appendChild(td);
    });
    tbody.appendChild(tr);
  }
  table.appendChild(tbody);
  return table;
}

function statTile(parent, label, value) {
  const tile = document.createElement("div");
  tile.className = "stat-tile";
  const l = document.createElement("div");
  l.className = "label";
  l.textContent = label;
  const v = document.createElement("div");
  v.className = "value";
  v.textContent = value;
  tile.append(l, v);
  parent.appendChild(tile);
}

/* ---------------- tab: Itens ---------------- */

const SORTS = {
  pickRate: { label: "mais escolhidas", value: (a) => a.pickRate },
  scorePerRun: { label: "maior pontuação/run", value: (a) => a.scorePerRun },
  lift: { label: "maior taxa de run profunda", value: (a) => a.lift ?? -1 },
  activations: { label: "mais ativadas", value: (a) => a.activations },
  ignored: { label: "mais ignoradas (oferta sem compra)", value: (a) => a.offered - a.bought },
};

function renderItems(main, runs, items) {
  const { list, baseline } = aggregateItems(runs, items);

  // podium: most picked / best performing / most ignored
  const minRuns = Math.max(2, Math.floor(runs.length * 0.05));
  const podium = document.createElement("div");
  podium.className = "podium";
  const podiumDefs = [
    ["\u{1F3C6}", "Mais escolhida", [...list].sort((a, b) => b.pickRate - a.pickRate)[0],
      (a) => pct(a.pickRate) + " das runs"],
    ["\u{1F525}", "Melhor desempenho", [...list].filter((a) => a.runsWith >= minRuns)
      .sort((a, b) => b.scorePerRun - a.scorePerRun)[0],
      (a) => fmt(a.scorePerRun) + " pts/run"],
    ["\u{1F977}", "Mais ignorada", [...list].filter((a) => a.offered >= minRuns)
      .sort((a, b) => (a.conversion ?? 1) - (b.conversion ?? 1))[0],
      (a) => pct(a.conversion ?? 0) + " de conversão em " + a.offered + " ofertas"],
  ];
  for (const [medal, label, agg, statFn] of podiumDefs) {
    if (!agg) continue;
    const pod = document.createElement("div");
    pod.className = "pod";
    const m = document.createElement("div");
    m.className = "medal";
    m.textContent = medal;
    const sprite = spriteNode(agg.key);
    const txt = document.createElement("div");
    const l = document.createElement("div");
    l.className = "pod-label";
    l.textContent = label;
    const n = document.createElement("div");
    n.className = "pod-name";
    n.textContent = displayName(agg.key);
    const s = document.createElement("div");
    s.className = "pod-stat";
    s.textContent = statFn(agg);
    txt.append(l, n, s);
    pod.append(m, sprite, txt);
    pod.style.cursor = "pointer";
    pod.onclick = () => showDetail(agg, baseline);
    podium.appendChild(pod);
  }
  main.appendChild(podium);

  // sort/filter row
  const sortRow = document.createElement("div");
  sortRow.className = "sort-row";
  sortRow.appendChild(document.createTextNode("Ordenar:"));
  const sortSel = document.createElement("select");
  for (const [k, s] of Object.entries(SORTS)) {
    const opt = document.createElement("option");
    opt.value = k;
    opt.textContent = s.label;
    if (k === state.sortBy) opt.selected = true;
    sortSel.appendChild(opt);
  }
  sortSel.onchange = () => { state.sortBy = sortSel.value; render(); };
  sortRow.appendChild(sortSel);
  sortRow.appendChild(document.createTextNode("Tipo:"));
  const typeSel = document.createElement("select");
  for (const [v, lab] of [["all", "todos"], ["rune", "runas"], ["relic", "relíquias"],
    ["slot_piece", "peças"], ["slot_modifier", "modificadores"]]) {
    const opt = document.createElement("option");
    opt.value = v;
    opt.textContent = lab;
    if (v === state.itemType) opt.selected = true;
    typeSel.appendChild(opt);
  }
  typeSel.onchange = () => { state.itemType = typeSel.value; render(); };
  sortRow.appendChild(typeSel);
  const note = document.createElement("span");
  note.textContent = `run profunda = nível ≥ ${state.filters.threshold} · baseline ${pct(baseline)}`;
  sortRow.appendChild(note);
  main.appendChild(sortRow);

  // card grid
  const sorted = list
    .filter((a) => state.itemType === "all" || a.type === state.itemType)
    .sort((a, b) => SORTS[state.sortBy].value(b) - SORTS[state.sortBy].value(a));
  const grid = document.createElement("div");
  grid.className = "item-grid";
  for (const agg of sorted) {
    const info = itemInfo(agg.key);
    const card = document.createElement("div");
    card.className = "item-card";
    if (info && RARITY_VAR[info.rarity]) card.style.setProperty("--rarity", `var(${RARITY_VAR[info.rarity]})`);
    card.appendChild(spriteNode(agg.key));
    const txt = document.createElement("div");
    const name = document.createElement("div");
    name.className = "name";
    name.textContent = displayName(agg.key);
    const meta = document.createElement("div");
    meta.className = "meta";
    meta.textContent = TYPE_LABEL[agg.type] + (info ? " · " + (info.rarity || "").toLowerCase() : "");
    const stats = document.createElement("div");
    stats.className = "stats";
    stats.textContent = `${pct(agg.pickRate)} das runs · ${fmt(agg.scorePerRun)} pts/run`;
    const lift = document.createElement("div");
    lift.className = "stats";
    if (agg.lift !== null && agg.runsWith >= minRuns) {
      const span = document.createElement("span");
      span.className = agg.lift >= 0 ? "lift-up" : "lift-down";
      span.textContent = (agg.lift >= 0 ? "↑ " : "↓ ") +
        pct(Math.abs(agg.lift)) + " vs baseline";
      lift.appendChild(span);
    } else {
      lift.textContent = agg.runsWith > 0 ? `${agg.runsWith} run(s)` : "nunca adquirida";
      lift.style.color = "var(--muted)";
    }
    txt.append(name, meta, stats, lift);
    card.appendChild(txt);
    card.onclick = () => showDetail(agg, baseline);
    grid.appendChild(card);
  }
  main.appendChild(grid);
}

function showDetail(agg, baseline) {
  const dialog = document.getElementById("detail");
  dialog.replaceChildren();
  const info = itemInfo(agg.key);
  const head = document.createElement("div");
  head.className = "detail-head";
  head.appendChild(spriteNode(agg.key));
  const title = document.createElement("div");
  const h = document.createElement("h3");
  h.textContent = displayName(agg.key);
  h.style.margin = "0";
  const meta = document.createElement("div");
  meta.className = "meta";
  meta.style.color = "var(--muted)";
  meta.textContent = TYPE_LABEL[agg.type] + (info ? " · " + (info.rarity || "").toLowerCase() : "") +
    (info && info.elements ? " · " + info.elements.join(", ").toLowerCase() : "");
  title.append(h, meta);
  head.appendChild(title);
  dialog.appendChild(head);
  if (info && info.description) {
    const desc = document.createElement("div");
    desc.className = "detail-desc";
    desc.textContent = info.description;
    dialog.appendChild(desc);
  }
  const rows = [
    ["Ofertada na loja", fmt(agg.offered)],
    ["Comprada", fmt(agg.bought) + (agg.conversion !== null ? ` (${pct(agg.conversion)} das ofertas)` : "")],
    ["Adquirida (inclui grátis/recompensa)", fmt(agg.acquired)],
    ["Vendida", fmt(agg.sold)],
    ["Recebida via upgrade", fmt(agg.upgradedInto)],
    ["Ativações", fmt(agg.activations)],
    ["Pontos gerados (total)", fmt(agg.score)],
    ["Pontos por run", fmt(agg.scorePerRun)],
    ["Presente no loadout final", fmt(agg.loadouts) + " run(s)"],
    ["Runs com o item", fmt(agg.runsWith)],
    ["Taxa de run profunda", agg.deepRate !== null ?
      `${pct(agg.deepRate)} (baseline ${pct(baseline)})` : "–"],
  ];
  const table = buildTable(
    [{ label: "" }, { label: "", num: true }],
    rows);
  table.className = "detail-stats";
  dialog.appendChild(table);

  // temporal progression: does taking this item earlier pay off more?
  const levels = [...agg.byAcqLevel.keys()].sort((a, b) => a - b);
  if (levels.length >= 2) {
    const h4 = document.createElement("h4");
    h4.textContent = "Valor por nível de aquisição";
    h4.style.margin = "16px 0 2px";
    dialog.appendChild(h4);
    const sub = document.createElement("div");
    sub.className = "meta";
    sub.style.cssText = "color:var(--muted);margin-bottom:8px";
    sub.textContent = "pontos médios por run conforme o nível em que o item foi adquirido";
    dialog.appendChild(sub);
    const acqRows = levels.map((l) => {
      const b = agg.byAcqLevel.get(l);
      return { label: "Nível " + l, value: b.score / b.n, hint: `n=${b.n}` };
    });
    const box = document.createElement("div");
    dialog.appendChild(box);
    hbar(box, acqRows);
  } else if (levels.length === 1) {
    const only = document.createElement("div");
    only.className = "meta";
    only.style.cssText = "color:var(--muted);margin-top:12px";
    only.textContent = "Adquirida sempre por volta do nível " + levels[0] + ".";
    dialog.appendChild(only);
  }

  const close = document.createElement("button");
  close.textContent = "Fechar";
  close.style.marginTop = "12px";
  close.onclick = () => dialog.close();
  dialog.appendChild(close);
  dialog.showModal();
}

/* ---------------- tab: Pontuações ---------------- */

function renderScores(main, runs) {
  const kpi = document.createElement("div");
  kpi.className = "kpi-row";
  const best = Math.max(0, ...runs.map((r) => Number(r.best_round_score)));
  statTile(kpi, "Runs", fmt(runs.length));
  statTile(kpi, "Recorde de rodada", fmt(best));
  statTile(kpi, "Nível máximo alcançado", fmt(Math.max(0, ...runs.map((r) => r.final_level))));
  statTile(kpi, "Média de rodadas por run", fmt(runs.reduce((s, r) => s + r.rounds_played, 0) / Math.max(runs.length, 1)));
  main.appendChild(kpi);

  const grid = document.createElement("div");
  grid.className = "grid-2";
  main.appendChild(grid);

  // histogram of best round score — log2 bins because scores grow exponentially
  const values = runs.map((r) => Number(r.best_round_score)).filter((v) => v > 0);
  const bins = [];
  if (values.length) {
    const maxExp = Math.ceil(Math.log2(Math.max(...values) + 1));
    for (let e = Math.max(6, 0); e <= maxExp; e++) {
      const lo = e === 6 ? 0 : 2 ** e;
      const hi = 2 ** (e + 1);
      bins.push({ label: fmt(hi), count: values.filter((v) => v >= lo && v < hi).length, lo, hi });
    }
  }
  makeCard(grid, "Distribuição do recorde de rodada", "runs por faixa de pontuação (faixas dobram)",
    (body) => histogram(body, bins),
    { cols: [{ label: "Até" }, { label: "Runs", num: true }],
      rows: bins.map((b) => [fmt(b.hi), fmt(b.count)]) });

  // score by level vs target curve
  const maxLv = Math.max(1, ...runs.map((r) => r.final_level));
  const levels = Array.from({ length: maxLv }, (_, i) => i + 1);
  const sums = new Map(), counts = new Map(), obsTarget = new Map();
  for (const r of runs) {
    for (const round of (r.summary?.rounds || [])) {
      sums.set(round.level, (sums.get(round.level) || 0) + round.score);
      counts.set(round.level, (counts.get(round.level) || 0) + 1);
      // the target the game actually showed — ground truth, never drifts
      if (typeof round.target === "number" && round.target > 0)
        obsTarget.set(round.level, Math.max(obsTarget.get(round.level) || 0, round.target));
    }
  }
  const avg = levels.map((lv) => counts.get(lv) ? sums.get(lv) / counts.get(lv) : null);
  // observed target where a run reached that level; else rebuild from the run's own curve params
  const curve = resolveCurve(runs);
  const target = levels.map((lv) => obsTarget.get(lv) ?? curveTarget(lv, curve));
  const seriesColor = getComputedStyle(document.documentElement).getPropertyValue("--series-1").trim();
  const mutedColor = getComputedStyle(document.documentElement).getPropertyValue("--baseline").trim();
  makeCard(grid, "Pontuação média por nível vs alvo", "escala log — o alvo cresce exponencialmente",
    (body) => {
      lines(body, levels, [
        { name: "média dos jogadores", color: seriesColor, values: avg },
        { name: "pontuação alvo", color: mutedColor, values: target },
      ], { log: true, xLabel: "nível" });
      legend(body, [{ name: "média dos jogadores", color: seriesColor },
        { name: "pontuação alvo", color: mutedColor }], "line");
    },
    { cols: [{ label: "Nível", num: true }, { label: "Média", num: true }, { label: "Alvo", num: true }],
      rows: levels.map((lv, i) => [lv, avg[i] === null ? "–" : fmt(avg[i]), fmt(target[i])]) });

  // hall of fame
  const top = [...runs].sort((a, b) => Number(b.best_round_score) - Number(a.best_round_score)).slice(0, 10);
  const hof = document.createElement("div");
  hof.className = "card";
  const h3 = document.createElement("h3");
  h3.textContent = "\u{1F3DB}️ Hall da Fama — melhores runs";
  hof.appendChild(h3);
  const rows = top.map((r, i) => {
    return [
      ["\u{1F947}", "\u{1F948}", "\u{1F949}"][i] || String(i + 1),
      fmt(Number(r.best_round_score)),
      String(r.final_level),
      r.client_version,
      String(r.seed ?? "–"),
      loadoutSnapshot(r),
    ];
  });
  hof.appendChild(buildTable(
    [{ label: "#" }, { label: "Recorde", num: true }, { label: "Nível", num: true },
      { label: "Versão" }, { label: "Seed" }, { label: "Loadout final" }],
    rows));
  main.appendChild(hof);
}

/* ---------------- tab: Funil ---------------- */

function renderFunnel(main, runs) {
  const maxLv = Math.max(1, ...runs.map((r) => r.final_level));
  const levels = Array.from({ length: maxLv }, (_, i) => i + 1);

  // fold versions past the top 3 into "outras"
  const byVersion = new Map();
  for (const r of runs) byVersion.set(r.client_version, (byVersion.get(r.client_version) || 0) + 1);
  const topVersions = [...byVersion.entries()].sort((a, b) => b[1] - a[1]).slice(0, 3).map((e) => e[0]);
  const css = (v) => getComputedStyle(document.documentElement).getPropertyValue(v).trim();
  const slots = [css("--series-1"), css("--series-2"), css("--series-3"), css("--series-4")];
  const groups = topVersions.map((v, i) => ({
    name: v, color: slots[i],
    runs: runs.filter((r) => r.client_version === v),
  }));
  const others = runs.filter((r) => !topVersions.includes(r.client_version));
  if (others.length) groups.push({ name: "outras", color: slots[3], runs: others });

  const series = groups.map((g) => ({
    name: g.name, color: g.color,
    values: levels.map((lv) => g.runs.filter((r) => r.final_level >= lv).length / Math.max(g.runs.length, 1)),
  }));

  // deadliest level: where the most runs ended
  const deaths = new Map();
  for (const r of runs) deaths.set(r.final_level, (deaths.get(r.final_level) || 0) + 1);
  const deadliest = [...deaths.entries()].sort((a, b) => b[1] - a[1])[0];

  makeCard(main, "Funil de progressão", "% das runs que alcançam cada nível",
    (body) => {
      funnel(body, levels, series, { deadliest: deadliest ? deadliest[0] : null });
      if (series.length > 1) legend(body, series);
      if (deadliest) {
        const note = document.createElement("div");
        note.className = "deadliest";
        note.textContent = `\u{1F480} Nível mais mortal: ${deadliest[0]} — ${deadliest[1]} run(s) terminaram lá`;
        body.appendChild(note);
      }
    },
    { cols: [{ label: "Nível", num: true }, ...series.map((s) => ({ label: s.name, num: true }))],
      rows: levels.map((lv, i) => [lv, ...series.map((s) => pct(s.values[i]))]) });

  const kpi = document.createElement("div");
  kpi.className = "kpi-row";
  statTile(kpi, "Runs abandonadas", fmt(runs.filter((r) => r.outcome === "abandoned").length));
  statTile(kpi, "Duração média (min)", fmt(runs.reduce((s, r) => s + (r.duration_msec || 0), 0) / Math.max(runs.length, 1) / 60000));
  main.appendChild(kpi);
}

/* ---------------- tab: Economia ---------------- */

function renderEconomy(main, runs) {
  const eco = runs.map((r) => r.summary?.economy).filter(Boolean);
  const n = Math.max(eco.length, 1);
  const kpi = document.createElement("div");
  kpi.className = "kpi-row";
  statTile(kpi, "Mana ganha por run (média)", fmt(eco.reduce((s, e) => s + e.earned, 0) / n));
  statTile(kpi, "Mana gasta por run (média)", fmt(eco.reduce((s, e) => s + e.spent, 0) / n));
  statTile(kpi, "Saldo final médio", fmt(eco.reduce((s, e) => s + e.final_money, 0) / n));
  main.appendChild(kpi);

  const SOURCE_LABEL = {
    shop_rune: "Runas", shop_piece: "Peças", shop_modifier: "Modificadores",
    shop_relic: "Relíquias", scroll: "Pergaminhos", upgrade: "Upgrades",
    overclock: "Overclock", relic_reroll: "Reroll de relíquia",
    pedestal: "Pedestal", panel_unlock: "Painéis", other: "Outros",
  };
  const spend = new Map();
  for (const e of eco) {
    for (const [src, v] of Object.entries(e.spend_by_source || {})) {
      spend.set(src, (spend.get(src) || 0) + v);
    }
  }
  const rows = [...spend.entries()]
    .map(([src, v]) => ({ label: SOURCE_LABEL[src] || src, value: v / n, hint: "total " + fmt(v) }))
    .sort((a, b) => b.value - a.value);
  makeCard(main, "Para onde vai a mana", "gasto médio por run, por categoria",
    (body) => hbar(body, rows),
    { cols: [{ label: "Categoria" }, { label: "Média/run", num: true }],
      rows: rows.map((r) => [r.label, fmt(r.value)]) });
}

/* ---------------- render root ---------------- */

function render() {
  const main = document.getElementById("content");
  main.replaceChildren();
  const runs = filteredRuns();
  document.getElementById("status").textContent =
    `${runs.length} de ${state.runs.length} runs`;
  if (!runs.length) {
    const note = document.createElement("div");
    note.className = "empty-note";
    note.textContent = state.runs.length
      ? "Nenhuma run passa nos filtros atuais."
      : "Sem dados ainda — configure a conexão (⚙) e clique em Atualizar, ou carregue um snapshot.";
    main.appendChild(note);
    return;
  }
  const items = filteredItems(runs);
  if (state.tab === "items") renderItems(main, runs, items);
  else if (state.tab === "scores") renderScores(main, runs);
  else if (state.tab === "funnel") renderFunnel(main, runs);
  else renderEconomy(main, runs);
}

/* ---------------- boot ---------------- */

function boot() {
  // settings
  const settings = document.getElementById("settings");
  const urlInput = document.getElementById("cfg-url");
  const keyInput = document.getElementById("cfg-key");
  urlInput.value = localStorage.getItem(LS.url) || "";
  keyInput.value = localStorage.getItem(LS.key) || "";
  document.getElementById("cfg-save").onclick = () => {
    localStorage.setItem(LS.url, urlInput.value.trim());
    localStorage.setItem(LS.key, keyInput.value.trim());
    settings.hidden = true;
    refresh();
  };
  document.getElementById("btn-config").onclick = () => { settings.hidden = !settings.hidden; };
  document.getElementById("btn-refresh").onclick = refresh;
  document.getElementById("btn-snapshot").onclick = downloadSnapshot;
  document.getElementById("file-snapshot").onchange = (e) => {
    if (e.target.files[0]) loadSnapshot(e.target.files[0]);
    e.target.value = "";
  };
  document.getElementById("btn-load").onclick = () => document.getElementById("file-snapshot").click();
  document.getElementById("btn-demo").onclick = () => {
    if (!window.RUNES_DEMO) { alert("demo_data.js não carregou"); return; }
    const data = window.RUNES_DEMO();
    state.runs = data.runs;
    state.items = data.items;
    settings.hidden = true;
    initFilters();
    render();
    document.getElementById("status").textContent = `exemplo: ${state.runs.length} runs (dados fictícios)`;
  };

  document.getElementById("f-outcome").onchange = (e) => { state.filters.outcome = e.target.value; render(); };
  document.getElementById("f-days").onchange = (e) => { state.filters.days = Number(e.target.value); render(); };
  const threshold = document.getElementById("f-threshold");
  threshold.value = state.filters.threshold;
  threshold.onchange = () => { state.filters.threshold = Math.max(1, Number(threshold.value) || 8); render(); };
  const minLevel = document.getElementById("f-minlevel");
  const maxLevel = document.getElementById("f-maxlevel");
  minLevel.onchange = () => { state.filters.minLevel = Math.max(0, Number(minLevel.value) || 0); render(); };
  maxLevel.onchange = () => { state.filters.maxLevel = Math.max(0, Number(maxLevel.value) || 0); render(); };

  for (const btn of document.querySelectorAll("nav.tabs button")) {
    btn.onclick = () => {
      state.tab = btn.dataset.tab;
      document.querySelectorAll("nav.tabs button").forEach((b) => b.classList.toggle("active", b === btn));
      render();
    };
  }

  // deep-linkable tab (#items/#scores/#funnel/#economy)
  const hashTab = location.hash.slice(1);
  if (["items", "scores", "funnel", "economy"].includes(hashTab)) {
    state.tab = hashTab;
    document.querySelectorAll("nav.tabs button").forEach((b) =>
      b.classList.toggle("active", b.dataset.tab === hashTab));
  }

  let cachedAt = null;
  if (window.RUNES_TEST_DATA) {
    state.runs = window.RUNES_TEST_DATA.runs;
    state.items = window.RUNES_TEST_DATA.items;
  } else {
    cachedAt = loadCache();
    if (!localStorage.getItem(LS.url)) settings.hidden = false;
  }
  initFilters();
  render();
  if (cachedAt) {
    document.getElementById("status").textContent += ` · cache de ${cachedAt.toLocaleString("pt-BR")}`;
  }
}

boot();
