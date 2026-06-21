/* Zymlux — Bandeau d'installation (PWA) */
(function () {
  var standalone = window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone;
  if (standalone) return;
  if (localStorage.getItem("zx_install_dismissed")) return;

  var ua = navigator.userAgent;
  var isIOS = /iphone|ipad|ipod/i.test(ua);
  var isSafari = /safari/i.test(ua) && !/crios|fxios|chrome|android/i.test(ua);
  var deferred = null;

  var ICON = '<svg viewBox="0 0 64 64"><rect width="64" height="64" rx="14" fill="#0E0D0C"/><path d="M41 14a22 22 0 1 0 0 36 18 18 0 0 1 0-36Z" fill="#C9A24B"/></svg>';

  function injectStyle() {
    if (document.getElementById("zx-install-style")) return;
    var s = document.createElement("style");
    s.id = "zx-install-style";
    s.textContent =
      '#zx-install{position:fixed;left:50%;bottom:20px;transform:translateX(-50%);z-index:200;display:flex;align-items:center;gap:13px;width:min(440px,92vw);' +
      'background:rgba(28,24,19,0.94);-webkit-backdrop-filter:blur(18px);backdrop-filter:blur(18px);border:1px solid rgba(201,162,75,0.3);' +
      'border-radius:16px;padding:12px 14px;box-shadow:0 20px 50px rgba(0,0,0,0.5);font-family:Inter,-apple-system,sans-serif;color:#F2EDE4;animation:zxup .5s cubic-bezier(.22,1,.36,1);}' +
      '@keyframes zxup{from{opacity:0;transform:translate(-50%,18px)}to{opacity:1;transform:translate(-50%,0)}}' +
      '#zx-install .zx-ic{width:42px;height:42px;border-radius:11px;flex:0 0 auto;overflow:hidden;}' +
      '#zx-install .zx-ic svg{width:100%;height:100%;display:block;}' +
      '#zx-install .zx-tx{flex:1;font-size:0.8rem;line-height:1.35;font-weight:300;color:rgba(242,237,228,0.75);}' +
      '#zx-install .zx-tx b{font-weight:600;display:block;font-size:0.92rem;color:#F2EDE4;margin-bottom:1px;}' +
      '#zx-install button{font-family:inherit;cursor:pointer;}' +
      '#zx-install .zx-go{background:linear-gradient(180deg,#EBCB82,#C9A24B);color:#1A1410;border:none;border-radius:999px;padding:10px 17px;font-size:0.82rem;font-weight:600;white-space:nowrap;}' +
      '#zx-install .zx-x{background:none;border:none;color:rgba(242,237,228,0.45);font-size:1.25rem;line-height:1;padding:2px 4px;flex:0 0 auto;}';
    document.head.appendChild(s);
  }

  function banner(inner) {
    injectStyle();
    var b = document.createElement("div");
    b.id = "zx-install";
    b.innerHTML = inner;
    document.body.appendChild(b);
    b.querySelector(".zx-x").onclick = dismiss;
    return b;
  }
  function dismiss() {
    var b = document.getElementById("zx-install");
    if (b) b.remove();
    localStorage.setItem("zx_install_dismissed", "1");
  }

  // Android / Chrome : prompt natif
  window.addEventListener("beforeinstallprompt", function (e) {
    e.preventDefault();
    deferred = e;
    var b = banner('<div class="zx-ic">' + ICON + '</div><div class="zx-tx"><b>Installer Zymlux</b>Accès rapide depuis ton écran d\'accueil.</div><button class="zx-go">Installer</button><button class="zx-x" aria-label="Fermer">×</button>');
    b.querySelector(".zx-go").onclick = function () {
      deferred.prompt();
      deferred.userChoice.finally(dismiss);
    };
  });

  // iOS Safari : pas de prompt → on guide
  if (isIOS && isSafari) {
    window.addEventListener("load", function () {
      setTimeout(function () {
        if (document.getElementById("zx-install")) return;
        banner('<div class="zx-ic">' + ICON + '</div><div class="zx-tx"><b>Installer Zymlux</b>Appuie sur Partager (⬆️) puis « Sur l\'écran d\'accueil ».</div><button class="zx-x" aria-label="Fermer">×</button>');
      }, 2500);
    });
  }
})();
