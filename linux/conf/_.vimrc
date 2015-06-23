"set viminfo=!,'25,\"100,:20,%,n~/.viminfo

syntax on
set shiftwidth=4
set ts=4
let c_space_errors=1
set hlsearch
map <F1> :tabnew

set history=50          " keep 50 lines of command line history
set ruler               " show the cursor position all the time
set showcmd             " display incomplete commands
set incsearch           " do incremental searching
set ignorecase
set smartcase
set smarttab

" for tmux
"set mouse=a
"set ttymouse=xterm

" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = ","
let g:mapleader = ","

colorscheme koehler

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" Highlight spaces
"":highlight ExtraWhitespace ctermbg=darkgreen guibg=lightgreen
"":match ExtraWhitespace /\s\+\%#\@<!$/

" Source : http://vim.wikia.com/wiki/VimTip1274
" Highlight whitespace problems.
" flags is '' to clear highlighting, or is a string to
" specify what to highlight (one or more characters):
"   e  whitespace at end of line
"   i  spaces used for indenting
"   s  spaces before a tab
"   t  tabs not at start of line
function! ShowWhitespace(flags)
  let bad = ''
  let pat = []
  for c in split(a:flags, '\zs')
    if c == 'e'
      call add(pat, '\s\+$')
    elseif c == 'i'
      call add(pat, '^\t*\zs \+')
    elseif c == 's'
      call add(pat, ' \+\ze\t')
    elseif c == 't'
      call add(pat, '[^\t]\zs\t\+')
    else
      let bad .= c
    endif
  endfor
  if len(pat) > 0
    let s = join(pat, '\|')
    exec 'syntax match ExtraWhitespace "'.s.'" containedin=ALL'
  else
    syntax clear ExtraWhitespace
  endif
  if len(bad) > 0
    echo 'ShowWhitespace ignored: '.bad
  endif
endfunction

function! ToggleShowWhitespace()
  if !exists('b:ws_show')
    let b:ws_show = 0
  endif
  if !exists('b:ws_flags')
    let b:ws_flags = 'est'  " default (which whitespace to show)
  endif
  let b:ws_show = !b:ws_show
  if b:ws_show
    call ShowWhitespace(b:ws_flags)
  else
    call ShowWhitespace('')
  endif
endfunction

nnoremap <Leader>ws :call ToggleShowWhitespace()<CR>
highlight ExtraWhitespace ctermbg=darkgreen guibg=darkgreen

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" 
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


" " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " "
" allow backspacing over everything in insert mode
set backspace=indent,eol,start
set whichwrap+=<,>,h,l

" " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " "
" Only do this part when compiled with support for autocommands.
if has("autocmd")

	" Call function when character ':' is founded
	autocmd! BufNewFile *:* nested call s:gotoline()

	" In text files, always limit the width of text to 78 characters
	autocmd BufRead *.txt set tw=78

	" When editing a file, always jump to the last known cursor position.
	" Don't do it when the position is invalid or when inside an event handler
	" (happens when dropping a file on gvim).
	autocmd BufReadPost *
				\ if line("'\"") > 0 && line("'\"") <= line("$") |
				\   exe "normal g`\"" |
				\ endif

endif " has("autocmd")

set autoindent                " always set autoindenting on
" Enable file type detection.
" Use the default filetype settings, so that mail gets 'tw' set to 72,
" 'cindent' is on in C files, etc.
" Also load indent files, to automatically do language-dependent indenting.
filetype plugin indent on



" Always show the status line
set laststatus=2

" Format the status line
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ L:%l\ C:%c



" Don't redraw while executing macros (good performance config)
set lazyredraw
" For regular expressions turn magic on
set magic


" Returns true if paste mode is enabled
function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    en
    return ''
endfunction

" Disable highlight when <leader><cr> is pressed
map <silent> <leader><cr> :noh<cr>

" Remove the Windows ^M - when the encodings gets messed up
noremap <Leader>m mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm

" Toggle paste mode on and off
map <leader>pp :setlocal paste!<cr>
" Enter Insert Mode with paste mode on
map <leader>pi :setlocal paste<cr>i
map <leader>nu :set nu! <CR>

" Delete trailing white space
map <leader>sd :%s/\s\+$//ge<CR>
map <leader>st :%s/^\([\t]*\)    /\1\t/ge<CR>

