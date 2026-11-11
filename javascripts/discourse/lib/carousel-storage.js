// Per-browser carousel state in localStorage. Storage can be blocked (private
// mode, strict cookie settings), so every access is guarded: a failure means
// "no stored state" and never breaks rendering.

const PREFIX = "topic-showcase:carousel";

function key(name, userId) {
  return `${PREFIX}:${name}:${userId ?? "anon"}`;
}

function read(name, userId) {
  try {
    return window.localStorage.getItem(key(name, userId));
  } catch {
    return null;
  }
}

function write(name, userId, value) {
  try {
    if (value == null) {
      window.localStorage.removeItem(key(name, userId));
    } else {
      window.localStorage.setItem(key(name, userId), value);
    }
  } catch {
    // Not persisted; the state still lives in memory for this page view.
  }
}

export function readCollapsed(userId) {
  return read("collapsed", userId) === "1";
}

// "1" when collapsed, removed when expanded.
export function writeCollapsed(userId, collapsed) {
  write("collapsed", userId, collapsed ? "1" : null);
}

export function readSeenAt(userId) {
  return read("seen-at", userId);
}

export function writeSeenAt(userId, isoTimestamp) {
  write("seen-at", userId, isoTimestamp);
}
