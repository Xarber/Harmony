// SPDX-License-Identifier: AGPL-3.0-only
/** @typedef {{id:string,title:string,artist:string,album:string,favorite:boolean,duration:number,hash:string,filename:string,addedAt:string,lyrics?:string}} Track */
/** @typedef {{id:string,title:string,artist:string,trackID:string|null}} PlaylistEntry */
export const VERSION = '0.1.0';
export const BUILD = '2026-11-07.1';
export function normalize(text) { return String(text).normalize('NFKD').replace(/\p{M}/gu, '').toLocaleLowerCase('en-US').replace(/[^\p{L}\p{N}]+/gu, ' ').trim(); }
export function clock(seconds) { if (!Number.isFinite(seconds)) return '–:––'; const value = Math.max(0, Math.floor(seconds)); return `${Math.floor(value / 60)}:${String(value % 60).padStart(2, '0')}`; }
export function parseList(text) {
  if (typeof text !== 'string' || text.length > 1_000_000) throw new Error('Track lists must be smaller than 1 MB.');
  if (text.includes('#EXT-X-')) throw new Error('HLS streaming manifests are not supported as local playlists.');
  const entries = []; let pending = null;
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim(); if (!line) continue;
    if (line.startsWith('#EXTINF:')) { pending = line.slice(line.indexOf(',') + 1); continue; }
    if (line.startsWith('#')) continue;
    const value = pending ?? line; pending = null;
    const split = value.split(/ [—–-] /); const artist = split.length > 1 ? split.shift() : '';
    entries.push({id:crypto.randomUUID(),title:split.join(' — ') || value,artist,trackID:null});
  }
  if (entries.length > 10000) throw new Error('Track lists are limited to 10,000 entries.');
  return entries;
}
export function candidates(entry, tracks) {
  return tracks.filter(track => normalize(track.title) === normalize(entry.title)).map(track => ({track,confidence:entry.artist && normalize(entry.artist) === normalize(track.artist) ? 0.75 : 0.35,explanation:'Title similarity is a suggestion. Confirm the recording.'}));
}
export function parseLRC(raw) {
  if (typeof raw !== 'string' || raw.length > 2_000_000) throw new Error('Lyrics must be smaller than 2 MB.');
  const offset = Number(raw.match(/\[offset:([+-]?\d+)\]/i)?.[1] ?? 0) / 1000;
  const timed = []; const plain = [];
  for (const line of raw.split(/\r?\n/)) {
    const matches = [...line.matchAll(/\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]/g)];
    if (!matches.length) { if (line.trim() && !line.startsWith('[')) plain.push({time:null,text:line}); continue; }
    const last = matches.at(-1); const text = line.slice(last.index + last[0].length).trim();
    for (const match of matches) if (Number(match[2]) < 60) timed.push({time:Math.max(0,Number(match[1])*60+Number(match[2])+Number(`0.${match[3] ?? 0}`)+offset),text});
  }
  return timed.length ? timed.sort((a,b)=>a.time-b.time) : plain;
}
export function activeLyric(lines, time) { return lines.findLastIndex(line => line.time !== null && line.time <= time); }
export function nextIndex(index, length, repeat, shuffle, automatic = false, random = Math.random) {
  if (!length) return -1;
  if (automatic && repeat === 'one') return index;
  if (shuffle && length > 1) { const other = Math.floor(random() * (length - 1)); return other >= index ? other + 1 : other; }
  if (index + 1 < length) return index + 1;
  return repeat === 'all' ? 0 : -1;
}
export function validateIdeas(data) {
  if (data?.schemaVersion !== 1 || data.project !== 'it.xarber.harmony' || !Array.isArray(data.ideas) || data.ideas.length > 10000) throw new Error('This is not a compatible Harmony Ideas export.');
  const ids = new Set(); const statuses = ['pending','approved','deferred','inProgress','implemented','rejected'];
  for (const idea of data.ideas) {
    if (typeof idea.id !== 'string' || ids.has(idea.id) || typeof idea.title !== 'string' || !idea.title.trim() || !statuses.includes(idea.status) || !Number.isFinite(idea.createdAt) || !Number.isFinite(idea.updatedAt)) throw new Error('Invalid or duplicate idea. Existing ideas were preserved.');
    ids.add(idea.id);
  }
  return data.ideas;
}
