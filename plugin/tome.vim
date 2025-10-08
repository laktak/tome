scriptencoding utf-8

if exists("g:loaded_tome") || &cp
  finish
endif
let g:loaded_tome = 1

if !exists("g:tome_no_send")
  let g:tome_no_send = ['vim', 'nvim', 'lf', 'gitui']
endif

if !exists("g:tome_vars")
  let g:tome_vars = 1
endif

if !exists("g:tome_target")
  let g:tome_target = ''
endif

if !exists("g:tome_skip_prefix")
  let g:tome_skip_prefix = '^\$\s\+'
endif

if !exists("g:tome_highlight_ms")
  let g:tome_highlight_ms = 0
endif

let s:vars = {}
let s:highlight_ids = []

function! TomeSetVar(name, value)
  if g:tome_vars
    let s:vars[a:name]=a:value
  endif
endfunction

function! TomeGetVars()
  if g:tome_vars
    return s:vars
  else
    return {}
  endif
endfunction

function! s:notify(text)
  if has("nvim")
    echohl WarningMsg
    echom a:text
    echohl None
  else
    call popup_notification(a:text, #{time: 3000, pos: 'center'})
  endif
endfunction

function! s:setExecutedHighlight(start_line, end_line)
  if g:tome_highlight_ms <= 0
    return
  endif

  if !hlexists('TomeExecuted')
    highlight default link TomeExecuted IncSearch
  endif

  call s:clearExecutedHighlight()

  for line_num in range(a:start_line, a:end_line)
    let pattern = '\%'.line_num.'l.*'
    let id = matchadd('TomeExecuted', pattern)
    call add(s:highlight_ids, id)
  endfor

  if len(s:highlight_ids) > 0
    let s:tome_highlight_timer = timer_start(g:tome_highlight_ms, function('s:tomeClearHighlightTimer'))
  endif
endfunction

function! s:clearExecutedHighlight()
  if len(s:highlight_ids) > 0
    call timer_stop(s:tome_highlight_timer)
    for id in s:highlight_ids
      try
        call matchdelete(id)
      catch
        " Ignore errors if highlight doesn't exist
      endtry
    endfor
  endif
  let s:highlight_ids = []
endfunction

function! s:tomeClearHighlightTimer(timer)
  call s:clearExecutedHighlight()
endfunction

function! s:tomeSubstituteVars(text)
  if !g:tome_vars | return [a:text, [], []] | endif
  let result = a:text
  let setvars = []
  let uvars = {}
  " set $<NAME>=
  let lines = []
  for line in split(a:text, "\n")
    if match(line, '^\$<\i\+>=.*$') == 0
      let varname = matchstr(line, '\(\$<\)\@<=\i\+\(>=\)\@=')
      let value = matchstr(line, '\([^=]\+=\)\@<=.*$')
      let s:vars[varname] = value
      call add(setvars, varname)
    else
      " remove prefix
      if g:tome_skip_prefix != ''
        let line = substitute(line, g:tome_skip_prefix, '', '')
      endif
      call add(lines, line)
    endif
  endfor
  if len(lines) == 0 | return ["", [], setvars] | endif
  " use \r to simulate the <Enter> key
  let result = join(lines, "\r") . "\r"
  " subst $<NAME>
  while 1
    let varname = matchstr(result, '\$<\i\+>')
    if varname == "" | break | endif
    let varname = varname[2:-2]
    if has_key(s:vars, varname)
      let value = s:vars[varname]
    else
      let value = ''
      let uvars[varname] = ''
    endif
    let result = substitute(result, '\$<' . varname . '>', value, 'g')
  endwhile
  " remove escapes
  let result = substitute(result, '\$<<\(\i\+\)>', '\$<\1>', 'g')
  if len(uvars) == 0
    return [result, [], setvars]
  else
    return ["", keys(uvars), []]
  endif
endfunction

function! s:getAndHighlightCurrentLine()
  call s:setExecutedHighlight(line("."), line("."))
  return getline(".")."\n"
endfunction

function! s:getAndHighlightVisualSelection()
  try
    call s:setExecutedHighlight(line("'<"), line("'>"))
    let oldA = @a
    silent normal! gv"ay
    return getreg('a', 1, 0)
  finally
    let @a = oldA
  endtry
endfunction

function! s:getAndHighlightParagraph()
  let start = search('^$', 'bnW')
  let end = search('^$', 'nW')
  if end > 0
    let end = end - 1
  else
    let end = '$'
  endif
  call s:setExecutedHighlight(start + 1, end)
  let res = getbufline("%", start+1, end)
  return join(res, "\n")
endfunction

function! s:sendTmuxCommand(targetOffset, text)
  let panes = split(system("tmux list-panes -F '#{pane_index}:#{pane_current_command}'"), '\n')
  let active = split(system("tmux list-panes -f '#{pane_active}' -F '#{pane_index}'"), '\n')
  let override = a:targetOffset == 1 " default=0
  let vimPane = str2nr(active[0])
  if a:targetOffset > 0
    let cmdPane = vimPane + a:targetOffset
  else
    let cmdPane = vimPane + 1
  endif
  let panes = filter(panes, 'v:val =~ "^'.cmdPane.':.*"')
  if len(panes) == 0
    silent call system('tmux split-window -v -l 10')
    silent call system('tmux select-pane -t '.vimPane)
  else
    let proc = split(panes[0], ':')[1]
    if index(g:tome_no_send, proc) >= 0 && !override
      return 'not sending to '.proc.' (see config)'
    endif
  endif
  let cmd = "tmux send-keys -t ".cmdPane." -l ".shellescape(a:text)
  silent call system(cmd)
  return ''
endfunction

function! s:sendTerminalCommand(targetOffset, text)
  let current_win = winnr()
  let current_buf = bufnr('%')
  let terminal_buffers = []
  for buf in range(1, bufnr('$'))
    if getbufvar(buf, "&buftype") == 'terminal'
      call add(terminal_buffers, buf)
    endif
  endfor

  if a:targetOffset >= 0 && a:targetOffset < len(terminal_buffers)
    let terminal_buf = terminal_buffers[a:targetOffset]
  else
    " new terminal buffer
    if has("nvim")
      split
    endif
    terminal
    let terminal_buf = bufnr('%')
  endif

  if !has("nvim")
    call term_sendkeys(terminal_buf, a:text)
  else
    call chansend(terminal_buf, a:text)
  endif
  exe current_win . 'wincmd w'
  return ''
endfunction

function! s:getTarget()
  if index(['vim', 'tmux'], g:tome_target) < 0
    " detect tmux
    let g:tome_target = $TMUX_PANE!='' ? 'tmux' : 'vim'
  endif
  return g:tome_target
endfunction

function! s:prepAndSendCommand(targetOffset, text)
  let [cmd, missing, setvars] = s:tomeSubstituteVars(a:text)
  let message = ""
  if len(missing) > 0
    enew
    call s:markScratch("vars")
    call s:mapBufferCRToPlay()
    let x = "# please define the following tome variables\n" . join(map(missing, {idx, val -> '$<' . val . '>='}), "\n")."\n"
    silent! put =x
  elseif cmd != ""
    if s:getTarget() == 'vim'
      let message = s:sendTerminalCommand(a:targetOffset, cmd)
    else
      let message = s:sendTmuxCommand(a:targetOffset, cmd)
    endif
    if message != ''
      call s:notify(message)
      return
    endif
    let message = "sent"
  endif
  if len(setvars) > 0
    if message != ""
      let message = message . "/"
    endif
    let message = message . "set tome var: " . join(setvars, ", ")
  endif
  if message != ""
    if len(message) > 60
      let message = strpart(message, 0, 57) . "..."
    endif
    echo message
  endif
endfunction

function! s:playLine()
  call s:prepAndSendCommand(v:count, s:getAndHighlightCurrentLine())
endfunction

function! s:playSel()
  call s:prepAndSendCommand(v:count, s:getAndHighlightVisualSelection())
endfunction

function! s:playParagraph()
  call s:prepAndSendCommand(v:count, s:getAndHighlightParagraph() . "\n")
endfunction

function! s:mapBufferCRToPlay()
  nnoremap <script> <silent> <nowait> <buffer> <CR> :<C-U>call <SID>playLine()<CR>
endfunction

function! s:markScratch(name)
  let name = len(a:name)>0 ? a:name : 'SCRATCH'
  let [newname, i] = [name, 1]
  while bufnr('\['.newname.'\]') >= 0 && i < 100
    let i += 1
    let newname = name.i
  endwhile
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal buflisted
  exe 'file \['.newname.'\]'
endfunction


nnoremap <silent> <Plug>(TomePlayLine) :<C-U>call <SID>playLine()<CR>
nnoremap <silent> <Plug>(TomePlayParagraph) :<C-U>call <SID>playParagraph()<CR>
xnoremap <silent> <Plug>(TomePlaySelection) :<C-U>call <SID>playSel()<CR>

command! TomePlayBook call s:mapBufferCRToPlay()
command! -nargs=? TomeScratchPad call s:markScratch(<q-args>)|call s:mapBufferCRToPlay()
command! -nargs=? TomeScratchPadOnly call s:markScratch(<q-args>)

if !exists("g:tome_no_mappings")

  nmap <Leader>p <Plug>(TomePlayLine)
  nmap <Leader>P <Plug>(TomePlayParagraph)
  xmap <Leader>p <Plug>(TomePlaySelection)

endif

if !exists("g:tome_no_auto")

  augroup tomePlayCmds
    au!
    autocmd BufRead .playbook* call s:mapBufferCRToPlay()
  augroup END

endif
