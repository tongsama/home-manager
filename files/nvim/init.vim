" nvim-from-vim: https://neovim.io/doc/user/nvim.html#nvim-from-vim
"
" vim と nvim で設定を共存させる。
" ~/.vim を runtimepath / packpath に足し、~/.vimrc (= files/vim/dotvimrc) を source する。
" dotvimrc 側には has('nvim') の分岐があり、nvim 固有設定はそこで処理される。
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
