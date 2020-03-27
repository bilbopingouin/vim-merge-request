# vim-merge-request

Utilities to facilitate the local code review for merge requests.

## Intended use

Github and gitlab have nice tools to do some code reviewing for merge requests. However, why go to a browser, if one could stay at home in vim?

## Commands

This revolves (currenty) around two simple commands: 

- `:CRDiff` shows the statistics of the diff (to see the files which have been modified), and populate the quickfix list (to move around the files).
  It can be called using 
  - `:CRDiff master HEAD`
  - `:CRDiff master`
  - `:CRDiff`
  If not specified, it would take the default values (master and HEAD), but other commits could be specified (note that it does not require to be on of those commits).
- `:CRFileDiff` after jumping to one of the file from the quicklist, it will call `:Gedit` and `:Gdiff` to display the vimdiff for the specific file. Note that for the two diffed commits, it will either use the default values, or the values used in the previous command.

## Requirements

This requires the [fugitive](tpope/vim-fugitive) plugin as well as a functioning `git`.

## Extension

A possible extension could be a note taking plugin like [note for file](bilbopingouin/vim-notes-for-file).
