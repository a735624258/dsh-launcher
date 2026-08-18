// 页面右下角注入"停止 DSH"悬浮按钮
(() => {
  if (document.getElementById("dsh-stop-btn")) return;

  const btn = document.createElement("div");
  btn.id = "dsh-stop-btn";
  btn.textContent = "⏻ 停止 DSH";
  btn.style.cssText = `
    position: fixed; left: 85px; bottom: 6px; z-index: 99999;
    background: #e5484d; color: #fff; border: none; border-radius: 999px;
    padding: 7px 12px; font: 600 12px/1.4 system-ui, sans-serif;
    cursor: pointer; box-shadow: 0 4px 14px rgba(229,72,77,.45);
    user-select: none; transition: transform .15s ease, opacity .15s ease;
  `;
  btn.onmouseenter = () => { btn.style.transform = "scale(1.05)"; };
  btn.onmouseleave = () => { btn.style.transform = "scale(1)"; };
  btn.onclick = () => {
    btn.textContent = "⏳ 正在停止…";
    btn.style.opacity = "0.6";
    chrome.runtime.sendMessage({ action: "stop" }, (res) => {
      if (res && res.ok) {
        btn.textContent = "✅ 已停止";
        // 服务已停，标签页由 background 关闭
      } else {
        btn.textContent = "⚠ 停止失败";
        setTimeout(() => { btn.textContent = "⏻ 停止 DSH"; btn.style.opacity = "1"; }, 3000);
      }
    });
  };
  document.body.appendChild(btn);
})();
