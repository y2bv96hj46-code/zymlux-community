/* Zymlux — Service Worker
   Met en cache UNIQUEMENT les fichiers statiques du site (même origine).
   Ne touche jamais aux données Supabase (confidentialité). */
const CACHE = "zymlux-v28";
const STATIC = /\.(?:html|css|js|png|svg|webp|jpg|jpeg|gif|ico|woff2?|webmanifest)$/i;

self.addEventListener("install", () => self.skipWaiting());

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  // Ne gérer que les fichiers statiques de notre propre domaine.
  if (url.origin !== location.origin) return;          // -> Supabase, fonts, images externes : jamais cachés
  if (!STATIC.test(url.pathname)) return;              // -> pas de pages dynamiques / API
  e.respondWith(
    fetch(req)
      .then((res) => {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
        return res;
      })
      .catch(() => caches.match(req))
  );
});

// Purge du cache à la demande (déconnexion)
self.addEventListener("message", (e) => {
  if (e.data === "zx-clear-cache") caches.delete(CACHE);
});
