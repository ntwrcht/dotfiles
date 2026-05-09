"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => lazy.nvim
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader = ","
let maplocalleader = ","
let g:loaded_perl_provider = 0
let g:loaded_ruby_provider = 0
let g:python3_host_prog = expand('~/.local/share/nvim/python-provider/bin/python')

lua << EOF
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "Yggdroot/indentLine" },
  { "voldikss/vim-floaterm" },
  { "tpope/vim-commentary" },
  { "neoclide/coc.nvim", branch = "release" },
  { "vim-airline/vim-airline" },
  { "vim-airline/vim-airline-themes" },
  { "gko/vim-coloresque" },
  { "editorconfig/editorconfig-vim" },
  { "mg979/vim-visual-multi" },
  { "christoomey/vim-tmux-navigator" },
  { "airblade/vim-gitgutter" },
  { "instant-markdown/vim-instant-markdown", ft = "markdown" },
  { "tpope/vim-fugitive" },
  { "aklt/plantuml-syntax" },
  { "tyru/open-browser.vim" },
  { "weirongxu/plantuml-previewer.vim" },
  { "pangloss/vim-javascript" },
  { "leafgarland/typescript-vim" },
  { "maxmellon/vim-jsx-pretty" },
  { "jparise/vim-graphql" },
  { "peitalin/vim-jsx-typescript" },
  { "prettier/vim-prettier", build = "yarn install --frozen-lockfile --production" },
  { "darrikonn/vim-gofmt", build = ":GoUpdateBinaries" },
  { "leafOfTree/vim-vue-plugin" },
  { "madox2/vim-ai" },
}, {
  install = { colorscheme = { "xcode_dark", "habamax" } },
  checker = { enabled = false },
  rocks = { enabled = false },
})
EOF

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
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

nnoremap <silent> <leader>d :FloatermNew nnn -deH<cr>
nnoremap <silent> <leader>r :FloatermNew rg .<cr>
nnoremap <silent> <leader>g :FloatermNew lazygit<cr>
nnoremap <silent> <leader>f :FloatermNew fzf<cr>

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
" => VIM AI
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:vim_ai_roles_config_file = '~/roles.ini'

let g:vim_ai_edit = {
\  "options": {
\    "model": "gpt-4.1-mini",
\    "stream": 0,
\    "temperature": 1,
\    "max_completion_tokens": 25000,
\    "initial_prompt": "",
\  },
\}

let g:vim_ai_chat = {
\  "options": {
\    "model": "gpt-4.1-mini",
\    "stream": 0,
\    "temperature": 1,
\    "max_completion_tokens": 25000,
\    "initial_prompt": "",
\  },
\}

xnoremap <leader>c :AIChat<CR>
nnoremap <leader>c :AIChat<CR>

nnoremap <leader>re :AIRedo<CR>
nnoremap <leader>cm :GitCommitMessage<CR>

" custom command suggesting git commit message, takes no arguments
function! GitCommitMessageFn()
  let l:range = 0
  let l:diff = system('git diff HEAD')
  let l:prompt = "Hey, I just made some code changes. Here’s the diff. Can you suggest a short, clear commit message for it?\n" . l:diff
  let l:config = {
  \  "engine": "chat",
  \  "options": {
  \    "model": "gpt-4.1-mini",
  \    "initial_prompt": ">>> system\nYou are experienced in software development. Generate a concise git commit message from the diff provided below. Write it in a clean and concise way so that the team can clearly understand the commit more easily. The output should be a conventional commit pattern.",
  \    "temperature": 1,
  \  }
  \}
  call vim_ai#AIRun(l:range, l:config, l:prompt)
endfunction
command! GitCommitMessage call GitCommitMessageFn()

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

inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
inoremap <silent><expr> <C-x><C-z> coc#pum#visible() ? coc#pum#stop() : "\<C-x>\<C-z>"
" remap for complete to use tab and <cr>
inoremap <silent><expr> <TAB>
    \ coc#pum#visible() ? coc#pum#next(1):
    \ <SID>check_back_space() ? "\<Tab>" :
    \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <silent><expr> <c-space> coc#refresh()

hi CocSearch ctermfg=12 guifg=#18A3FF
hi CocMenuSel ctermbg=109 guibg=#13354A
