/* Synthetic demo dataset for the dashboard.
 * Lets you explore every tab (with real sprites from the manifest) before any
 * Supabase connection exists. Deterministic: same numbers on every load.
 * window.RUNES_DEMO() -> { runs, items } in the exact shape the REST API returns. */
(() => {
  // deterministic PRNG so the demo looks the same every time you open it
  let _s = 0x9e3779b9;
  const rnd = () => { _s = (_s * 1103515245 + 12345) & 0x7fffffff; return _s / 0x7fffffff; };
  const int = (a, b) => a + Math.floor(rnd() * (b - a + 1));
  const pick = (arr) => arr[Math.floor(rnd() * arr.length)];
  const pickN = (arr, n) => {
    const s = new Set();
    let guard = 0;
    while (s.size < Math.min(n, arr.length) && guard++ < 200) s.add(pick(arr));
    return [...s];
  };
  const uuid = () => "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (rnd() * 16) | 0;
    return (c === "x" ? r : (r & 0x3) | 0x8).toString(16);
  });
  const splitTypeId = (k) => { const i = k.indexOf(":"); return [k.slice(0, i), k.slice(i + 1)]; };
  const mkItem = (runId, pid, ver, type, id, o) => Object.assign({
    run_id: runId, player_id: pid, client_version: ver, item_type: type, item_id: id,
    times_offered: 0, times_bought: 0, times_acquired: 0, times_sold: 0,
    times_upgraded_into: 0, activations: 0, score_contribution: 0,
    in_final_loadout: false, run_outcome: null, run_final_level: null,
  }, o);

  function demoData() {
    const M = window.RUNES_MANIFEST || {};
    const keys = Object.keys(M);
    const byType = (t) => keys.filter((k) => k.startsWith(t + ":"));
    let runeKeys = byType("rune");
    let relicKeys = byType("relic");
    let pieceKeys = byType("slot_piece");
    let modKeys = byType("slot_modifier");
    // manifest might only carry some types — fall back to synthetic ids so the demo still fills up
    const fake = (t, n) => Array.from({ length: n }, (_, i) => `${t}:${t}_demo_${i + 1}`);
    if (!runeKeys.length) runeKeys = fake("rune", 18);
    if (!relicKeys.length) relicKeys = fake("relic", 10);
    if (!pieceKeys.length) pieceKeys = fake("slot_piece", 6);
    if (!modKeys.length) modKeys = fake("slot_modifier", 6);

    const versions = ["0.6.0-beta", "0.5.0-beta", "0.4.0-beta"];
    const players = Array.from({ length: 14 }, () => uuid());
    // intrinsic power per item so some clearly out/under-perform → interesting charts
    const power = {};
    for (const k of [...runeKeys, ...relicKeys, ...pieceKeys, ...modKeys]) power[k] = 0.6 + rnd() * 0.9;

    const srcWeights = {
      shop_rune: 5, shop_piece: 2, shop_modifier: 2, shop_relic: 2,
      scroll: 2, upgrade: 3, overclock: 1, relic_reroll: 1, pedestal: 1,
    };

    const runs = [], items = [];
    for (let i = 0; i < 64; i++) {
      const version = rnd() < 0.6 ? versions[0] : pick(versions);
      const outcome = rnd() < 0.12 ? "abandoned" : "loss";
      const roll = rnd();
      const finalLevel = roll < 0.4 ? int(1, 2) : roll < 0.75 ? int(3, 4) : roll < 0.93 ? int(5, 6) : int(7, 8);

      const loadout = [
        ...pickN(runeKeys, int(3, 7)),
        ...pickN(relicKeys, int(0, 3)),
        ...pickN(pieceKeys, int(0, 2)),
        ...pickN(modKeys, int(0, 2)),
      ];
      const lp = loadout.reduce((s, k) => s + (power[k] || 1), 0) / Math.max(loadout.length, 1);

      const rounds = [];
      let best = 0, total = 0, dur = 0;
      for (let lv = 1; lv <= finalLevel; lv++) {
        const target = Math.floor(100 * Math.pow(1.5 + 0.05 * (lv - 1), lv - 1));
        const score = Math.floor(target * (0.8 + rnd() * 0.5) * lp);
        const d = int(20000, 90000);
        rounds.push({ level: lv, score, target, victory: lv < finalLevel, duration_msec: d });
        best = Math.max(best, score); total += score; dur += d;
      }

      const runId = uuid();
      const pid = players[int(0, players.length - 1)];
      const earned = int(20, 60) * finalLevel;
      const spendBySource = {};
      let spent = 0;
      for (const [src, w] of Object.entries(srcWeights)) {
        if (rnd() < 0.7) { const v = int(3, 10) * w; spendBySource[src] = v; spent += v; }
      }
      const created = new Date(Date.now() - int(0, 75) * 86400000 - int(0, 86400) * 1000).toISOString();

      runs.push({
        run_id: runId, player_id: pid, client_version: version, seed: int(1, 999999999),
        outcome, final_level: finalLevel, rounds_played: rounds.length,
        best_round_score: best, total_score: total, duration_msec: dur, created_at: created,
        summary: {
          rounds,
          economy: { earned, spent, final_money: Math.max(0, earned - spent + int(0, 20)), spend_by_source: spendBySource },
          upgrades: [],
          final_loadout: loadout,
        },
      });

      const seen = new Set(loadout);
      for (const k of loadout) {
        const [type, id] = splitTypeId(k);
        const acts = type === "rune" ? int(1, finalLevel * 3) : 0;
        items.push(mkItem(runId, pid, version, type, id, {
          times_offered: 1, times_bought: rnd() < 0.7 ? 1 : 0, times_acquired: 1,
          times_sold: rnd() < 0.1 ? 1 : 0,
          activations: acts, score_contribution: Math.floor(acts * (30 + (power[k] || 1) * 45)),
          in_final_loadout: true, run_outcome: outcome, run_final_level: finalLevel,
        }));
      }
      // items offered but never taken → makes pick-rate / "most ignored" meaningful
      for (const k of pickN([...runeKeys, ...relicKeys], int(2, 6)).filter((k) => !seen.has(k))) {
        const [type, id] = splitTypeId(k);
        items.push(mkItem(runId, pid, version, type, id, {
          times_offered: 1, in_final_loadout: false, run_outcome: outcome, run_final_level: finalLevel,
        }));
      }
    }
    return { runs, items };
  }

  window.RUNES_DEMO = demoData;
})();
