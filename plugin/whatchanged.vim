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
  hi low_complexity guifg=#004400 guibg=#004400
  hi medium_complexity guifg=#bbbb00 guibg=#bbbb00
  hi high_complexity guifg=#ff2222 guibg=#ff2222
  :exe ":silent sign place 2 line=" . a:line . " name=medium_complexity buffer=" . a:current_buffer
endfunction

" Remove all signs
function! s:RemoveSigns(current_buffer)
ruby << EOF
  VIM::command('redir => s:complexity_sign_list')
  VIM::command("silent sign place buffer=#{current_buffer}")
  VIM::command('redir END')

  sign_list = VIM::evaluate('s:complexity_sign_list')
  signs = sign_list.strip.split("\n")
  signs = signs.select{|s| s.include?("=")}

  # will be an array with linenumbers that have signs, not used at the moment
  # but can be usefull in the future
  numbers = []
  signs.each do |sign|
    # get start of next line so we know when to stop
    id = sign.match(/id/).begin(0)

    # filter out all non-digits
    numbers << sign[0...id].gsub(/\D/, "").to_i
  end

  # loop through the buffer and remove every sign
  numbers.size.times do |i|
    VIM::command("sign unplace 2 buffer=#{current_buffer}")
  end
EOF
endfunction

" Show changes in current file
function! s:ShowChanges()
ruby << EOF
  current_buffer = VIM::Buffer.current.number

  VIM::command("call s:RemoveSigns(#{current_buffer})")

  current_file = VIM::evaluate('expand("%:p")')
  lines = %x[git blame #{current_file} | grep "Not Committed" | cut -c 55-57]

  # filter out non-digits because files without many lines would output 5) for
  # example instead of 5
  # The matching pattern will need to be refactored.
  lines.split("\n").collect{|l| l.gsub(/\D/, "")}.each do |line|
    VIM::command("call s:AddSign(#{line}, #{current_buffer})")
  end
EOF
endfunction

command UpdateGitStatus :call <SID>ShowChanges()
