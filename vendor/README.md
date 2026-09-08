# vendor/

Skills installed under their original bare, un-namespaced names, because the
skills in `skills/` invoke them by those names rather than by a `my-utils:`
prefix. Most are third-party and carried as-is; a row that says otherwise is
first-party text kept here only for its name.

`setup.sh` symlinks `vendor/skills/*` into `~/.claude/skills/` alongside the
skills in `skills/`, using the same never-clobber rule — a machine that already
has its own copy under that name keeps it.

| Skill | Why it lives here | Provenance |
|---|---|---|
| `linus` | Every work tier marks its review step "never skip". A mandatory gate cannot depend on a file that exists on one machine, and the bare name is what those tiers invoke. | First-party as of 2026-09. The text it replaced came from an open-source forum and reached this repo as a bare directory with no author, licence, or link attached, so there was no way to credit it correctly — it was rewritten rather than redistributed. That earlier text remains in this repo's git history. The review criteria are Linus Torvalds' publicly stated engineering principles, which anyone may restate; the wording here is this repo's own. |

Dependencies that DO have an upstream are installed by `./setup.sh --with-deps`
instead of being vendored: `superpowers` (Claude plugin marketplace) and
`gsd-core` (npm). Never vendor those.
