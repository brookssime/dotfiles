set nocompatible 
filetype off    

set number      "show line numbers
set backspace=indent,eol,start  "Allow backspace in insert mode
set history=1000
set autoread     "Reload files changed outside vim

" Wildmenu and wildmode makes file completion behave like in the shell,
" autocomplete to the point of ambiguity and show other options
set wildmenu
set wildmode=list:longest


set hidden "Vim needs this to manage multiple buffers effectively

"turn on syntax highlighting
syntax on


let mapleader = ","



" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'preservim/nerdtree'
Plugin 'tpope/vim-surround'
Plugin 'w0rp/ale'
Plugin 'valloric/youcompleteme'
Plugin 'vim-airline/vim-airline'
Plugin 'eliba2/vim-node-inspect'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled = 1
nnoremap <F2> :NERDTree<CR>
nnoremap <F3> :NERDTreeToggle<CR>
nnoremap <F4> :NERDTreeClose<CR>
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif
