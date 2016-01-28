" plug-search - Find your plugins!
" ================================
if exists('g:psr_loaded')
  finish
endif
let g:psr_loaded = 1

let s:root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let g:psr_plugs = eval(join(readfile(s:root . '/db.json')))
let g:psr_tags = eval(join(readfile(s:root . '/tags.json')))

let s:loc = {'tab': -1, 'buf': -1, 'info_buf': -1}

function! s:syntax_win()
  syntax clear
  syntax match psrTitle #^Plug Search#
  syntax match psrUser  #^[a-zA-Z\-\.]\+/#he=e-1
  syntax match psrRepo  #[a-zA-Z\-\.]\+:#he=e-1
  hi def link psrTitle  Title
  hi def link psrUser   Type
  hi def link psrRepo   Repeat
endfunction

" Insert the Plug line at original buffer position
function! s:insert(close)
  let plug = getline('.')
  let index = stridx(plug, ':') - 1
  let plug = plug[0:index]
  let def_opts = get(g:psr_plugs[plug], 'opts', '')
  let line = printf("Plug '%s'%s", plug,
        \ type(def_opts) == type({}) ? ', ' . string(def_opts) : '')

  echomsg plug . ' ' . line
  " TODO: Insert text at previous position.

  if a:close
    call s:win_close()
  endif
endfunction

function! s:switch_to()
  if !s:win_exists()
    return 0
  endif

  " TODO: Extract function
  if winbufnr(0) != s:loc.buf
    let s:pos = [tabpagenr(), winnr(), winsaveview()]
    execute 'normal!' s:loc.tab.'gt'
    let winnr = bufwinnr(s:loc.buf)
    execute winnr.'wincmd w'
    call add(s:pos, winsaveview())
  else
    let s:pos = [winsaveview()]
  endif

  setlocal modifiable
  return 1
endfunction

" Main window = default search one
function! s:create_main_win()
  execute 'vertical topleft new'
  let s:loc.tab = tabpagenr()
  let s:loc.buf = winbufnr(0)
  nnoremap <silent> <buffer> q :call <SID>win_close()<cr>

  " Incomplete functions
  nnoremap <buffer> i :call <SID>insert(0)<cr>
  nnoremap <buffer> I :call <SID>insert(1)<cr>

  " TODO: Help split
  "nnoremap <buffer> ? :call <SID>help()<cr>
  " TODO: Information split below panel
  "nnoremap <buffer> n :call <SID>info()<cr>
endfunction

function! s:win_open()
  if s:switch_to()
    silent %d _
  else
    call s:create_main_win()
  endif

  setlocal buftype=nofile bufhidden=wipe nobuflisted
        \ noswapfile nowrap cursorline modifiable
  setf psearch
  if exists('g:syntax_on')
    call s:syntax_win()
  endif
  call append(0, ["Plug Search", "-----------"])
endfunction

function! s:win_close()
  let s:loc = {'tab': -1, 'buf': -1, 'info_buf': -1}
  silent bdelete!
endfunction

function! s:win_exists()
  let buflist = tabpagebuflist(s:loc.tab)
  return !empty(buflist) && index(buflist, s:loc.buf) >= 0
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
" For testing
command! PT call s:tags('search')

" vim:set et sts=2 sw=2 ts=2:
