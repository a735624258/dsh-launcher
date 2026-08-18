// DSH 停止管家：监听 127.0.0.1:3099
// GET /ping      -> 200 ok（健康检查）
// GET /shutdown  -> 关闭 3080 端口的 DSH 服务，然后自己退出
const http = require("http");
const { exec } = require("child_process");

const PORT = 3099;
const TARGET = ":3080";

function killPort(port, done) {
  exec(
    `netstat -ano | findstr ${port} | findstr LISTENING`,
    { windowsHide: true },
    (err, stdout) => {
      if (err || !stdout.trim()) { done("no listener on " + port); return; }
      const pids = new Set();
      for (const line of stdout.split(/\r?\n/)) {
        const m = line.trim().split(/\s+/);
        if (m.length >= 5 && /^\d+$/.test(m[m.length - 1])) pids.add(m[m.length - 1]);
      }
      if (pids.size === 0) { done("no pid for " + port); return; }
      const cmd = [...pids].map((p) => `taskkill /f /pid ${p}`).join(" & ");
      exec(cmd, { windowsHide: true }, (e) => done(e ? e.message : "killed: " + [...pids].join(",")));
    }
  );
}

const server = http.createServer((req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Content-Type", "application/json");
  if (req.url.startsWith("/ping")) {
    res.end(JSON.stringify({ ok: true }));
  } else if (req.url.startsWith("/shutdown")) {
    res.end(JSON.stringify({ ok: true, msg: "stopping DSH" }));
    // 稍等让响应先发出去，再关 DSH 和自己
    setTimeout(() => {
      killPort(TARGET, (msg) => {
        console.log("[dsh-stop] " + msg);
        process.exit(0);
      });
    }, 300);
  } else {
    res.statusCode = 404;
    res.end(JSON.stringify({ ok: false }));
  }
});

server.listen(PORT, "127.0.0.1", () => {
  console.log("[dsh-stop] listening on http://127.0.0.1:" + PORT);
});
