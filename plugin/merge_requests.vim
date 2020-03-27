"--------------------------------------------
" Variables
"-------------------------------------------
let s:start_commit='master'
let s:end_commit='HEAD'
let s:list_files=[]


"--------------------------------------------
" Display the stats of the merge request diff
"-------------------------------------------
function! s:openSwapBuffer()
  :new
  :setlocal buftype=nofile
  :setlocal bufhidden=hide
  :setlocal noswapfile
  :setlocal nobuflisted
endfunction

"--------------------------------------------
" Set syntax
"-------------------------------------------
" inspired by gv.vim
function! s:syntax()
  setf merge_requests
  
  syn clear

  syn match   mrInfo    /^diff\ .*:$/  contains=mrLabels nextgroup=mrFile
  "syn match   mrLabels  /([a-fA-F0-9]\+|master|HEAD)/ contained

  syn match   mrFile      /^\ \+[^|]\+|\ *[0-9]\+\ *[+-]*$/ contains=mrSeparator,mrMods
  syn match   mrSeparator /|/       contained
  syn match   mrMods      /\ *[0-9]\+\ [+-]*/ contained contains=mrPlus,mrMinus
  syn match   mrPlus      /+/       contained
  syn match   mrMinus     /-/       contained

  syn match   mrSummary   /^\ [0-9]\+\ file.*\ changed.*$/

  hi def link mrInfo      Constant
  hi def link mrLabels    Label
  hi def link mrFile      Identifier
  hi def link mrSeparator Conditional
  hi def link mrMods      Normal
  hi def link mrPlus      Type
  hi def link mrMinus     String
  hi def link mrSummary   Comment
endfunction

"--------------------------------------------
" Determine the commits that we will be working with
"-------------------------------------------
function! merge_requests#initCommits(...)
  :let l:nbArgs = a:0
  if l:nbArgs > 0
    :let s:start_commit = a:1
    if l:nbArgs>1
      :let s:end_commit = a:2
    endif
  endif
  :echo s:start_commit.' / '.s:end_commit
endfunction

"--------------------------------------------
" Display the stats of the merge request diff
"-------------------------------------------
function! merge_requests#showDiff(start,end)
  :call s:openSwapBuffer()
  :execute 'normal 0idiff '.a:start.'..'.a:end.':'
  :execute ':r!git diff --stat '.a:start.'..'.a:end
  :execute 'normal gg'
  :call s:syntax()
endfunction

"--------------------------------------------
" Wrapper for the diff
"-------------------------------------------
function! merge_requests#showDiffWrapper(...)
  :call call('merge_requests#initCommits',a:000)  " a normal call would pack the a:000 list into another list
  :call merge_requests#listModFiles(s:start_commit,s:end_commit)
  :call merge_requests#showDiff(s:start_commit,s:end_commit)
endfunction

"--------------------------------------------
" Get the list of affected files in the diff
"-------------------------------------------
function! merge_requests#listFiles(start,end)
  :let l:list=systemlist('git diff --name-only '.a:start.'..'.a:end)
  ":echo l:list
  :let s:list_files = copy(l:list)
endfunction

"--------------------------------------------
" Display the stats of the merge request diff
"-------------------------------------------
function! merge_requests#listModFiles(start,end)
  :call merge_requests#listFiles(a:start,a:end)
  :call setqflist(map(s:list_files,{_, p -> {'filename': p}}),'r')
  ":call setloclist(0,map(l:list,{_, p -> {'filename': p}}))
  ":call setloclist(0,list)
  ":lex list
  ":lex map(l:list,{_, p-> {'filename': p}})
  ":lopen
  ":copen
endfunction

"--------------------------------------------
" Open the two versions of the file
"-------------------------------------------
" Requires fugitive
function! merge_requests#openFileToDiff(start,end)
  :call merge_requests#listFiles(a:start,a:end)
  let l:isInList=0
  for i in range(0,len(s:list_files)-1)
    ":echo s:list_files[i]
    ":echo s:list_files[i].' vs. '.expand('%:.')
    if s:list_files[i] == expand('%:.')
      :let l:isInList=1
      :break
    endif
  endfor

  if l:isInList==1
    :execute ':Gedit '.a:start.':%'
    :execute ':Gdiff '.a:end
  endif
endfunction

"--------------------------------------------
" Commands
"-------------------------------------------
:command! -nargs=* CRDiff :call merge_requests#showDiffWrapper(<f-args>)

:command! -nargs=0 CRFileDiff :call merge_requests#openFileToDiff(s:start_commit,s:end_commit)
