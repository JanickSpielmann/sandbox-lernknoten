/* Service Worker, der jeder Antwort die Header COOP und COEP hinzufügt.
   Damit ist die Seite "cross origin isolated" und der Browser erlaubt SharedArrayBuffer.
   Das braucht die Live Eingabe für input() in der Python Sandbox (GitHub Pages kann diese Header nicht selbst senden). */
self.addEventListener('install', function () { self.skipWaiting(); });
self.addEventListener('activate', function (e) { e.waitUntil(self.clients.claim()); });
self.addEventListener('fetch', function (e) {
  var r = e.request;
  if (r.cache === 'only-if-cached' && r.mode !== 'same-origin') return;
  e.respondWith(
    fetch(r).then(function (res) {
      if (res.status === 0) return res;
      var h = new Headers(res.headers);
      h.set('Cross-Origin-Embedder-Policy', 'require-corp');
      h.set('Cross-Origin-Opener-Policy', 'same-origin');
      return new Response(res.body, { status: res.status, statusText: res.statusText, headers: h });
    }).catch(function () { return Response.error(); })
  );
});
