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
  syn match psrTag #^\S #he=e-1
  syn match psrComment /[#\-]\+/
  syn match psrWarning #^PLUGIN UNMAINTAINED#
  syn match psrTitle #^[A-Z][0-9a-zA-Z ]\+:#he=e-1
  syn match psrUser  #[0-9a-zA-Z\-.]\+/#me=e-1,he=e-1
  syn match psrRepo  #/[0-9a-zA-Z\-.]\+#ms=s+1
  syn match psrTag   #- .*#hs=s+2
  hi def link psrWarning Error
  hi def link psrTitle  Title
  hi def link psrUser   Type
  hi def link psrRepo   Repeat
  hi def link psrTag    Function
  hi def link psrComment Comment
endfunction

function! s:syntax_win()
  syn clear
  syn match psrTag #^\S #he=e-1
  syn match psrComment /[#\-]\+/
  syn match psrTitle #^Plug Search#
  syn match psrUser  #^[0-9a-zA-Z\-.]\+/#he=e-1
  syn match psrRepo  #[0-9a-zA-Z\-.]\+:#he=e-1
  hi def link psrTitle  Title
  hi def link psrUser   Type
  hi def link psrRepo   Repeat
  hi def link psrTag    Function
  hi def link psrComment Comment
endfunction

function! s:help_win()
  let lines =  [
      \ "? Toggle this help text.",
      \ "i Insert Plug line into starting buffer.",
      \ "I Same as 'i', then close windows.",
      \ "q Close all open windows.",
      \ ]
  call s:help(lines)
endfunction

function! s:help_info()
  let lines =  [
      \ "? Toggle this help text.",
      \ "q Close this window.",
      \ ]
  call s:help(lines)
endfunction

function! s:help(lines)
  let line = getline(1)
  if line[0] != '?'
    let buffer = s:mul_text('#', winwidth(0) * 0.5)
    call append(0, a:lines + [buffer])
  else
    exec printf('1,%dd', len(a:lines) + 1)
  endif
endfunction

function! s:mul_text(text, times)
  let line = ''
  let times = a:times
  while times > 0
    let line .= a:text
    let times -= 1
  endwhile
  return line
endfunction

function! s:get_plug_name()
  let line = getline('.')
  let index = stridx(line, ':') - 1
  if index == -2
    throw 'No plug found.'
  endif
  return line[0:index]
endfunction

function! s:append_to_loc(lines, loc)
  let [cur_tab, cur_win] = [tabpagenr(), winnr()]
  execute 'normal!' a:loc[0] . 'gt'
  execute bufwinnr(a:loc[1]) . 'wincmd w'

  call append(a:loc[2]['lnum'] + s:lines_put, a:lines)
  let s:lines_put += type(a:lines) == type([]) ? len(a:lines) : 1

  execute 'normal!' cur_tab . 'gt'
  execute cur_win . 'wincmd w'
endfunction

" Insert the Plug line at original buffer position
function! s:insert(close)
  try
    let plug = s:get_plug_name()
    let def_opts = get(g:psr_plugs[plug], 'opts', '')
    let line = printf("Plug '%s'%s", plug,
          \ type(def_opts) == type({}) ? ', ' . string(def_opts) : '')
    call s:append_to_loc(line, s:orig_loc)
  catch
    echoerr 'No plug on current line.'
  endtry

  if a:close
    call s:win_close()
  endif
endfunction

function! s:fill_info(plug, lnum)
  let lnum = a:lnum
  let lines = []

  let fork = get(a:plug, 'fork', '')
  if fork != ''
    let lines = add(lines, "PLUGIN UNMAINTAINED")
    let lines = add(lines, "Active Fork: " . fork)
  endif

  let lines = add(lines,  "Description: " . a:plug.desc)

  let alts = get(a:plug, 'alts', [])
  if len(alts)
    let lines = add(lines, "Alternatives:")
    for alt in alts
      let lines = add(lines, "* " . alt)
    endfor
  endif

  let opts = get(a:plug, 'opts', {})
  if len(opts)
    " FIXME: Formatting of info?
    call add(lines, "Standard Opts:" . string(opts))
  endif

  let suggests = get(a:plug, 'suggests', [])
  if len(suggests)
    call add(lines, "Suggests:")
    for suggest in suggests
      call add(lines, "* " . suggest)
    endfor
  endif

  call add(lines, "Tags:")
  for tag in a:plug.tags
    call add(lines, "- " . tag)
  endfor

  call append(lnum, lines)
endfunction

function! s:open_info()
  try
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

    call append(0, [plug_name, s:mul_text('-', len(plug_name))])
    call s:fill_info(plug, 3)
    normal gg
  catch
    echoerr 'No plug on current line.'
  endtry
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
  nnoremap <silent> <buffer> ? :call <SID>help_info()<cr>
  " TODO: Should be able to 'open' a plugin and replace info buffer.
  " TODO: Should be able to 'open' a tag and replace main window with plugins
  " matching.
  " TODO: Should be able to open to github URL, deps openBrowser?
  " nnoremap <silent> <buffer> O :call <SID>open_github()<cr>
endfunction

" Main window = default search one
function! s:create_main_win()
  execute 'vertical topleft new'
  let s:loc.tab = tabpagenr()
  let s:loc.buf = winbufnr(0)
  nnoremap <silent> <buffer> q :call <SID>win_close()<cr>
  nnoremap <silent> <buffer> i :call <SID>insert(0)<cr>
  nnoremap <silent> <buffer> I :call <SID>insert(1)<cr>
  nnoremap <silent> <buffer> o :call <SID>open_info()<cr>
  " TODO: Should be able to open to github URL, deps openBrowser?
  " nnoremap <silent> <buffer> O :call <SID>open_github()<cr>
  nnoremap <silent> <buffer> ? :call <SID>help_win()<cr>
endfunction

function! s:open_win()
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
  call s:open_win()

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
  call s:open_win()

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
