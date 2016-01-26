" plug-search - Find your plugins!
" ================================
if exists('g:psr_loaded')
  finish
endif
let g:psr_loaded = 1

let s:root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let g:psr_plugs = eval(join(readfile(s:root . '/db.json')))
let g:psr_tags = eval(join(readfile(s:root . '/tags.json')))

let s:psr_tab = get(s:, 'psr_tab', -1)
let s:psr_buf = get(s:, 'psr_buf', -1)

function! s:win_create()
  execute 'vertical topleft new'
  let s:psr_tab = tabpagenr()
  let s:psr_buf = winbufnr(0)
endfunction

function! s:win_open()
  call s:win_create()

  nnoremap <silent> <buffer> q :bd!<cr>

  call append(0, ["Plug Search", "-----------"])
  setf psearch
endfunction

function! s:win_close()
endfunction

function! s:win_exists()
  let buflist = tabpagebuflist(s:psr_tab)
  return !empty(buflist) && index(buflist, s:psr_buf) >= 0
endfunction

function! s:search(...)
  call s:win_open()

  let term = a:1
  for [name,plug] in items(g:psr_plugs)
    let line = name . ': ' . plug['desc']
    if stridx(line, term) != -1
      call append(3, line)
    endif
    unlet name plug
  endfor
endfunction

function! s:tags(...)
  call s:win_open()

  for name in get(g:psr_tags, a:1, [])
    call append(3, name . ': ' . g:psr_plugs[name]['desc'])
  endfor
endfunction

function! s:tag_names(...)
  return sort(filter(keys(g:psr_tags), 'stridx(v:val, a:1) == 0'))
endfunction

command! -nargs=* PSearch call s:search(<f-args>)
command! -nargs=* -complete=customlist,s:tag_names PTags call s:tags(<f-args>)

" vim:set et sts=2 sw=2 ts=2:
