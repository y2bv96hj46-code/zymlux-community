// Ancien service worker neutralisé : nettoie le cache et se désinscrit
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', async () => {
  try {
    const keys = await caches.keys();
    await Promise.all(keys.map(k => caches.delete(k)));
    await self.registration.unregister();
    const cs = await self.clients.matchAll();
    cs.forEach(c => c.navigate(c.url));
  } catch (e) {}
});
