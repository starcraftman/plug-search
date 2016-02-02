" plug-search - Find your plugins!
" ================================
" TODO: Format inserted lines with = . As go? Only on close?
" TODO: Code completion
" TODO: Allow going back forwards with u/ctrl-r, handle nomod
if exists('g:psr_loaded')
  finish
endif
let g:psr_loaded = 1

let s:loc = {'tab': -1, 'win': -1, 'info': -1}
let s:orig_loc = []
let s:lines_put = 0
let s:root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
let g:psr_plugs = eval(join(readfile(s:root . '/db.json')))
let g:psr_tags = eval(join(readfile(s:root . '/tags.json')))

function! s:mul_text(text, times)
  let line = ''
  let times = a:times
  while times > 0
    let line .= a:text
    let times -= 1
  endwhile
  return line
endfunction

function! s:parse_tag_name()
  let words = split(getline('.'))
  if words[0] != '-'
    throw 'No tag found in line: ' . getline('.')
  endif
  return words[1]
endfunction

function! s:parse_plug_name()
  let plug_name = matchstr(getline('.'), '\S\+/[^ :]\+')
  if plug_name == ''
    throw 'No plugin found in line: ' . getline('.')
  endif
  return plug_name
endfunction

function! s:get_plug_entry(name, ...)
  let plug = get(g:psr_plugs, a:name, {})
  if empty(plug)
    if a:0 > 0
      return a:1
    else
      throw 'db.json missing plugin: ' . a:name
    endif
  endif
  return plug
endfunction

