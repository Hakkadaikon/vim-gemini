scriptencoding utf-8

function! s:get_channel() abort
  if !exists('s:job') || job_status(s:job) !=# 'run'
    let s:job = jobstart(['gemini', '-json'], {'in_mode': 'json', 'out_mode': 'nl', 'noblock': 1})
    let s:ch = s:job " job_start() is the channel itself in Neovim
  endif
  return s:ch
endfunction

function! s:write_text(winid, text) abort
  for l:text in split(a:text, '\zs')
    if l:text == "\n"
      call win_execute(a:winid, 'silent normal! Go', 1)
    else
      call win_execute(a:winid, 'silent normal! GA' .. l:text, 1)
    endif
  endfor
endfunction

function! s:gemini_cb_out(ch, winid, msg) abort
  let l:msg = json_decode(a:msg)
  if a:winid == -1
    let l:winid = bufwinid('__GEMINI__')
    if l:winid ==# -1
      silent noautocmd split __GEMINI__
      setlocal buftype=nofile bufhidden=wipe noswapfile
      setlocal wrap nonumber signcolumn=no filetype=markdown
      wincmd p
      let l:winid = bufwinid('__GEMINI__')
    endif
    call win_execute(l:winid, 'setlocal modifiable', 1)
  else
    let l:winid = a:winid
  endif
  call s:write_text(l:winid, l:msg['text'])
  if l:msg['error'] != ''
    call s:write_text(l:winid, l:msg['error'])
  elseif l:msg['eof']
    call s:write_text(l:winid, "\n")
  endif
  if a:winid == -1
    call win_execute(l:winid, 'setlocal nomodifiable nomodified', 1)
  endif
endfunction

function! s:gemini_cb_err(ch, msg) abort
  echohl ErrorMsg | echom '[gemini ch err] ' .. a:msg | echohl None
endfunction

function! gemini#send(text) abort
  let l:ch = s:get_channel()
  " Pass the winid as a context to the callback
  call ch_setoptions(l:ch, {'out_cb': function('s:gemini_cb_out', [v:null, -1]), 'err_cb': function('s:gemini_cb_err')})
  call ch_send(l:ch, json_encode({'text': a:text}) .. "\n")
endfunction

function! gemini#code_review_please() abort
  let l:lang = get(g:, 'gemini_lang', $LANG)
  let l:question = l:lang =~# '^ja' ? 'このプログラムをレビューして下さい。' : 'please code review'
  let l:lines = [
  \  l:question,
  \  '',
  \] + getline(1, '$')
  call gemini#send(join(l:lines, "\n"))
endfunction

function! gemini#expand() abort
  let l:ch = s:get_channel()
  " Pass the current winid as a context
  call ch_setoptions(l:ch, {'out_cb': function('s:gemini_cb_out', [v:null, bufwinid('%')]), 'err_cb': function('s:gemini_cb_err')})
  call ch_send(l:ch, json_encode({'text': getline('.')}) .. "\n")
  return "\n"
endfunction
