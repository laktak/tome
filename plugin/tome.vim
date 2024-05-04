scriptencoding utf-8

if exists("g:loaded_tome") || &cp
  finish
endif
let g:loaded_tome = 1

if !exists("g:tome_no_send")
  let g:tome_no_send = ['vim', 'lf']
endif

function! s:getVisualSelection()
  try
    let oldA = @a
    silent normal! gv"ay
    return getreg('a', 1, 0)
  finally
    let @a = oldA
  endtry
endfunction

function! s:getParagraph()
  let start = search('^$', 'bnW')
  let end = search('^$', 'nW')
  if end > 0
    let end = end - 1
  else
    let end = '$'
  endif
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
      echom 'not sending to' proc
      call popup_notification('not sending to '.proc, #{time: 3000, pos: 'center'})
      return
    endif
  endif
  let cmd = "tmux send-keys -t ".cmdPane." ".shellescape(a:text)
  silent call system(cmd)
endfunction

function! s:playLine()
  call s:sendTmuxCommand(v:count, getline(".")."\r")
endfunction

function! s:playSel()
  call s:sendTmuxCommand(v:count, s:getVisualSelection())
endfunction

function! s:playParagraph()
  call s:sendTmuxCommand(v:count, s:getParagraph() . "\n")
endfunction

function! s:mapBufferCRToPlay()
  nnoremap <script> <silent> <nowait> <buffer> <CR> :<C-U>call <SID>playLine()<CR>
endfunction

function! s:playBook()
  call s:mapBufferCRToPlay()
  augroup vimPlayCmds
    au!
    autocmd BufRead .playbook* call s:playBook()
  augroup END
endfunction

nnoremap <silent> <Plug>(TomePlayLine) :<C-U>call <SID>playLine()<CR>
nnoremap <silent> <Plug>(TomePlayParagraph) :<C-U>call <SID>playParagraph()<CR>
xnoremap <silent> <Plug>(TomePlaySelection) :<C-U>call <SID>playSel()<CR>

command! TomePlayBook call s:playBook()

if !exists("g:tome_no_mappings")

  nmap <Leader>u <Plug>(TomePlayLine)
  nmap <Leader>U <Plug>(TomePlayParagraph)
  xmap <Leader>u <Plug>(TomePlaySelection)

endif