function! s:syntax()
  syn clear
  syn match psrComment /[#\-]\+/
  syn match psrTag     #- .*#hs=s+2
  syn match psrTag     #^[^ \-] #he=e-1
  syn match psrUser    #[0-9a-zA-Z.-]\+/#me=e-1,he=e-1
  syn match psrRepo    #/[0-9a-zA-Z.-]\+#ms=s+1
  syn match psrWarning #^PLUGIN UNMAINTAINED#
  syn match psrTitle   #^[A-Z][0-9a-zA-Z ]\+:#he=e-1
  syn match psrTitle   #^All Known Plugins#
  syn match psrTitle   #^All Known Tags#
  " FIXME: Highlighting dict entries of 'Opt' info segment
  syn match psrTerms   #'[0-9a-zA-Z.-]\+'#hs=s+1,he=e-1
  hi def link psrComment Comment
  hi def link psrRepo    Repeat
  hi def link psrTag     Function
  hi def link psrTitle   Title
  hi def link psrUser    Type
  hi def link psrWarning Error
  hi def link psrTerms   Function
endfunction

function! s:help(type)
  if a:type == 'info'
    let lines =  [
        \ "? Toggle this help text",
        \ "q Close this window",
        \ "Q Close all open windows",
        \ "i Insert Plug line into starting buffer",
        \ "I Same as 'i', then close all windows",
        \ "o Open plugin or tag under cursor",
        \ 'O Open plugin github project',
        \ ]
  else
    let lines =  [
        \ "? Toggle this help text",
        \ "q Close all open windows",
        \ "i Insert Plug line into starting buffer",
        \ "I Same as 'i', then close all windows",
        \ "o Open plugin or tag under cursor",
        \ 'O Open plugin github project',
        \ ]
  endif

  setl modifiable
  if getline(1)[0] != '?'
    let buffer = s:mul_text('#', 30)
    call append(0, lines + [buffer])
  else
    exec printf('1,%dd', len(lines) + 1)
  endif
  setl nomodifiable
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

function! s:insert()
  try
    let plug = s:parse_plug_name()
    let def_opts = get(s:get_plug_entry(plug), 'opts', {})
    let line = printf("Plug '%s'%s", plug,
          \ empty(def_opts) ? '' : ', ' . string(def_opts))
    call s:append_to_loc(line, s:orig_loc)
  catch
    echoerr v:exception
  endtry
endfunction

function! s:fill_info(plug_name, plug)
  let header = [a:plug_name, s:mul_text('-', len(a:plug_name)), a:plug.desc]
  let lines = []

  let fork = get(a:plug, 'fork', '')
  if fork != ''
    let lines += ["PLUGIN UNMAINTAINED", "Active Fork: " . fork]
  endif

  let alts = deepcopy(sort(get(a:plug, 'alts', [])), 'i')
  if len(alts)
    let lines += ["Alternatives:"] + map(alts, '"* " . v:val')
  endif

  let opts = get(a:plug, 'opts', {})
  if len(opts)
    " FIXME: Formatting of dict?
    let lines += ["Standard Opts: " . string(opts)]
  endif

  let suggests = deepcopy(sort(get(a:plug, 'suggests', [])), 'i')
  if len(suggests)
    let lines += ["Suggests:"] + map(suggests, '"* " . v:val')
  endif

  let lines += ["Tags:"] + map(deepcopy(sort(a:plug.tags)), '"- " . v:val')

  call append(0, header)
  call append(len(header) + 1, lines)
endfunction

function! s:info_on_tag()
  let tag_name = s:parse_tag_name()
  echomsg tag_name
  let plugs = g:psr_tags[tag_name]

  call s:open_info()

  let header = "Plugins Tagged With: '" . tag_name . "'"
  call append(0, [header, s:mul_text('-', len(header))])
  call append(3, plugs)
  exec '3,' . line('$') . 'sort i'
  setl nomodifiable
endfunction

function! s:info_on_plugin()
  let plug_name = s:parse_plug_name()
  let plug = s:get_plug_entry(plug_name)

  call s:open_info()

  call s:fill_info(plug_name, plug)
  setl nomodifiable
endfunction

function! s:github_uri(plug_name)
  return 'https://github.com/' .  a:plug_name
endfunction

function! s:github_readme()
  try
    let github_uri = s:github_uri(s:parse_plug_name())
    let temp_d = tempname()
    call system(printf('git clone --depth 1 %s %s', github_uri, temp_d))
    let readme = split(globpath(temp_d, 'README*'))
    if empty(readme)
      let readme = split(globpath(temp_d, 'readme*'))
    endif

    exec 'tabnew ' . readme[0]
    nnoremap <silent> <buffer> q :bd!<cr>
    setl buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap cursorline nomodifiable

    call system('rm -rf ' . temp_d)
  catch
    echoerr v:exception
  endtry
endfunction

function! s:open_info()
  if s:switch_to(s:loc.info)
    silent %d _
  else
    belowright new
    let s:loc.info = winbufnr(0)
    nnoremap <silent> <buffer> ? :call <SID>help('info')<cr>
    nnoremap <silent> <buffer> q :call <SID>win_close('info')<cr>
    nnoremap <silent> <buffer> Q :call <SID>win_close('info', 'win')<cr>
    nnoremap <silent> <buffer> i :call <SID>insert()<cr>
    nnoremap <silent> <buffer> I :call <SID>insert()<cr> <bar> :call <SID>win_close('info', 'win')<cr>
    nnoremap <silent> <buffer> o :call <SID>open_type()<cr>
    nnoremap <silent> <buffer> O :call <SID>github_readme()<cr>
    nnoremap <silent> <buffer> <C-G> :call <SID>open_github()<cr>
  endif

  setl buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap cursorline modifiable
  setf psearch

  if exists('g:syntax_on')
    call s:syntax()
  endif
  let b:type = 'info'
endfunction

function! s:win_exists(bufnr)
  let buflist = tabpagebuflist(s:loc.tab)
  return !empty(buflist) && index(buflist, a:bufnr) >= 0
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

  setl modifiable
  return 1
endfunction

function! s:open_type()
  try
    call s:info_on_tag()
  catch
    try
      call s:info_on_plugin()
    catch
      echoerr "Could not parse plugin or tag."
    endtry
  endtry
endfunction

function! s:open_github()
  if !exists(':OpenBrowser')
    echoerr 'Requires Plugin: tyru/open-browser.vim'
    return
  endif
  try
    let plug_name = s:parse_plug_name()
    silent exec 'OpenBrowser ' . s:github_uri(plug_name)
  catch
    echoerr v:exception
  endtry
endfunction

function! s:move_and_describe(dir)
  exec 'normal! ' .  a:dir
  if get(g:, 'psr_auto_open', 0) != 1
    return
  endif
  try
    call s:open_type()
    call s:switch_to(s:loc.win)
  catch
  endtry
endfunction

function! s:open_win()
  if empty(s:orig_loc)
    let s:orig_loc = [tabpagenr(), winbufnr(0), winsaveview()]
  endif

  if s:switch_to(s:loc.win)
    silent %d _
  else
    execute 'vertical topleft new'
    let s:loc.tab = tabpagenr()
    let s:loc.win = winbufnr(0)
    nnoremap <silent> <buffer> ? :call <SID>help('win')<cr>
    nnoremap <silent> <buffer> q :call <SID>win_close('info', 'win')<cr>
    nnoremap <silent> <buffer> i :call <SID>insert()<cr>
    nnoremap <silent> <buffer> I :call <SID>insert()<cr> <bar> :call <SID>win_close('info', 'win')<cr>
    nnoremap <silent> <buffer> o :call <SID>open_type()<cr>
    nnoremap <silent> <buffer> O :call <SID>github_readme()<cr>
    nnoremap <silent> <buffer> <C-G> :call <SID>open_github()<cr>
    nnoremap <silent> <buffer> j :call <SID>move_and_describe('j')<cr>
    nnoremap <silent> <buffer> k :call <SID>move_and_describe('k')<cr>
  endif

  setl buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap cursorline modifiable
  setf psearch
  if exists('g:syntax_on')
    call s:syntax()
  endif
endfunction

function! s:win_close(...)
  for key in a:000
    if s:loc[key] != -1
      call s:switch_to(s:loc[key])
      let s:loc[key] = -1
      silent bdelete!
    endif
  endfor

  if s:loc.win == -1 && s:loc.info == -1
    let s:loc.tab = -1
    let s:orig_loc = []
    let s:lines_put = 0
  endif
endfunction

function! s:match_str(haystack, needles)
  let op = '=~?'
  for needle in a:needles
    if needle =~# '[A-Z]'
      let op = '=~#'
      break
    endif
  endfor

  for needle in a:needles
    if eval('a:haystack ' . op . ' needle')
      return 1
    endif
  endfor
  return 0
endfunction

function! s:join_terms(terms)
  if empty(a:terms)
    return ''
  else
    return "'" . join(a:terms, "' or '") . "'"
  endif
endfunction

function! s:search(...)
  call s:open_win()

  if a:0 == 0
    let title = "All Known Plugins"
    call append(0, [title, s:mul_text('-', len(title))])
    call append(3, keys(g:psr_plugs))
  else
    let title = "Plugins Matching: " . s:join_terms(a:000)
    call append(0, [title, s:mul_text('-', len(title))])
    for [name, plug] in items(g:psr_plugs)
      let line = name . ': ' . plug['desc']
      if s:match_str(line, a:000)
        call append(3, name)
      endif
    endfor
  endif
  let b:type = 'search'
  exec '3,' . line('$') . 'sort i'
  setl nomodifiable
endfunction

function! s:merge_lists(first, second)
  let new_list = copy(a:first)
  for entity in a:second
    if index(new_list, entity) == -1
      call add(new_list, entity)
    endif
  endfor
  return new_list
endfunction

function! s:tags(...)
  call s:open_win()

  if a:0 == 0
    let title = "All Known Tags"
    call append(0, [title, s:mul_text('-', len(title))])
    call append(3, map(keys(g:psr_tags), '"- " . v:val'))
  else
    let tags = []
    for term in a:000
      let tags = s:merge_lists(tags, get(g:psr_tags, term, []))
    endfor
    let title = "Plugins Tagged With: " . s:join_terms(a:000)
    call append(0, [title, s:mul_text('-', len(title))])
    call append(3, tags)
  endif
  let b:type = 'tags'
  exec '3,' . line('$') . 'sort i'
  setl nomodifiable
endfunction

function! s:tag_names(...)
  return sort(filter(keys(g:psr_tags), 'stridx(v:val, a:1) == 0'))
endfunction

command! -nargs=* PSearch call s:search(<f-args>)
command! -nargs=* -complete=customlist,s:tag_names PTags call s:tags(<f-args>)
command! PT call s:tags('search')
command! PLoc :echo string(s:orig_loc)

" vim:set et sts=2 sw=2 ts=2:
