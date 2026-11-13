// SPDX-License-Identifier: AGPL-3.0-only
export class LibraryDB {
  constructor(name = 'harmony-web-v1') { this.name = name; this.opening = null; }
  async open() {
    if (!this.opening) this.opening = new Promise((resolve,reject) => {
      const request = indexedDB.open(this.name,2);
      request.onupgradeneeded = () => { for (const name of ['tracks','files','playlists','ideas','state']) if(!request.result.objectStoreNames.contains(name)) request.result.createObjectStore(name,{keyPath:'id'}); const tracks=request.transaction.objectStore('tracks'); if(!tracks.indexNames.contains('hash')) tracks.createIndex('hash','hash',{unique:true}); };
      request.onerror = () => reject(request.error);
      request.onblocked = () => reject(new Error('Close other Harmony tabs to upgrade the library.'));
      request.onsuccess = () => { request.result.onversionchange = () => {request.result.close(); this.opening = null;}; resolve(request.result); };
    });
    return this.opening;
  }
  async all(store) {
    const db = await this.open(); return new Promise((resolve,reject) => {
      const transaction = db.transaction(store); const request = transaction.objectStore(store).getAll();
      request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error);
    });
  }
  async get(store,id) {
    const db = await this.open(); return new Promise((resolve,reject) => {
      const request = db.transaction(store).objectStore(store).get(id); request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error);
    });
  }
  async write(changes) {
    const db = await this.open(); const stores = [...new Set(changes.map(change => change.store))];
    return new Promise((resolve,reject) => {
      const transaction = db.transaction(stores,'readwrite');
      transaction.oncomplete = () => resolve(); transaction.onerror = () => reject(transaction.error); transaction.onabort = () => reject(transaction.error ?? new Error('Storage operation was interrupted.'));
      for (const change of changes) { const store = transaction.objectStore(change.store); if (change.remove) store.delete(change.id); else store.put(change.value); }
    });
  }
  async put(store,value) { return this.write([{store,value}]); }
  async importAudio(file) {
    if (!file.size || file.size > 256_000_000) throw new Error('Choose an audio file smaller than 256 MB. Your original stays unchanged.');
    const quota = await navigator.storage?.estimate?.();
    if (quota?.quota && quota.quota - (quota.usage ?? 0) < file.size + 5_000_000) throw new Error('Not enough browser storage. Export your library before clearing anything.');
    const hash = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',await file.arrayBuffer())),b=>b.toString(16).padStart(2,'0')).join('');
    const existing = (await this.all('tracks')).find(track=>track.hash===hash); if (existing) return {track:existing,duplicate:true};
    const duration = await inspectAudio(file);
    // Recheck after media inspection to avoid duplicates from a concurrent tab import.
    const fresh = (await this.all('tracks')).find(track=>track.hash===hash); if (fresh) return {track:fresh,duplicate:true};
    const track = {id:crypto.randomUUID(),title:file.name.replace(/\.[^.]+$/,''),artist:'',album:'',favorite:false,duration,hash,filename:file.name,addedAt:new Date().toISOString(),lyrics:'',provenance:'Filename / user metadata'};
    try { await this.write([{store:'tracks',value:track},{store:'files',value:{id:track.id,blob:file}}]); } catch(error) { const duplicate=(await this.all('tracks')).find(item=>item.hash===hash);if(duplicate)return {track:duplicate,duplicate:true};throw error; }
    return {track,duplicate:false};
  }
  async close() { if (this.opening) (await this.opening).close(); this.opening = null; }
}
export async function inspectAudio(file) {
  const url = URL.createObjectURL(file); const audio = new Audio(); audio.preload = 'metadata';
  try { return await new Promise((resolve,reject) => {
    const timeout = setTimeout(()=>reject(new Error('Audio inspection timed out.')),15000);
    const finish = callback => {clearTimeout(timeout); audio.onloadedmetadata = null; audio.onerror = null; callback();};
    audio.onloadedmetadata = () => finish(()=>Number.isFinite(audio.duration) && audio.duration > 0 ? resolve(audio.duration) : reject(new Error('Audio duration is invalid.')));
    audio.onerror = () => finish(()=>reject(new Error('This browser cannot decode the selected audio. Try MP3, AAC/M4A or WAV.'))); audio.src = url;
  }); } finally { audio.removeAttribute('src'); audio.load(); URL.revokeObjectURL(url); }
}
