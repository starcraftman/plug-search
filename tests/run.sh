#!/usr/bin/env bash
ROOT=$(dirname $(dirname $(readlink -f $0)))
STAGE=/tmp/staging
VADER="$STAGE/vader.vim"
VIMRC="$STAGE/vimrc"
VIMPLUG="$STAGE/autoload/plug.vim"

if [ -d "$STAGE" ]; then
    rm -rf "$STAGE"
fi

curl -fLo $VIMPLUG --create-dirs \
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

TEST_FILE="$ROOT/tests/test.vader"
vim -u "$VIMRC" +PlugInstall +qa > /dev/null 2>&1
if [ "$1" = '!' ]; then
  vim -u "$VIMRC" -c "Vader! $TEST_FILE"
else
  vim -u "$VIMRC" -c "Vader $TEST_FILE"
fi

#jsonlint -q db.json
#jsonlint -q tags.json
