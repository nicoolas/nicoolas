"set viminfo=!,'25,\"100,:20,%,n~/.viminfo

syntax on
set shiftwidth=4
set ts=4
let c_space_errors=1
set hlsearch
map <F1> :tabnew
"set nu

set history=50          " keep 50 lines of command line history
set ruler               " show the cursor position all the time
set showcmd             " display incomplete commands
set incsearch           " do incremental searching
set ignorecase
set smartcase

" for tmux
"set mouse=a
"set ttymouse=xterm


" " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " "
" Function to allow to go to line number when a file is open
function! s:gotoline()
    let file = bufname("%")
    let names =  matchlist( file, '\(.*\):\(\d\+\)')

    if len(names) != 0 && filereadable(names[1])
        let l:bufn = bufnr("%")
        exec ":e " . names[1]
        exec ":" . names[2]
        exec ":bdelete " . l:bufn
        if foldlevel(names[2]) > 0
            exec ":foldopen!"
        endif
    endif
endfunction
" Call function when character ':' is founded
autocmd! BufNewFile *:* nested call s:gotoline()


" " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " "
" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " "
" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " In text files, always limit the width of text to 78 characters
  autocmd BufRead *.txt set tw=78
 
  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

set autoindent                " always set autoindenting on

colorscheme koehler

endif " has("autocmd")
