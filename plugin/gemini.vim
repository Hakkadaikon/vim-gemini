command -nargs=* Gemini call gemini#send(<q-args>)
command -nargs=0 CodeReviewPleaseGemini call gemini#code_review_please()
inoremap <plug>(gemini-expand) <c-r>=gemini#expand()<cr>
if !hasmapto('<plug>(gemini-expand)') && get(g:, 'gemini_expand_key', 1) !=# ''
  if empty(get(g:, 'gemini_expand_key'))
    imap <unique> <expr> <c-y>j pumvisible()?'<c-e><plug>(gemini-expand)':'<plug>(gemini-expand)'
  else
    exe 'imap' g:gemini_expand_key '<plug>(gemini-expand)'
  endif
endif
