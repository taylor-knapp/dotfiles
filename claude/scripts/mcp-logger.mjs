#!/usr/bin/env node
// Stdio proxy that logs all JSON-RPC messages between Claude Code and an MCP server.
// Usage: node mcp-logger.mjs <log-file> <command> [args...]
// Sits between stdin/stdout, forwarding everything while writing JSON-RPC traffic to the log file.

import { spawn } from 'node:child_process';
import { createWriteStream, mkdirSync } from 'node:fs';
import { basename, dirname } from 'node:path';

const [logFile, command, ...args] = process.argv.slice(2);

if (!logFile || !command) {
  process.stderr.write('Usage: mcp-logger.mjs <log-file> <command> [args...]\n');
  process.exit(1);
}

mkdirSync(dirname(logFile), { recursive: true });
const log = createWriteStream(logFile, { flags: 'a' });
const serverName = basename(command);

function timestamp() {
  return new Date().toISOString();
}

const SEP = '────────────────────────────────────────────────────────────';

function createLineBuffer(direction) {
  let buf = '';
  return function feed(chunk) {
    buf += chunk.toString('utf8');
    // Split on newlines; keep the last (possibly incomplete) segment
    const lines = buf.split('\n');
    buf = lines.pop();
    for (const raw of lines) {
      const trimmed = raw.trim();
      if (!trimmed) continue;
      try {
        const msg = JSON.parse(trimmed);
        if (msg.jsonrpc || msg.method || msg.result || msg.error) {
          const label =
            direction === 'request'
              ? `>>> REQUEST (client → ${serverName})`
              : `<<< RESPONSE (${serverName} → client)`;
          log.write(`[${timestamp()}] ${label}\n`);
          log.write(JSON.stringify(msg, null, 2) + '\n');
          log.write(SEP + '\n');
        }
      } catch {
        // Not valid JSON yet — skip (Content-Length headers, etc.)
      }
    }
  };
}

const requestBuffer = createLineBuffer('request');
const responseBuffer = createLineBuffer('response');

log.write(
  `\n${'='.repeat(60)}\n[${timestamp()}] MCP Logger started: ${command} ${args.join(' ')}\n${'='.repeat(60)}\n`
);

const child = spawn(command, args, {
  stdio: ['pipe', 'pipe', 'inherit'],
  env: process.env,
});

process.stdin.on('data', (chunk) => {
  requestBuffer(chunk);
  child.stdin.write(chunk);
});

process.stdin.on('end', () => {
  child.stdin.end();
});

child.stdout.on('data', (chunk) => {
  responseBuffer(chunk);
  process.stdout.write(chunk);
});

child.on('exit', (code, signal) => {
  log.write(`[${timestamp()}] Process exited: code=${code} signal=${signal}\n`);
  log.end();
  process.exit(code ?? 1);
});

child.on('error', (err) => {
  log.write(`[${timestamp()}] Spawn error: ${err.message}\n`);
  log.end();
  process.stderr.write(`mcp-logger: failed to spawn ${command}: ${err.message}\n`);
  process.exit(1);
});

process.on('SIGTERM', () => child.kill('SIGTERM'));
process.on('SIGINT', () => child.kill('SIGINT'));
