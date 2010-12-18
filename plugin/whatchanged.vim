" whatchanged.vim
" by Mark Mulder markmulder@gmail.com
" https://github.com/bittersweet/vim-whatchanged
"
" This shows annotations next to your source code for changed and added lines
"
" Borrowed heavily from Gary Bernhardts pycomplexity script
" https://github.com/garybernhardt/pycomplexity/

if !has('signs')
  finish
endif

" Sign colors and settings
hi SignColumn guifg=fg guibg=bg
hi low_complexity guifg=#004400 guibg=#004400
hi medium_complexity guifg=#bbbb00 guibg=#bbbb00
hi high_complexity guifg=#ff2222 guibg=#ff2222
sign define low_complexity text=XX texthl=low_complexity
sign define medium_complexity text=XX texthl=medium_complexity
sign define high_complexity text=XX texthl=high_complexity

" Place signs
function! s:AddSign(line, current_buffer)
  :exe ":silent sign place 2 line=" . a:line . " name=medium_complexity buffer=" . a:current_buffer
endfunction

" Remove all signs
function! s:RemoveSigns(current_buffer)
  :exe ":sign unplace " . a:current_buffer
endfunction

" Show changes in current file
function! s:ShowChanges()
ruby << EOF

  current_buffer = VIM::Buffer.current.number

  VIM::command("call s:RemoveSigns(#{current_buffer})")

  current_file = VIM::evaluate('expand("%:p")')
  # Currently only works in the directory where vim was started
  lines = %x[git blame #{current_file} | grep "Not Committed" | cut -c 55-56]

  lines.split("\n").each do |line|
    VIM::command("call s:AddSign(#{line}, #{current_buffer})")
  end
EOF
endfunction

command UpdateGitStatus :call <SID>ShowChanges()
" command RemoveAllSigns :call <SID>RemoveSigns()
nmap <silent> <Leader>k :UpdateGitStatus<CR>
