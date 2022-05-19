"--------------------------------------------
" Variables
"-------------------------------------------
"let s:start_commit='master'
"let s:end_commit='HEAD'
let s:list_files=[]


"--------------------------------------------
" Display the stats of the merge request diff
"--------------------------------------------
function! s:openSwapBuffer()
  :tabnew
  :setlocal buftype=nofile
  :setlocal bufhidden=hide
  :setlocal noswapfile
  :setlocal nobuflisted
endfunction

"--------------------------------------------
" Set syntax
"--------------------------------------------
" inspired by gv.vim
function! s:syntax()
  setf merge_requests
  
  syn clear

  syn match   mrInfo    /^diff\ .*:$/  contains=mrLabels nextgroup=mrFile

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
"--------------------------------------------
function! merge_requests#initCommits(...)
  :let l:nbArgs = a:0
  if l:nbArgs > 0
    :let s:start_commit = a:1
    if l:nbArgs>1
      :let s:end_commit = a:2
    else
      :let s:end_commit = "HEAD"
    endif
  else
    :let s:start_commit = "master"
  endif
  ":echo s:start_commit.' / '.s:end_commit

  :let s:three_ways = 0
  if l:nbArgs>2
    if '3' == a:3
      :let s:three_ways = 1
    endif
  endif
endfunction

"--------------------------------------------
" Display the stats of the merge request diff
"--------------------------------------------
function! merge_requests#showDiff(start,end)
  if has('popupwin')
    :call popup_dialog(['Statistics: '.a:start.'..'.a:end, '']+systemlist('git diff --stat '.a:start.'..'.a:end)+['', '[x] Close'], #{filter: 'popup_filter_yesno', callback: 'merge_requests#showList'}) 
  else
    :call s:openSwapBuffer()
    :execute 'normal 0idiff '.a:start.'..'.a:end.':'
    :execute ':r!git diff --stat '.a:start.'..'.a:end
    :execute 'normal gg'
    :call s:syntax()
  endif
endfunction

"--------------------------------------------
" Display the list of modified files
"--------------------------------------------
function! merge_requests#showList(id, result)
  if has('popupwin')
    :call popup_menu(systemlist('git diff --name-only '.s:start_commit.'..'.s:end_commit), #{title: 'Pick a file', callback: 'merge_requests#openPickedFile'})
  else
    :copen
  endif
endfunction

"--------------------------------------------
" Display the file indexed
"--------------------------------------------
function! merge_requests#openPickedFile(id, index)
  :only
  :execute 'cc '.a:index
  :call merge_requests#openFileToDiff(s:start_commit,s:end_commit)
endfunction

"--------------------------------------------
" Wrapper for the diff
"--------------------------------------------
function! merge_requests#showDiffWrapper(...)
  :call call('merge_requests#initCommits',a:000)  " a normal call would pack the a:000 list into another list
  :call merge_requests#listModFiles(s:start_commit,s:end_commit)
  :call merge_requests#showDiff(s:start_commit,s:end_commit)
endfunction

"--------------------------------------------
" Get the list of affected files in the diff
"--------------------------------------------
function! merge_requests#listFiles(start,end)
  :let l:list=systemlist('git diff --name-only '.a:start.'..'.a:end)
  :let s:list_files = copy(l:list)
endfunction

"--------------------------------------------
" Display the stats of the merge request diff
"--------------------------------------------
function! merge_requests#listModFiles(start,end)
  :call merge_requests#listFiles(a:start,a:end)
  :call setqflist(map(s:list_files,{_, p -> {'filename': p}}),'r')
endfunction

"--------------------------------------------
" Open the two versions of the file
"--------------------------------------------
" Requires fugitive
function! merge_requests#openFileToDiff(start,end)
  :call merge_requests#listFiles(a:start,a:end)
  let l:isInList=0
  for i in range(0,len(s:list_files)-1)
    if s:list_files[i] == expand('%:.')
      :let l:isInList=1
      :break
    endif
  endfor

  :let l:fname = expand('%:.')
  if l:isInList==1
    :execute ':Gedit '.a:start.':%'
    :execute ':Gdiff '.a:end
    if s:three_ways
      :execute 'vert sb '.l:fname
      :diffthis
    endif
  endif
endfunction

"--------------------------------------------
" Open diffs of a given file using the defined hashes
"--------------------------------------------
function! merge_requests#testCommitsDefined()
  :let l:unset=0

  " Do we have a start commit?
  if 0 == exists('s:start_commit')
    :let s:start_commit = 'master'
    :let l:unset=1
  endif

  " Do we have a end commit?
  if 0 == exists('s:end_commit')
    :let s:end_commit = 'HEAD'
    :let l:unset=1
  endif

  " If we changed anything, we update the list
  if l:unset
    :call merge_requests#listModFiles(s:start_commit, s:end_commit)
  endif
endfunction

"--------------------------------------------
" Open diffs of a given file using the defined hashes
"--------------------------------------------
function! merge_requests#openFileDiffs()
  :call merge_requests#testCommitsDefined()
  :call merge_requests#openFileToDiff(s:start_commit,s:end_commit)
endfunction

"--------------------------------------------
" Open the first file in the list
"--------------------------------------------
function! merge_requests#openFirstFile()
  :call merge_requests#testCommitsDefined()
  :only
  :crewind
  :call merge_requests#openFileToDiff(s:start_commit,s:end_commit)
endfunction

"--------------------------------------------
" Open the next file in the list
"--------------------------------------------

function! merge_requests#openNextFile()
  :call merge_requests#testCommitsDefined()
  :only
  :cnext
  :call merge_requests#openFileToDiff(s:start_commit,s:end_commit)
endfunction

"--------------------------------------------
" Commands
"-------------------------------------------
  """
  " Initiate a merge request review
  """
:command! -nargs=* CRDiff     :call merge_requests#showDiffWrapper(<f-args>)

  """
  " Compare the two versions of the current file
  """
:command! -nargs=0 CRFileDiff :call merge_requests#openFileDiffs()

  """
  " Show the diff of the first file in the quicklist
  """
:command! -nargs=0 CRFirst    :call merge_requests#openFirstFile()

  """
  " Pick the next differing file in the quicklist
  """
:command! -nargs=0 CRNext     :call merge_requests#openNextFile()

  """
  " Pick a file to review
  """
:command! -nargs=0 CRPick     :call merge_requests#showList(0,0)

  """
  " Display the currently selected commits
  """
:command! -nargs=0 CRVersions :execute ':echo "git diff '.s:start_commit.'..'.s:end_commit.'"'
