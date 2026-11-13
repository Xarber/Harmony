// SPDX-License-Identifier: AGPL-3.0-only
import {mkdir,cp,readdir,readFile,writeFile,rm} from 'node:fs/promises';
import {resolve,join,relative} from 'node:path';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('.',import.meta.url));const out=resolve(root,'dist');
await rm(out,{recursive:true,force:true});await mkdir(out,{recursive:true});
for(const name of ['index.html','guide.html','landing.js','style.css','manifest.webmanifest','app','assets'])await cp(join(root,name),join(out,name),{recursive:true});
await cp(resolve(root,'../LICENSE'),join(out,'LICENSE.txt'));
const landing = await readFile(join(root, 'index.html'), 'utf8');
const app = await readFile(join(root, 'app/index.html'), 'utf8');
const body = html => html.match(/<body[^>]*>([\s\S]*)<\/body>/)[1];
const head = landing.match(/<head>([\s\S]*?)<\/head>/)[1].replace('/landing.js', '/app/main.js');
const landingMarkup = body(landing).replace('id="main"', 'id="landing-main" tabindex="-1"').replace('href="#main"', 'href="#landing-main"');
for (const [file, route] of [['index.html', 'landing'], ['app/index.html', 'app']]) {
  const inApp = route === 'app';
  const html = `<!doctype html><html lang="en"><head>${head}</head><body class="${inApp ? 'app-page' : 'landing'}"><div id="landing-view"${inApp ? ' hidden' : ''}>${landingMarkup}</div><div id="app-view"${inApp ? '' : ' hidden'}>${body(app)}</div></body></html>`;
  await writeFile(join(out, file), html);
}

if(process.argv.includes('--qa')) {await mkdir(join(out,'tests'));for(const name of ['browser.html','browser.js'])await cp(join(root,'tests',name),join(out,'tests',name));}
async function files(dir){let all=[];for(const entry of await readdir(dir,{withFileTypes:true})){const path=join(dir,entry.name);all.push(...(entry.isDirectory()?await files(path):[path]));}return all;}
const assets=(await files(out)).sort();const hash=createHash('sha256');for(const path of assets)hash.update(await readFile(path));const version=hash.digest('hex').slice(0,16);
const template=await readFile(join(root,'sw-template.js'),'utf8');await writeFile(join(out,'sw.js'),template.replace('__CACHE__',`harmony-shell-${version}`).replace('__ASSETS__',JSON.stringify(assets.map(path=>'/'+relative(out,path).replaceAll('\\','/')))));
await writeFile(join(out,'build.json'),JSON.stringify({application:'Harmony',webVersion:'0.1.0',shell:version},null,2)+'\n');
console.log(`Built Harmony web shell ${version} (${assets.length} static files) to ${out}`);
