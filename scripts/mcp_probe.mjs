// Probe an MCP stdio server: initialize, list tools, optionally call one tool.
// Usage: node scripts/mcp_probe.mjs <server.js> [toolName] [jsonArgs]
import { spawn } from "node:child_process";

const [server, tool, rawArgs] = process.argv.slice(2);
// .exe servers (e.g. tools/pyenv/Scripts/mcp-server-git.exe) run directly; .js servers run under node.
const extra = process.env.PROBE_ARGS ? process.env.PROBE_ARGS.split(" ") : [];
const child = server.endsWith(".exe")
  ? spawn(server, extra, { env: { ...process.env } })
  : spawn("node", [server, ...extra], { env: { ...process.env, MCP_TRANSPORT: "stdio" } });
let buf = "";
const send = (m) => child.stdin.write(JSON.stringify(m) + "\n");
child.stdout.on("data", (d) => {
  buf += d.toString();
  let i;
  while ((i = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, i).trim();
    buf = buf.slice(i + 1);
    if (!line.startsWith("{")) continue;
    const msg = JSON.parse(line);
    if (msg.id === 1) {
      send({ jsonrpc: "2.0", method: "notifications/initialized" });
      send({ jsonrpc: "2.0", id: 2, method: "tools/list" });
    } else if (msg.id === 2) {
      console.log("TOOLS:", msg.result.tools.map((t) => t.name).join(", "));
      if (!tool) finish(0);
      else send({ jsonrpc: "2.0", id: 3, method: "tools/call", params: { name: tool, arguments: JSON.parse(rawArgs || "{}") } });
    } else if (msg.id === 3) {
      console.log("CALL", tool, "=>", JSON.stringify(msg.result ?? msg.error).slice(0, 800));
      finish(0);
    }
  }
});
function finish(code) { child.kill(); process.exit(code); }
setTimeout(() => send({ jsonrpc: "2.0", id: 1, method: "initialize", params: { protocolVersion: "2024-11-05", capabilities: {}, clientInfo: { name: "probe", version: "1" } } }), 1500);
setTimeout(() => { console.log("TIMEOUT"); finish(1); }, 25000);
