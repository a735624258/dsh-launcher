// 后台：转发停止请求到本地管家服务，成功后关闭对应标签页
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg && msg.action === "stop") {
    fetch("http://127.0.0.1:3099/shutdown")
      .then((r) => r.json())
      .then((data) => {
        sendResponse({ ok: true, data });
        // 等停止生效后关闭标签页（服务 300ms 后 kill，这里 600ms 后关）
        if (sender.tab && sender.tab.id != null) {
          setTimeout(() => {
            try { chrome.tabs.remove(sender.tab.id); } catch (e) { /* tab 可能已关 */ }
          }, 600);
        }
      })
      .catch((e) => sendResponse({ ok: false, error: String(e) }));
    return true; // 异步响应
  }
});
