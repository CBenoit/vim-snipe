let s:forward_motions = {'f': 1, 't': 1}
let s:jump_tokens = 'abcdefghijklmnopqrstuvwxyz'

function! s:get_hit_counts(hits_rem)
  " returns a list corresponding to s:jump_tokens; each
  " count represents how many hits are in the subtree
  " rooted at the corresponding jump token
  let n_jump_tokens = len(s:jump_tokens)
  let n_hits = repeat([0], n_jump_tokens)
  let hits_rem = a:hits_rem

  let is_first_level = 1
  while hits_rem > 0
    " if we can't fit all the hits in the first level,
    " fit the remainder starting from the last jump token
    let n_children = is_first_level
          \ ? 1
          \ : len(n_jump_tokens) - 1
    for j in range(n_jump_tokens)
      let n_hits[j] += n_children
      let hits_rem -= n_children
      if hits_rem <= 0
        let n_hits[j] += hits_rem
        break
      endif
    endfor
    let is_first_level = 0
  endwhile

  return reverse(n_hits)
endfunction

function! s:GetJumpTokenTree(hits)
  let tree = {}

  " i: index into hits
  " j: index into hits
  let i = 0
  let j = 0
  for y_count in s:get_hit_counts(len(a:hits))
    let node = s:jump_tokens[j]
    if y_count == 1
      let tree[node] = a:hits[i]
    elseif y_count > 1
      let tree[node] = s:MyFunc(a:hits[i:i + y_count - 1])
    else
      continue
    endif
    let j += 1
    let i += y_count
  endfor

  return tree
endfunction

function! s:PromptUser()
  " code
endfunction

function! s:GetHits(char, motion)
  let hits = []
  let flags = ''
  if !has_key(s:forward_motions, a:motion)
    let flags += 'b'
  endif
  while 1
    let [lnum, cnum] = searchpos(
          \'\C' . escape(a:char, '.$^~'),
          \flags,
          \line('.')
          \)
    if lnum == 0 && cnum == 0
      " no more hits
      break
    elseif foldclosed(lnum) != -1
      " skip folded lines
      continue
    endif
    call add(hits, [lnum, cnum])
  endwhile
  return hits
endfunction

function! s:DoMotion(ord, motion)
  if a:ord == 27
    " escape key pressed
    return
  endif
  let orig = [line('.'), col('.')]
  let char = nr2char(a:ord)
  let hits = s:GetHits(char, a:motion)
  echom string(hits)
  let tree = s:GetJumpTokenTree(hits)
  echom string(tree)
endfunction

" nnoremap <unique> <script> <Plug>ForwardMotions <SID>GetHitsForward
nnoremap <script> <Plug>ForwardMotion <SID>DoMotionForward
nnoremap <script> <Plug>ReverseMotion <SID>DoMotionReverse
nnoremap <SID>DoMotionForward :call <SID>DoMotion(getchar(), 'f')<CR>
nnoremap <SID>DoMotionReverse :call <SID>DoMotion(getchar(), 'F')<CR>