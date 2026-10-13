#!/usr/bin/env node
// Stdio-to-HTTP bridge for MCP servers (Streamable HTTP transport).
// Reads JSON-RPC from stdin, POSTs to the remote endpoint, writes responses to stdout.
// Handles both JSON and SSE response bodies.
// Usage: mcp-sse-bridge.mjs <url> [--header "Name: Value"] ...

import { createInterface } from "node:readline";

const args = process.argv.slice(2);
const headers = {};
let url;

for (let i = 0; i < args.length; i++) {
  if (args[i] === "--header" && args[i + 1]) {
    const idx = args[i + 1].indexOf(":");
    if (idx > 0) {
      headers[args[i + 1].slice(0, idx).trim()] = args[i + 1].slice(idx + 1).trim();
    }
    i++;
  } else if (!url) {
    url = args[i];
  }
}

if (!url) {
  process.stderr.write("Usage: mcp-sse-bridge.mjs <url> [--header 'Name: Value'] ...\n");
  process.exit(1);
}

let sessionId = null;
let inflight = 0;
let stdinClosed = false;

function maybeExit() {
  if (stdinClosed && inflight === 0) process.exit(0);
}

function log(msg) {
  process.stderr.write(`[mcp-bridge] ${msg}\n`);
}

async function parseSSEResponse(res) {
  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buf = "";
  let eventData = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buf += decoder.decode(value, { stream: true });
    const lines = buf.split("\n");
    buf = lines.pop();

    for (const line of lines) {
      if (line.startsWith("data:")) {
        eventData += (eventData ? "\n" : "") + line.slice(5).trim();
      } else if (line.trim() === "" && eventData) {
        try {
          const msg = JSON.parse(eventData);
          process.stdout.write(JSON.stringify(msg) + "\n");
        } catch {
          log(`Non-JSON SSE data: ${eventData}`);
        }
        eventData = "";
      }
    }
  }

  if (eventData) {
    try {
      const msg = JSON.parse(eventData);
      process.stdout.write(JSON.stringify(msg) + "\n");
    } catch {
      // trailing non-JSON
    }
  }
}

async function postMessage(body) {
  inflight++;
  try {
    const postHeaders = {
      ...headers,
      "Content-Type": "application/json",
      Accept: "application/json, text/event-stream",
    };
    if (sessionId) {
      postHeaders["Mcp-Session-Id"] = sessionId;
    }

    const res = await fetch(url, {
      method: "POST",
      headers: postHeaders,
      body,
    });

    const sid = res.headers.get("mcp-session-id");
    if (sid) sessionId = sid;

    if (!res.ok) {
      const errBody = await res.text().catch(() => "");
      log(`POST failed: ${res.status} ${res.statusText} ${errBody}`);
      const snippet = errBody.replace(/\s+/g, " ").trim().slice(0, 500);
      const message = `HTTP ${res.status} ${res.statusText}${snippet ? `: ${snippet}` : ""}`;
      let parsedId;
      try {
        parsedId = JSON.parse(body).id;
      } catch {}
      if (parsedId !== undefined) {
        const errResponse = {
          jsonrpc: "2.0",
          id: parsedId,
          error: { code: -32000, message, data: { status: res.status, body: snippet } },
        };
        process.stdout.write(JSON.stringify(errResponse) + "\n");
      } else {
        process.stdout.write(
          JSON.stringify({
            jsonrpc: "2.0",
            method: "notifications/message",
            params: { level: "error", logger: "mcp-bridge", data: message },
          }) + "\n",
        );
      }
      return;
    }

    const contentType = res.headers.get("content-type") || "";
    if (contentType.includes("text/event-stream")) {
      await parseSSEResponse(res);
    } else {
      const text = await res.text();
      if (text.trim()) {
        process.stdout.write(text.endsWith("\n") ? text : text + "\n");
      }
    }
  } catch (err) {
    log(`POST error: ${err.message}`);
    let parsedId;
    try {
      parsedId = JSON.parse(body).id;
    } catch {}
    if (parsedId !== undefined) {
      const errResponse = {
        jsonrpc: "2.0",
        id: parsedId,
        error: { code: -32001, message: `Bridge fetch error: ${err.message}` },
      };
      process.stdout.write(JSON.stringify(errResponse) + "\n");
    }
  } finally {
    inflight--;
    maybeExit();
  }
}

log(`Bridge ready → ${url}`);

const rl = createInterface({ input: process.stdin });

rl.on("line", (line) => {
  const trimmed = line.trim();
  if (!trimmed) return;
  postMessage(trimmed);
});

rl.on("close", () => {
  stdinClosed = true;
  maybeExit();
});

process.on("SIGTERM", () => process.exit(0));
process.on("SIGINT", () => process.exit(0));
