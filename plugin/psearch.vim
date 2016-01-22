" plug-search - Find your plugins!
" ================================
if exists('g:psearch_loaded')
    finish
endif
let g:psearch_loaded = 1

let g:psearch_plugs = eval(join(readfile('db.json')))
let g:psearch_tags = eval(join(readfile('tags.json')))

function! s:search(...)
  echomsg "Stub"
endfunction

command! -nargs=* -bang PSearch call s:search(<bang>0, [<f-args>])

" vim:set et sw=2 ts=2:
