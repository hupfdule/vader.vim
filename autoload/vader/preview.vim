let s:buf_name = 'vader_preview'
let s:buf_id   = ''

""
" Open the preview buffer in a new window.
"
" If the preview buffer wasn't created yet, it is created.
" If the preview buffer is not visible in a current window a new window is
" created for it.
" The preview buffers content is then updated for the current cursor
" location.
function! vader#preview#open() abort
  if !bufexists(s:buf_name)
    call s:create_preview_buffer()
  endif

  let l:cur_win = win_getid()
  let l:win_id = bufwinid(s:buf_name)
  if l:win_id ==# -1
    execute 'rightbelow vnew +' . s:buf_id . 'buffer'
  endif
  call win_gotoid(l:cur_win)

  call vader#preview#update()
endfunction

""
" Close the preview buffers window.
"
" If the preview buffer is not visible in a current window this does
" nothing.
function! vader#preview#close() abort
  let l:cur_win = win_getid()
  let l:win_id = bufwinid(s:buf_name)
  let l:win_nr = win_id2win(l:win_id)
  if l:win_nr !=# 0
    execute l:win_nr . 'wincmd c'
  endif
  call win_gotoid(l:cur_win)
endfunction

""
" Update the content of the preview buffer with the current "Given" block.
"
" The content to display is recognized by the current cursor location.
function! vader#preview#update() abort
  if getbufvar('', '&filetype') !=# 'vader'
    echohl ErrorMsg | echo "Only preview of filetype=vader is supported" | echohl None
    return
  endif

  let l:preview_content = s:get_get_preview_content()
  call deletebufline(s:buf_id, 1, '$')
  for l:line in l:preview_content['content']
    call appendbufline(s:buf_id, '$', l:line)
  endfor

  " delete the leftover, now empty, first line
  call deletebufline(s:buf_id, 1)

  " Set filetype
  if l:preview_content['filetype'] != ''
    call setbufvar(s:buf_id, '&filetype', l:preview_content['filetype'])
  endif

  " Disable folding in the preview buffer
  call setbufvar(s:buf_id, '&foldenable', 0)

  " Enable display of line numbers
  call setbufvar(s:buf_id, '&number', 1)

  " TODO: Adjust width to the maximum necessary?
  " FIXME: This function leaves the "window-header" of the preview active.  Why?
endfunction

""
" Check whether the preview window is visible.
" If it is open a non-zero value is returned.
function! vader#preview#is_open() abort
  return bufwinid(s:buf_name) != -1
endfunction

""
" Returns the content to preview as a list of strings.
"
" The content to preview will be taken from the "Given" block at or before
" the current cursor position.
function! s:get_get_preview_content() abort
  let l:cur_pos = getcurpos()

  let l:prev_given = -1
  let l:prev_other = -1
  while v:true
    let l:prev_heading = search(vader#syntax#_head(), 'bcnW')
    if l:prev_heading == 0
      break
    endif

    let l:match_given = matchlist(getline(l:prev_heading), vader#syntax#_head())
    if l:match_given[3] ==# 'Given'
      let l:prev_given = l:prev_heading
      break
    else
      let l:prev_other = l:prev_heading
    endif
    call cursor(l:prev_heading - 1, 0)
  endwhile

  " if there was no "Given" block there is nothing to preview
  if l:prev_given <= 0
    echohl ErrorMsg | echo "Nothing to preview" | echohl None
    return []
  endif

  " if there was no other block header, the cursor is inside the given
  " block and we need to find the start of the next one
  if l:prev_other <= 0
    call cursor(l:prev_given + 1, 0)
    let l:prev_other = search(vader#syntax#_head(), 'cnW')
    " if there is no other block than the "Given" block we assume the next
    " block 'after' the end of the file
    if l:prev_other == 0
      let l:prev_other = line('$') + 1
    endif
  endif

  call setpos('.', l:cur_pos)

  let l:given_lines = getline(l:prev_given + 1, l:prev_other - 1)

  " TODO: Remove leading 2 spaces (if Given ends with ':')
  if getline(l:prev_given) =~# ':\s*$'
    for i in range(0, len(l:given_lines) - 1)
      let l:given_lines[i] = s:strip_leading_whitespace(l:given_lines[i])
    endfor
  endif

  return {
        \ 'filetype': trim(l:match_given[4]),
        \ 'comment':  trim(l:match_given[5]),
        \ 'content':  l:given_lines
        \ }
endfunction

""
" Remove the leading 2 spaces of a "Given" content line.
"
" If {line} is empty (contains only whitespace or no content at all) it is
" returned unmodified.
"
" Otherwise {line} is returned with the leading 2 space characters removed.

" If {line} is not empty and does not start with 2 spaces it is returned
" unmodified.
function! s:strip_leading_whitespace(line) abort
  " FIXME: We don't need this check anymore. We can always execute the
  " substitution.
  if a:line !~# '\%(^\s*$\)\|\%(^\s\{2\}\)'
    return a:line
  endif

  return substitute(a:line, '^\s\{2\}', '', '')
endfunction

""
" Creates the preview buffer as a hidden buffer.
"
" If the preview buffer already exists it will not be created again.
function! s:create_preview_buffer() abort
  let s:buf_id = bufnr(s:buf_name, 1)
  call setbufvar(s:buf_id, '&buftype'    , 'nofile')
  call setbufvar(s:buf_id, '&bufhidden'  , 'hide')
  call setbufvar(s:buf_id, '&buflisted'  , 0)
  call setbufvar(s:buf_id, '&swapfile'   , 0)

  " temporarily switch to the buffer to be able to write to it
  let l:cur_buf = bufnr('')
  execute s:buf_id  . 'buffer'
  execute l:cur_buf . 'buffer'
endfunction


