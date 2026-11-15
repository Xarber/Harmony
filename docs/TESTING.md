# Quality checks

The UADS quality workflow runs on pull requests to testing, beta and main on pushes to testing and by manual dispatch. It runs Swift and web tests, reports suite-wide coverage and validates the production PWA export and policy configuration. The existing build workflow handles packaging. Local equivalents are `scripts/check.sh`, `node --test web/tests/*.test.mjs`, `node web/build.mjs --production`, and `python scripts/check-web-export.py`. Install `jsonschema==4.26.0` in a Python virtual environment to run `python scripts/validate-uads.py`.

The byte budget is enforced on the production JavaScript before compression. Browser runtime metrics and native cold-start targets in the budget file require measurements on logged reference environments. Changed-line and changed-branch coverage target 80% and 70% respectively. Suite-wide output does not verify those targets. Changed-code enforcement and continuous security and accessibility gates remain pending. Web targets WCAG 2.2 AA and requires manual focus, keyboard, screen reader, motion and scaling checks in addition to automation.

Use browser and native runtime checks appropriate to each release. Critical defects block affected releases. High-severity defects block stable releases unless a documented authorized exception is permissible.
