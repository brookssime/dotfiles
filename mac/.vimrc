set nocompatible
filetype plugin indent on
syntax on

set number
set relativenumber
set backspace=indent,eol,start  "Allow backspace in insert mode
set history=10000
set autoread                    "Reload files changed outside vim
set hidden                      "Vim needs this to manage multiple buffers effectively

" Wildmenu and wildmode makes file completion behave like in the shell,
" autocomplete to the point of ambiguity and show other options
set wildmenu
set wildmode=list:longest

set hlsearch
set incsearch

set clipboard=unnamed

let mapleader="\<Space>"

let g:netrw_liststyle = 3
let g:netrw_banner = 0
let g:netrw_winsize = 25
let g:netrw_browse_split = 4

nnoremap <F2> :Lexplore<CR>
nnoremap <Leader>f :Lexplore<CR>

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | Explore | endif

" --- Ported from the Neovim config (lua/plugins/astrocore.lua) ---
" Copied once, deliberately not kept in sync. Edit either side freely.

" Buffer navigation
nnoremap ]b :bnext<CR>
nnoremap [b :bprevious<CR>
nnoremap <Leader>bd :bdelete<CR>

" Move 5 lines at a time. In visual mode this shadows J (join); use gJ or :join
nnoremap K 5k
nnoremap J 5j
xnoremap K 5k
xnoremap J 5j

" No arrow keys
nnoremap <Up> <Nop>
nnoremap <Down> <Nop>
nnoremap <Right> <Nop>
nnoremap <Left> <Nop>
inoremap <Up> <Nop>
inoremap <Down> <Nop>
inoremap <Right> <Nop>
inoremap <Left> <Nop>

" Black-hole deletes so they never clobber the unnamed register. <Leader>D
" re-exposes the real cutting operator (<Leader>Dd cuts a line, because the
" second d lands in operator-pending mode, which these maps don't touch)
nnoremap d "_d
nnoremap D "_D
nnoremap x "_x
nnoremap X "_X
nnoremap c "_c
nnoremap C "_C
nnoremap <Leader>D d

xnoremap d "_d
xnoremap x "_x
xnoremap c "_c
xnoremap <Leader>D d

" Paste over a selection without swallowing the register
xnoremap p P
