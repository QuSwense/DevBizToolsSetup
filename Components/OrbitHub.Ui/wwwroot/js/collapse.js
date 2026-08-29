/* ═══════════════════════════════════════════
   OrbitHub.Ui — per-card collapse state
   Persists each collapsible section card's expanded/collapsed state in
   localStorage. Loaded lazily by the Dashboard via JS interop (import).
   ═══════════════════════════════════════════ */

const STORAGE_KEY = 'servicehub:dashboard:card-collapse';

function readAll() {
    try {
        const raw = localStorage.getItem(STORAGE_KEY);
        return raw ? JSON.parse(raw) : {};
    }
    catch {
        return {};
    }
}

function writeAll(map) {
    try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(map));
    }
    catch {
        // storage unavailable (private mode / quota) — ignore
    }
}

export function get(key) {
    return readAll()[key] === true;
}

export function set(key, collapsed) {
    const all = readAll();
    all[key] = collapsed === true;
    writeAll(all);
}

export function getAll() {
    return readAll();
}
