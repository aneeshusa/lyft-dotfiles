set termguicolors
colorscheme slate
set number
set relativenumber
set ruler
set wildmode=list:full
map q <Nop>
set scrolloff=1
set sidescrolloff=5
set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
set list
set showcmd
set foldmethod=indent
set foldenable
set foldlevelstart=10
set foldnestmax=10
set expandtab

" Syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_aggregate_errors = 1

autocmd BufWriteCmd *.html,*.css,*.adoc :call Refresh_firefox()
function! Refresh_firefox()
  if &modified
    write
    silent !echo  'vimYo = content.window.pageYOffset;
          \ vimXo = content.window.pageXOffset;
          \ BrowserReload();
          \ content.window.scrollTo(vimXo,vimYo);
          \ repl.quit();'  |
          \ @netcat@ -w 1 localhost 4242 2>&1 > /dev/null
  endif
endfunction
