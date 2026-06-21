/* Enregistrement du service worker (PWA). Sorti dans un fichier à part
   pour permettre une politique de sécurité (CSP) stricte sans script en ligne. */
if ("serviceWorker" in navigator) {
  window.addEventListener("load", function () {
    navigator.serviceWorker.register("sw.js").catch(function () {});
  });
}
