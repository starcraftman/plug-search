#!/usr/bin/env bash
ROOT=$(dirname $(dirname $(readlink -f $0)))
STAGE=/tmp/vsearch-staging
VIMRC="$STAGE/vimrc"

# Replace real dbs with test ones during execution
test_dbs() {
  if [ "$1" = "undo" ]; then
    rm "$ROOT/db.json" "$ROOT/tags.json"
    mv "$ROOT/db.json_bak" "$ROOT/db.json"
    mv "$ROOT/tags.json_bak" "$ROOT/tags.json"
  else
    mv "$ROOT/db.json" "$ROOT/db.json_bak"
    mv "$ROOT/tags.json" "$ROOT/tags.json_bak"
    cp "$ROOT/tests/db.json" "$ROOT/tests/tags.json" "$ROOT"
  fi
}

if [ -d "$STAGE" ]; then
    rm -rf "$STAGE"
fi

curl -fLo "$STAGE/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    > /dev/null 2>&1

cat > $VIMRC <<EOF
set nocompatible
set rtp+=$STAGE
set rtp+=$ROOT
call plug#begin('$STAGE/plugged')
  Plug 'junegunn/vader.vim'
  Plug 'tomasr/molokai'
call plug#end()

set background=dark
try
  colorscheme molokai
  " Molokai CursorLine isn't bright enough
  hi CursorLine  ctermbg=236
catch
  colorscheme desert
endtry

set number
set ruler
set shell=/bin/bash
set showcmd
set wildmenu
set wildmode=longest,list,full

inoremap jk <Esc>
vnoremap i  <Esc>
"inoremap <esc> <nop>

nnoremap <Right> :bnext<CR>
nnoremap <Left>  :bprevious<CR>
nnoremap <Up>    :tabn<CR>
nnoremap <Down>  :tabp<CR>

nnoremap <silent> <Space>k :wincmd k<CR>
nnoremap <silent> <Space>j :wincmd j<CR>
nnoremap <silent> <Space>h :wincmd h<CR>
nnoremap <silent> <Space>l :wincmd l<CR>
EOF

test_dbs

TEST_FILE="$ROOT/tests/test.vader"
vim -u "$VIMRC" +PlugInstall +qa > /dev/null 2>&1
if [ "$1" = '!' ]; then
  vim -u "$VIMRC" -c "Vader! $TEST_FILE"
else
  vim -u "$VIMRC" -c "Vader $TEST_FILE"
fi

test_dbs "undo"

jsonlint -q db.json
jsonlint -q tags.json
