scriptencoding utf-8

function! s:get_channel() abort
  if !exists('s:job') || job_status(s:job) !=# 'run'
    let s:job = job_start(['gemini', '-json'], {
      \ 'on_stdout': function('s:gemini_cb_out'),
      \ 'on_stderr': function('s:gemini_cb_err'),
      \ 'in_io': 'json',
      \ 'out_io': 'nl',
      \ 'noblock': 1
    \ })
    let s:ch = s:job
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

function! s:gemini_cb_out(job_id, data, event) abort
  let l:msg = json_decode(join(a:data, ''))
  let l:winid = bufwinid('__GEMINI__')
  if l:winid ==# -1
    silent noautocmd split __GEMINI__
    setlocal buftype=nofile bufhidden=wipe noswapfile
    setlocal wrap nonumber signcolumn=no filetype=markdown
    wincmd p
    let l:winid = bufwinid('__GEMINI__')
  endif
  call win_execute(l:winid, 'setlocal modifiable', 1)
  call s:write_text(l:winid, l:msg['text'])
  if l:msg['error'] != ''
    call s:write_text(l:winid, l:msg['error'])
  elseif l:msg['eof']
    call s:write_text(l:winid, "\n")
  endif
  call win_execute(l:winid, 'setlocal nomodifiable nomodified', 1)
endfunction

function! s:gemini_cb_err(job_id, data, event) abort
  echohl ErrorMsg | echom '[gemini ch err] ' .. join(a:data, '') | echohl None
endfunction

function! gemini#send(text) abort
  let l:ch = s:get_channel()
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
  call ch_send(l:ch, json_encode({'text': getline('.')}) .. "\n")
  return "\n"
endfunction
