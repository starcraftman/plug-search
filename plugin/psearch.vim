" plug-search - Find your plugins!
" ================================
if exists('g:psr_loaded')
  finish
endif
let g:psr_loaded = 1

let s:orig_loc = []
let s:lines_put = 0
let s:loc = {'tab': -1, 'buf': -1, 'info_buf': -1}
let s:root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let g:psr_plugs = eval(join(readfile(s:root . '/db.json')))
let g:psr_tags = eval(join(readfile(s:root . '/tags.json')))

function! s:syntax_info(title)
  syn clear
  syn match psrWarning #^PLUGIN UNMAINTAINED#
  syn match psrSubtitle #^[A-Z][0-9a-zA-Z ]\+:#he=e-1
  syn match psrUser  #[0-9a-zA-Z\-.]\+/#me=e-1,he=e-1
  syn match psrRepo  #/[0-9a-zA-Z\-.]\+#ms=s+1
  syn match psrTag   #  - .*#hs=s+4
  hi def link psrWarning Error
  hi def link psrSubtitle  Title
  hi def link psrUser   Type
  hi def link psrRepo   Repeat
  hi def link psrTag    Function
endfunction

function! s:syntax_win()
  syn clear
  syn match psrTitle #^Plug Search#
  syn match psrUser  #^[0-9a-zA-Z\-.]\+/#he=e-1
  syn match psrRepo  #[0-9a-zA-Z\-.]\+:#he=e-1
  hi def link psrTitle  Title
  hi def link psrUser   Type
  hi def link psrRepo   Repeat
endfunction

function! s:append_to_buf(lines, loc)
  let [cur_tab, cur_win] = [tabpagenr(), winnr()]
  execute 'normal!' a:loc[0] . 'gt'
  execute bufwinnr(a:loc[1]) . 'wincmd w'

  call append(a:loc[2]['lnum'] + s:lines_put, a:lines)
  let s:lines_put += type(a:lines) == type([]) ? len(a:lines) : 1

  execute 'normal!' cur_tab . 'gt'
  execute cur_win . 'wincmd w'
endfunction

function! s:get_plug_name()
  let line = getline('.')
  let index = stridx(line, ':') - 1
  return line[0:index]
endfunction

" Insert the Plug line at original buffer position
function! s:insert(close)
  let plug = s:get_plug_name()
  let def_opts = get(g:psr_plugs[plug], 'opts', '')
  let line = printf("Plug '%s'%s", plug,
        \ type(def_opts) == type({}) ? ', ' . string(def_opts) : '')

  call s:append_to_buf(line, s:orig_loc)

  if a:close
    call s:win_close()
  endif
endfunction

function! s:fill_info(plug, lnum)
  let lnum = a:lnum

  let fork = get(a:plug, 'fork', '')
  if fork != ''
    call append(lnum, "PLUGIN UNMAINTAINED")
    call append(lnum + 1, "Active Fork: " . fork)
    let lnum += 2
  endif

  call append(lnum, "Description: " . a:plug.desc)
  let lnum += 1

  call append(lnum, "Tags:")
  let lnum += 1

  for tag in a:plug.tags
    call append(lnum, "  - " . tag)
    let lnum += 1
  endfor

  let alts = get(a:plug, 'alternatives', [])
  if len(alts)
    call append(lnum, "Alternatives:")
    let lnum += 1

    for alt in alts
      call append(lnum, "  * " . alt)
      let lnum += 1
    endfor
  endif
endfunction

function! s:info()
  let plug_name = s:get_plug_name()
  let plug = g:psr_plugs[plug_name]

  if s:switch_to(s:loc.info_buf)
    silent %d _
  else
    call s:create_info_win()
  endif

  setlocal buftype=nofile bufhidden=wipe nobuflisted
        \ noswapfile nowrap cursorline modifiable
  setf psearch

  if exists('g:syntax_on')
    call s:syntax_info(plug_name)
  endif

  let bar = ''
  let len = len(plug_name)
  while len > 0
    let bar = bar . '-'
    let len -= 1
  endwhile

  call append(0, [plug_name, bar])
  call s:fill_info(plug, 3)
endfunction

function! s:switch_to(bufnr)
  if !s:win_exists(a:bufnr)
    return 0
  endif

  if winbufnr(0) != a:bufnr
    let s:pos = [tabpagenr(), winnr(), winsaveview()]
    execute 'normal!' s:loc.tab . 'gt'
    execute bufwinnr(a:bufnr) . 'wincmd w'
    call add(s:pos, winsaveview())
  else
    let s:pos = [winsaveview()]
  endif

  setlocal modifiable
  return 1
endfunction

function! s:create_info_win()
  new
  let s:loc.info_buf = winbufnr(0)
  nnoremap <silent> <buffer> q :bd!<cr>
endfunction

" Main window = default search one
function! s:create_main_win()
  execute 'vertical topleft new'
  let s:loc.tab = tabpagenr()
  let s:loc.buf = winbufnr(0)
  nnoremap <silent> <buffer> q :call <SID>win_close()<cr>
  nnoremap <silent> <buffer> i :call <SID>insert(0)<cr>
  nnoremap <silent> <buffer> I :call <SID>insert(1)<cr>
  nnoremap <silent> <buffer> n :call <SID>info()<cr>

  " TODO: Help split
  "nnoremap <buffer> ? :call <SID>help()<cr>
endfunction

function! s:win_open()
  if empty(s:orig_loc)
    let s:orig_loc = [tabpagenr(), winnr(), winsaveview()]
  endif

  if s:switch_to(s:loc.buf)
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
  for key in ['buf', 'info_buf']
    if s:loc[key] != -1
      call s:switch_to(s:loc[key])
      let s:loc[key] = -1
      silent bdelete!
    endif
  endfor
  let s:loc.tab = -1
  let s:orig_loc = []
  let s:lines_put = 0
endfunction

function! s:win_exists(bufnr)
  let buflist = tabpagebuflist(s:loc.tab)
  return !empty(buflist) && index(buflist, a:bufnr) >= 0
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
