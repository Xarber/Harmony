// SPDX-License-Identifier: AGPL-3.0-only
const CACHE = '__CACHE__';
const ASSETS = __ASSETS__;
const PATHS = new Set(ASSETS);
self.addEventListener('install',event=>event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(ASSETS.map(url=>new Request(url,{cache:'reload'}))))));
// Do not skip waiting automatically. A running player/editor must not reload unexpectedly.
self.addEventListener('message',event=>{if(event.data?.type==='APPLY_UPDATE')self.skipWaiting();});
self.addEventListener('activate',event=>event.waitUntil((async()=>{for(const key of await caches.keys())if(key.startsWith('harmony-shell-')&&key!==CACHE)await caches.delete(key);await self.clients.claim();})()));
self.addEventListener('fetch',event=>{
 const url=new URL(event.request.url);
 if(event.request.method!=='GET'||url.origin!==self.location.origin)return;
 const path=url.pathname==='/'?'/index.html':url.pathname==='/app/'?'/app/index.html':url.pathname;
 if(!PATHS.has(path))return; // Never cache arbitrary APIs, credentials, audio blobs or exports.
 event.respondWith((async()=>{const cache=await caches.open(CACHE);return await cache.match(path)??fetch(event.request);})());
});
