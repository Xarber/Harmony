// SPDX-License-Identifier: AGPL-3.0-only
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {parseList,candidates,parseLRC,activeLyric,nextIndex,validateIdeas,clock} from '../app/domain.js';
test('ordered pasted and M3U lists retain duplicate occurrences',()=>{const entries=parseList('#EXTM3U\n#EXTINF:12,A — Song\na.wav\n#EXTINF:12,A — Song\na.wav');assert.equal(entries.length,2);assert.equal(entries[0].title,'Song');assert.notEqual(entries[0].id,entries[1].id);assert.throws(()=>parseList('#EXT-X-TARGETDURATION:3'));});
test('matching never treats title-only or live versions as exact',()=>{const result=candidates({title:'Café',artist:''},[{id:'1',title:'Cafe',artist:'Artist'},{id:'2',title:'Cafe (Live)',artist:'Artist'}]);assert.equal(result.length,1);assert.equal(result[0].confidence,.35);});
test('lyrics repeat, offset, precision and actual-clock selection',()=>{const lines=parseLRC('[offset:500]\n[00:02.5][00:04.050]Original line\n[00:01.00]First');assert.deepEqual(lines.map(l=>l.time),[1.5,3,4.55]);assert.equal(activeLyric(lines,1.4),-1);assert.equal(activeLyric(lines,3),1);assert.equal(parseLRC('Original plain text')[0].time,null);});
test('queue repeat, shuffle and end behavior',()=>{assert.equal(nextIndex(0,2,'one',false,true),0);assert.equal(nextIndex(1,2,'off',false),-1);assert.equal(nextIndex(1,2,'all',false),0);assert.equal(nextIndex(0,2,'off',true,false,()=>0),1);assert.equal(nextIndex(0,0,'all',true),-1);assert.equal(clock(65.8),'1:05');});
test('Ideas format interoperates with native Swift epoch and rejects invalid input',()=>{const idea={id:crypto.randomUUID(),title:'A note',status:'pending',createdAt:100,updatedAt:100};assert.equal(validateIdeas({schemaVersion:1,project:'it.xarber.harmony',ideas:[idea]}).length,1);assert.throws(()=>validateIdeas({schemaVersion:1,project:'it.xarber.harmony',ideas:[idea,idea]}));assert.throws(()=>validateIdeas({schemaVersion:2,project:'it.xarber.harmony',ideas:[]}));});
test('PWA manifest has identity, scoped standalone launch and maskable icon',async()=>{const manifest=JSON.parse(await readFile(new URL('../manifest.webmanifest',import.meta.url)));assert.equal(manifest.start_url,'/app/');assert.equal(manifest.display,'standalone');assert(manifest.icons.some(icon=>icon.purpose==='maskable'&&icon.sizes==='512x512'));});

import {initialRoute} from '../app/navigation.js';
test('first visit, remembered entry, deliberate landing and deep link', () => {
  assert.equal(initialRoute('/', false, false), 'landing');
  assert.equal(initialRoute('/', true, false), 'app');
  assert.equal(initialRoute('/', true, true), 'landing');
  assert.equal(initialRoute('/app/', false, false), 'app');
});
