scriptencoding utf-8

function! s:get_channel() abort
  if !exists('s:job') || job_status(s:job) !=# 'run'
    let s:job = job_start(['gemini', '-json'], {'in_mode': 'json', 'out_mode': 'nl', 'noblock': 1})
    let s:ch = job_getchannel(s:job)
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

function! s:gemini_cb_out(ch, msg) abort
  let l:msg = json_decode(a:msg)
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
    call s:write_text(l:winid, '')
  endif
  call win_execute(l:winid, 'setlocal nomodifiable nomodified', 1)
endfunction

function! s:gemini_cb_err(ch, msg) abort
  echohl ErrorMsg | echom '[gemini ch err] ' .. a:msg | echohl None
endfunction

function! gemini#send(text) abort
  let l:ch = s:get_channel()
  call ch_setoptions(l:ch, {'out_cb': function('s:gemini_cb_out'), 'err_cb': function('s:gemini_cb_err')})
  call ch_sendraw(l:ch, json_encode({'text': a:text}))
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
