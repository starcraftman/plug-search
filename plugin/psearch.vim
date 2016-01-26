" plug-search - Find your plugins!
" ================================
if exists('g:psearch_loaded')
  finish
endif
let g:psearch_loaded = 1

let s:root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let g:psearch_plugs = eval(join(readfile(s:root . '/db.json')))
let g:psearch_tags = eval(join(readfile(s:root . '/tags.json')))

let s:psearch_tab = get(s:, 'psearch_tab', -1)
let s:psearch_buf = get(s:, 'psearch_buf', -1)

function! s:win_create()
  execute 'vertical topleft new'
endfunction

function! s:win_open()
  call s:win_create()

  let s:psearch_tab = tabpagenr()
  let s:psearch_buf = winbufnr(0)
  nnoremap <silent> <buffer> q :bd!<cr>

  call append(0, ["Plug Search", "-----------"])
  setf psearch
endfunction

function! s:win_close()
endfunction

function! s:win_exists()
  let buflist = tabpagebuflist(s:psearch_tab)
  return !empty(buflist) && index(buflist, s:psearch_buf) >= 0
endfunction

function! s:search(...)
  call s:win_open()

  "for [key,plug] in items(g:psearch_plugs)
    "call append(3, key . ': ' . plug['desc'])
    "unlet key plug
  "endfor
endfunction

command! -nargs=* -bang PSearch call s:search(<bang>0, [<f-args>])

" vim:set et sts=2 sw=2 ts=2:
