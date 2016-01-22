# vim-plug-search

Placeholder for an idea I had as a semi-official extension.
Shouldn't take long to make.
Based on a small snippet I remember seeing from junegunn.
I don't think it quite fits inside vim-plug given the db, so better as a plugin itself.
I'd maintain my own because I don't think vim-awesome is terribly active.

Things it should do:

- [ ] Provide some basic search via description/tags (i.e. PlugSearch).
- [ ] Maintain a curated db in form of a json to be used. I'll take PRs for it.
- [ ] Provide completion while typing from this db. Toggleable.
- [ ] Provide some simple warnings of deprecations to users:
  - [ ] Example, user usessjl/ctrlp (inactive) -> notify about ctrlpvim/ctrlp (active)
  - [ ] Perhaps even detect when a plugin hasn't received a commit in x period and warn user?

## Development

To help people easily contribute/edit the json from vim.

Handy vim plugins:
- `Plug 'elzr/vim-json'`
  - Nice highlihting and concealing for json files:
- `Plug 'scrooloose/syntastic'`
  - Live writing syntax checker using jsonlint:

Handy programs:
- jsonlint:
  - Install: `sudo npm install jsonlint -g'
  - Lints json files, integrates with syntastic.
- [jq](https://stedolan.github.io/jq/).
  - Compress database: `jq '.' -c db.json > db.json`
  - Deompress/pretty database: `jq '.' db.json > db.json`
