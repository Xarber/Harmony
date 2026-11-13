// SPDX-License-Identifier: AGPL-3.0-only
import {nextIndex} from './domain.js';
export class LocalPlayer extends EventTarget {
  constructor(db) {
    super(); this.db = db; this.audio = new Audio(); this.audio.preload='metadata'; this.queue=[]; this.index=0; this.repeat='off'; this.shuffle=false; this.track=null; this.objectURL=null; this.generation=0; this.lastSaved=0;
    for (const event of ['play','pause','timeupdate','loadedmetadata','seeked','error']) this.audio.addEventListener(event,()=>{this.dispatchEvent(new Event('change')); if (Date.now()-this.lastSaved>3000 || event==='pause') {this.lastSaved=Date.now(); this.persist().catch(()=>{});} });
    this.audio.addEventListener('ended',()=>this.next(true).catch(error=>this.fail(error)));
    if ('mediaSession' in navigator) {
      for (const [name,action] of Object.entries({play:()=>this.audio.play(),pause:()=>this.audio.pause(),nexttrack:()=>this.next(),previoustrack:()=>this.previous(),seekto:event=>this.seek(event.seekTime)})) {
        try { navigator.mediaSession.setActionHandler(name,action); } catch { /* Capability differs by browser. */ }
      }
    }
  }
  async start(ids,index=0) { this.queue=[...ids]; this.index=index; await this.load(true); }
  async load(autoplay=false,position=0) {
    const generation=++this.generation; this.audio.pause();
    const track=await this.db.get('tracks',this.queue[this.index]); const file=track && await this.db.get('files',track.id);
    if (generation!==this.generation) return;
    if (!track || !file?.blob) throw new Error('Audio is missing. Import the corresponding file first.');
    if (this.objectURL) URL.revokeObjectURL(this.objectURL);
    this.track=track; this.objectURL=URL.createObjectURL(file.blob); this.audio.src=this.objectURL;
    this.audio.onloadedmetadata=()=>{if (generation===this.generation && position>0) this.seek(position);};
    if ('mediaSession' in navigator && 'MediaMetadata' in window) navigator.mediaSession.metadata=new MediaMetadata({title:track.title,artist:track.artist,album:track.album});
    this.dispatchEvent(new Event('change'));
    if (autoplay) await this.audio.play(); await this.persist();
  }
  async toggle() { if (!this.track) return; if (this.audio.paused) await this.audio.play(); else this.audio.pause(); }
  seek(time) { if (Number.isFinite(time)) this.audio.currentTime=Math.max(0,Math.min(time,this.audio.duration || this.track?.duration || 0)); }
  async next(automatic=false) { const next=nextIndex(this.index,this.queue.length,this.repeat,this.shuffle,automatic); if(next<0){this.audio.pause();this.seek(0);return;} this.index=next;await this.load(true); }
  async previous() { if(this.audio.currentTime>3){this.seek(0);return;} this.index=Math.max(0,this.index-1); await this.load(true); }
  async persist() { await this.db.put('state',{id:'playback',queue:this.queue,index:this.index,position:this.audio.currentTime,shuffle:this.shuffle,repeat:this.repeat}); }
  async restore() { const saved=await this.db.get('state','playback'); if(!saved?.queue?.length)return; this.queue=saved.queue;this.index=saved.index;this.shuffle=!!saved.shuffle;this.repeat=saved.repeat;await this.load(false,saved.position); }
  fail(error) { this.dispatchEvent(new CustomEvent('failure',{detail:error.message})); }
  destroy() { this.generation++;this.audio.pause();this.audio.removeAttribute('src');this.audio.load();if(this.objectURL) URL.revokeObjectURL(this.objectURL); }
}
