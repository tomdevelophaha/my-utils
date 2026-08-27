# vendor/

Third-party skills this library depends on that have no installable upstream.

`setup.sh` symlinks `vendor/skills/*` into `~/.claude/skills/` alongside the
skills in `skills/`, using the same never-clobber rule — a machine that already
has its own copy under that name keeps it.

Everything here is carried, not authored. Directory names stay bare and
un-namespaced, because the skills in `skills/` invoke them by their original
names.

| Skill | Why it is carried | Provenance |
|---|---|---|
| `linus` | Every work tier marks the `/linus` review "never skip". A mandatory gate cannot depend on a file that exists on one machine. | Unknown — found as a plain directory in `~/.claude/skills/` with no git remote and no attribution. |

Dependencies that DO have an upstream are installed by `./setup.sh --with-deps`
instead of being vendored: `superpowers` (Claude plugin marketplace) and
`gsd-core` (npm). Never vendor those.
