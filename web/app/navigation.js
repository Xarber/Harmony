// SPDX-License-Identifier: AGPL-3.0-only
const preference = 'harmony-entered-library';
const isQA = () => new URLSearchParams(location.search).get('qa') === '1';

function hasEntered() {
  try { return localStorage.getItem(preference) === 'yes'; }
  catch { return false; }
}

function rememberEntry() {
  if (isQA()) return;
  try { localStorage.setItem(preference, 'yes'); }
  catch { /* The current session can still navigate. */ }
}

export function initialRoute(path, remembered, deliberateLanding) {
  if (path.startsWith('/app')) return 'app';
  return remembered && !deliberateLanding ? 'app' : 'landing';
}

export function configureNavigation() {
  const landing = document.querySelector('#landing-view');
  const library = document.querySelector('#app-view');
  let suspendedDialog;

  function show(route, focus = false) {
    const inLibrary = route === 'app';
    if (!inLibrary) {
      suspendedDialog = library.querySelector('dialog[open]') ?? suspendedDialog;
      suspendedDialog?.close();
    }
    landing.hidden = inLibrary;
    library.hidden = !inLibrary;
    document.body.classList.toggle('landing', !inLibrary);
    document.body.classList.toggle('app-page', inLibrary);
    document.title = inLibrary ? 'Library — Harmony' : 'Harmony — Your music. In perfect harmony.';
    if (focus) {
      window.scrollTo(0, 0);
      const target = inLibrary ? library.querySelector('#main') : landing.querySelector('main');
      target?.focus({preventScroll: true});
      if (inLibrary && suspendedDialog) {
        suspendedDialog.showModal();
        suspendedDialog = undefined;
      }
    }
  }

  const route = initialRoute(location.pathname, !isQA() && hasEntered(), history.state?.landing);
  if (route === 'app') {
    rememberEntry();
    if (location.pathname === '/') history.replaceState(null, '', '/app/' + location.search);
  }
  show(route);

  document.addEventListener('click', event => {
    if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    const link = event.target.closest('a[href]');
    if (!link || link.origin !== location.origin || link.hash || link.target || link.hasAttribute('download')) return;
    const next = link.pathname === '/app/' ? 'app' : link.pathname === '/' ? 'landing' : null;
    if (!next) return;
    event.preventDefault();
    if (next === 'app') rememberEntry();
    const path = next === 'app' ? '/app/' : '/';
    if (location.pathname !== path) history.pushState({landing: next === 'landing'}, '', path + location.search);
    show(next, true);
  });

  window.addEventListener('popstate', () => show(location.pathname.startsWith('/app') ? 'app' : 'landing', true));
}
