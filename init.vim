call plug#begin('~/.config/nvim')

Plug 'dracula/vim',{'as':'dracula'}
Plug 'terryma/vim-multiple-cursors'
Plug 'sheerun/vim-polyglot'
Plug 'junegunn/fzf',{ 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', { 'branch': 'master', 'do': 'yarn install --frozen-lockfile'}
let g:coc_global_extensions = ['coc-tslint-plugin', 'coc-tsserver', 'coc-css', 'coc-html', 'coc-json', 'coc-prettier', 'coc-styled-components']
Plug 'jiangmiao/auto-pairs'
Plug 'yuezk/vim-js'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'preservim/nerdtree'

" Plug 'ncm2/ncm2'

call plug#end()

autocmd VimEnter * NERDTree
autocmd StdinReadPre * let s:std_in=1
autocmd Vimenter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

colorscheme dracula
set background=dark

set hidden
set number
set relativenumber
set mouse=a
set inccommand=split
set encoding=utf8

let mapleader="\<space>"
nnoremap <leader>; A;<esc>
nnoremap <leader>ev :vsplit ~/.config/nvim/init.vim<cr>
nnoremap <leader>sv :source ~/.config/nvim/init.vim<cr>

nnoremap <c-p> :GFiles<cr>
nnoremap <c-f> :Ag<space>

nnoremap <c-b> :NERDTreeToggle<cr>
nnoremap <leader>f :NERDTreeFocus<cr>
