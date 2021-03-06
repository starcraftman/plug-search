# plug-search

[![Travis][TravisShield]][TravisDash]

## Installation

To install using vim-plug:

```viml
Plug 'starcraftman/plug-search' | Plug 'tyru/open-browser.vim'
```

## Demo

A short demo of current features.

[![Short Demo][DemoGif]][DemoText]

## Notes

Placeholder for an idea I had as a semi-official extension to vim-plug.
Based on a small snippet I remember seeing from junegunn completing from vim-awesome.
I don't think it quite fits inside vim-plug given the db, so better as a plugin itself.

Things it should do:

- [x] Provide some basic search via description/tags (i.e. PlugSearch).
- [x] Maintain a curated db of plugins with useful information. PRs welcome.
- [ ] Provide completion for Plug lines from this db. Toggleable.
- [x] Generate a tags.json db from main db for finding related plugins.
- [ ] Provide some simple warnings of deprecations to users:
  - [x] Example, user using `kien/ctrlp.vim` (inactive) -> notify about `ctrlpvim/ctrlp.vim` (active)
  - [ ] Perhaps even detect when a plugin hasn't received a commit in x period and warn user? Might be annoying.

## Development

To help people easily contribute/edit the json from vim.

Handy vim plugins:
- `Plug 'elzr/vim-json'`
  - Nice highlihting and concealing for json files.
- `Plug 'scrooloose/syntastic'`
  - Live writing syntax checker using jsonlint.
- Compress/decompress json inside vim easily (see jq below).
```viml
nnoremap <Leader>jq :%!jq .<CR>
nnoremap <Leader>jQ :%!jq . -c<CR>
```

Handy programs:
- [jsonlint]:
  - Install: `sudo npm install jsonlint -g`
  - Lints json files, integrates with syntastic.
- [jq]:
  - Install: `sudo apt-get install jq`
  - Compress database: `jq '.' -c db.json > db.json`
  - Deompress/pretty database: `jq '.' db.json > db.json`

<!-- Links -->
[TravisShield]: https://travis-ci.org/starcraftman/plug-search.svg?branch=master
[TravisDash]: https://travis-ci.org/starcraftman/plug-search
[DemoGif]: https://github.com/starcraftman/plug-search/raw/master/demo.gif
[DemoText]: https://github.com/starcraftman/plug-search/blob/master/README.md
[jq]: https://stedolan.github.io/jq
[jsonlint]: https://github.com/zaach/jsonlint
