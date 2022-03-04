"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => VIM Plug
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin('~/.vim/plugged')
Plug 'Yggdroot/indentLine'
Plug 'voldikss/vim-floaterm'
Plug 'tpope/vim-commentary'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'editorconfig/editorconfig-vim'
Plug 'mg979/vim-visual-multi'
Plug 'christoomey/vim-tmux-navigator'
Plug 'airblade/vim-gitgutter'
Plug 'instant-markdown/vim-instant-markdown', {'for': 'markdown'}
Plug 'tpope/vim-fugitive'
Plug 'aklt/plantuml-syntax'
Plug 'tyru/open-browser.vim'
Plug 'weirongxu/plantuml-previewer.vim'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'leafgarland/typescript-vim'
Plug 'peitalin/vim-jsx-typescript'
Plug 'prettier/vim-prettier', { 'do': 'yarn install' }
call plug#end()

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader = ","
let maplocalleader = ","
set updatetime=200
set timeoutlen=1000 ttimeoutlen=50
set history=10000
set undofile
set hidden
set undolevels=100
set undoreload=1000
set nobackup
set nowritebackup
set noundofile
set nowrap
set noswapfile
set nocursorline
set shortmess+=c

" interface
set so=8
set number
set numberwidth=8
set signcolumn=yes
set tabstop=4
set shiftwidth=4
set expandtab
set textwidth=161
set colorcolumn=161
set cursorline

" completion
set cmdheight=1
set pumheight=8
set completeopt=menuone,noinsert,noselect

" clipboard
set clipboard^=unnamed,unnamedplus

" last line history
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

noremap! <C-h> <Left>
noremap! <C-j> <Down>
noremap! <C-k> <Up>
noremap! <C-l> <Right>
nnoremap tn :tabnew<CR>

" Go to tab by number
noremap <leader>1 1gt
noremap <leader>2 2gt
noremap <leader>3 3gt
noremap <leader>4 4gt
noremap <leader>5 5gt
noremap <leader>6 6gt
noremap <leader>7 7gt
noremap <leader>8 8gt
noremap <leader>9 9gt
noremap <leader>0 :tablast<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Theme
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:github_colors_soft = 1

set background=dark
set termguicolors

colorscheme xcode_dark

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => FloatTerm
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
hi Floaterm guibg=#222222
hi FloatermBorder guibg=#222222 guifg=#3A3A3A

let g:floaterm_opener = "tabe"
let g:floaterm_autoclose = 2
let g:floaterm_width = 0.8
let g:floaterm_height = 0.8
let g:floaterm_complete_options = {'shortcut': 'floaterm', 'priority': 5, 'filter_length': [5, 20]}
let g:floaterm_wintype = "float"

nnoremap <silent> <leader>d :FloatermNew nnn -de<cr>
nnoremap <silent> <leader>r :FloatermNew rg<cr>
nnoremap <silent> <leader>g :FloatermNew lazygit<cr>
nnoremap <silent> <leader>f :FloatermNew fzf<cr>
nnoremap <silent> <leader>p :FloatermNew ipython<cr>
nnoremap <silent> <leader>q :FloatermNew googler<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Prettier
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap <Leader>py <Plug>(Prettier)

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Git Gutter
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
hi GitGutterAddLineNr          guibg=#DEFFCD guifg=#505050 ctermfg=2
hi GitGutterChangeLineNr       guibg=#FBFFCD guifg=#505050 ctermfg=3
hi GitGutterDeleteLineNr       guibg=#FFD8CB guifg=#505050 ctermfg=1
hi GitGutterChangeDeleteLineNr guibg=#FBFFCD guifg=#505050 ctermfg=3

hi GitGutterAdd		       guibg=#B4FFB2 guifg=#505050 ctermfg=2
hi GitGutterChange 	       guibg=#F9FFB2 guifg=#505050 ctermfg=3
hi GitGutterDelete 	       guibg=#FFBBA6 guifg=#505050 ctermfg=1
hi GitGutterChangeDeleteLine   guibg=#F9FFB2 guifg=#505050 ctermfg=3

let g:gitgutter_signs = 1
let g:gitgutter_set_sign_backgrounds = 0
let g:gitgutter_enabled = 1
let g:gitgutter_highlight_lines = 0
let g:gitgutter_highlight_linenrs = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Visual Multi
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:VM_leader = '\'
let g:VM_theme = "olive"
let g:VM_maps = {}
let g:VM_maps["Select All"]        = '<leader>a'
let g:VM_maps["Visual All"]        = '<leader>a'
let g:VM_maps["Align"]             = '<leader>A'
let g:VM_maps["Add Cursor Down"]   = '<C-Down>'
let g:VM_maps["Add Cursor Up"]     = '<C-Up>'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Airline
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:airline_theme = "alduin"
let g:airline_extensions = ['tabline', 'coc', 'fugitiveline', 'wordcount', 'branch']
let g:airline_highlighting_cache = 1
let g:airline_powerline_fonts = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline#extensions#tabline#show_splits = 0
let g:airline#extensions#tabline#tab_min_count = 0
let g:airline#extensions#tabline#show_close_button = 0
let g:airline#extensions#tabline#tab_nr_type = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Tmux
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <silent> <C-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <C-j> :TmuxNavigateDown<cr>
nnoremap <silent> <C-k> :TmuxNavigateUp<cr>
nnoremap <silent> <C-l> :TmuxNavigateRight<cr>
nnoremap <silent> <C-\> :TmuxNavigatePrevious<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => COC VIM
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set shortmess+=c
let g:coc_global_extensions = [
            \'coc-tsserver',
            \'coc-clangd',
            \'coc-python',
            \'coc-go',
            \'coc-emmet',
            \'coc-html',
            \'coc-css',
            \'coc-prettier',
            \'coc-json',
            \'coc-docker',
            \'coc-markdownlint',
            \'coc-sh',
            \'coc-vetur',
            \]

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction

" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : <SID>check_back_space() ? "\<TAB>" : coc#refresh()
inorem<SID>check_ap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" Use `[g` and `]g` to navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation.
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <leader> ac <Plug>(coc-codeaction)
nmap <leader> qf <Plug>(coc-fix-current)

inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm(): "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

nnoremap <nowait><expr> <C-f> coc#float#has_scroll() ? coc#float#scroll(1) : "\<C-f>"
nnoremap <nowait><expr> <C-b> coc#float#has_scroll() ? coc#float#scroll(0) : "\<C-b>"
inoremap <nowait><expr> <C-f> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(1)\<cr>" : "\<Right>"
inoremap <nowait><expr> <C-b> coc#float#has_scroll() ? "\<c-r>=coc#float#scroll(0)\<cr>" : "\<Left>"

command! -nargs=0 Format :call CocAction('format')
command! -nargs=? Fold :call CocAction('fold', <f-args>)
command! -nargs=0 OR   :call CocAction('runCommand', 'editor.action.organizeImport')

set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
