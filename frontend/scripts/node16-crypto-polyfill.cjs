/**
 * Polyfill for Node.js 16 to provide `globalThis.crypto.getRandomValues`,
 * which Vite 5 expects during startup.
 *
 * Node 16 exposes WebCrypto at `require("crypto").webcrypto`.
 *
 * Note: Vite 5 also uses `import crypto from "node:crypto"` and calls
 * `crypto.getRandomValues(...)`. In Node 16, `require("crypto").getRandomValues`
 * is undefined, so we patch it to point at `crypto.webcrypto.getRandomValues`.
 */
try {
  const crypto = require("crypto");
  const webcrypto = crypto && crypto.webcrypto;

  // Patch global WebCrypto
  if (webcrypto && (!globalThis.crypto || typeof globalThis.crypto.getRandomValues !== "function")) {
    globalThis.crypto = webcrypto;
  }

  // Patch node:crypto default import (CommonJS export) used by Vite
  if (webcrypto && typeof crypto.getRandomValues !== "function" && typeof webcrypto.getRandomValues === "function") {
    crypto.getRandomValues = webcrypto.getRandomValues.bind(webcrypto);
  }
} catch (_) {
  // Best-effort; if it still fails, user must upgrade Node.
}


