const CACHE_VERSION = 'v8';
const CACHE_STATIC = `snowdome-static-${CACHE_VERSION}`;
const CACHE_FONTS = `snowdome-fonts-${CACHE_VERSION}`;

const PRECACHE_URLS = [
  './',
  './index.html',
  './snowdome.html',
  './snow-nyarm.html',
  './manifest.json',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-192-maskable.png',
  './icons/icon-512-maskable.png',
  './icons/apple-touch-icon.png',
  './icons/favicon-32.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_STATIC).then((cache) => {
      // cache: 'reload' で HTTP キャッシュをバイパスし、必ずオリジンから最新を取得してキャッシュする
      const requests = PRECACHE_URLS.map((url) => new Request(url, { cache: 'reload' }));
      return cache.addAll(requests);
    })
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  const keep = new Set([CACHE_STATIC, CACHE_FONTS]);
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => !keep.has(k)).map((k) => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

function isHtmlLike(req) {
  return req.mode === 'navigate' ||
         req.destination === 'document' ||
         req.destination === 'manifest';
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  // 音声/動画はブラウザに任せる（Range リクエストやストリーミングをSWで扱うと壊れやすい）
  if (req.destination === 'audio' || req.destination === 'video') return;

  const url = new URL(req.url);

  // Google Fonts: cache-first, populate on demand
  if (url.hostname === 'fonts.googleapis.com' || url.hostname === 'fonts.gstatic.com') {
    event.respondWith(
      caches.open(CACHE_FONTS).then(async (cache) => {
        const cached = await cache.match(req);
        if (cached) return cached;
        try {
          const res = await fetch(req);
          if (res.ok) cache.put(req, res.clone());
          return res;
        } catch (e) {
          return cached || Response.error();
        }
      })
    );
    return;
  }

  if (url.origin !== self.location.origin) return;

  // HTML / manifest: network-first。オンラインなら常に最新を届け、オフラインだけキャッシュへ
  if (isHtmlLike(req)) {
    event.respondWith(
      fetch(req).then((res) => {
        if (res.ok) {
          const copy = res.clone();
          caches.open(CACHE_STATIC).then((cache) => cache.put(req, copy));
        }
        return res;
      }).catch(() =>
        caches.match(req).then((cached) => cached || caches.match('./index.html'))
      )
    );
    return;
  }

  // その他（アイコン等）: cache-first
  event.respondWith(
    caches.match(req).then((cached) => {
      if (cached) return cached;
      return fetch(req).then((res) => {
        if (res.ok && (res.type === 'basic' || res.type === 'default')) {
          const copy = res.clone();
          caches.open(CACHE_STATIC).then((cache) => cache.put(req, copy));
        }
        return res;
      }).catch(() => Response.error());
    })
  );
});

self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') self.skipWaiting();
});
