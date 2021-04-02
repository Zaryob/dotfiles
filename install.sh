if [ ! -f "$HOME/.zaryob" ]; then
    echo "Installing Zaryob's dotfiles."
    git clone --depth=1 https://github.com/Zaryob/dotfiles.git "$HOME/.dotfiles"
    cd "$HOME/.dotfiles"
    printf "\033[0;31m* Setting shells.\033[0m\n"
    ln -svf $HOME/.dotfiles/shell/aliases $HOME/.aliases
    ln -svf $HOME/.dotfiles/shell/inputrc $HOME/.inputrc
    printf "\033[0;33m - Generating bash links\033[0m\n"
    ln -svf $HOME/.dotfiles/shell/bash/bash_logout $HOME/.bash_logout
    ln -svf $HOME/.dotfiles/shell/bash/bashrc $HOME/.bashrc
    ln -svf $HOME/.dotfiles/shell/bash/profile $HOME/.profile
    printf "\033[0;32m + Linked bash configs\033[0m\n"
    printf "\033[0;33m - Generating zsh links\033[0m\n"
    ln -svf $HOME/.dotfiles/shell/zsh/zshrc $HOME/.zshrc
    ln -svf $HOME/.dotfiles/shell/zsh/zlogout $HOME/.zlogout
    ln -svf $HOME/.dotfiles/shell/zsh/zprofile $HOME/.zprofile
    printf "\033[0;32m + Linked bash configs\033[0m\n"
    printf "\033[0;33m - Installing vim plugins\033[0m\n"
    [ -f $HOME/.vim ] || rm -rf $HOME/.vim
    [ -f $HOME/.cache/vim ] || rm -rf $HOME/.cache/vim
    mkdir -vp $HOME/.cache/vim
    mkdir -vp $HOME/.vim/pack/default/start
    bash $HOME/.dotfiles/editors/vim/gruvbox_ins.sh
    printf "\033[0;32m + Installed vim plugins\033[0m\n"
    printf "\033[0;33m - Installing emacs config\033[0m\n"
    [ -f $HOME/.emacs.d ] || rm -rf $HOME/.emacs.d
    ln -svf $HOME/.dotfiles/editors/emacs $HOME/.emacs.d
    printf "\033[0;33m + emacs config made\033[0m\n"
    printf "\033[0;33m - Generating vim links\033[0m\n"
    ln -svf $HOME/.dotfiles/editors/vim/vimrc $HOME/.vimrc
    printf "\033[0;32m + Linked vim configs\033[0m\n"
    printf "\033[0;33m - Copying fonts\033[0m\n"
    [ -f $HOME/.fonts ] || rm -rf $HOME/.fonts
    mkdir -v $HOME/.fonts
    cp -vf $HOME/.dotfiles/fonts/* $HOME/.fonts
    printf "\033[0;32m + Copied fonts\033[0m\n"
#    printf "\033[0;33m - Setting conky up\033[0m\n"
#    ln -svf $HOME/.dotfiles/conky/conkyrc $HOME/.conkyrc
#    printf "\033[0;32m + Conky setted\033[0m\n"
    printf "\033[0;33m - Setting i3wm up\033[0m\n"
    ln -svf $HOME/.dotfiles/i3-themes/simplicity/compton.conf $HOME/.config
    [ -f $HOME/.config/i3 ] || rm -rf $HOME/.config/i3
    [ -f $HOME/.config/clipit ] || rm -rf $HOME/.config/clipit
    ln -svf $HOME/.dotfiles/i3-themes/simplicity/config/clipit  $HOME/.dotfiles/i3-themes/simplicity/config/i3  $HOME/.config/
    ln -svf $HOME/.dotfiles/i3-themes/simplicity/fehbg $HOME/.fehbg
    printf "\033[0;32m + i3wm setted up\033[0m\n"
    printf "\033[0;33m - Initializing tmux \033[0m\n"
    ln -svf $HOME/.dotfiles/shell/tmux/tmux.conf $HOME/.tmux.conf
    ln -svf $HOME/.dotfiles/shell/tmux/tmux-themepack $HOME/.tmux-themepack
    printf "\033[0;32m + tmux setted up\033[0m\n"
#    printf "\033[0;33m - Initializing fish \033[0m\n"
#    [ -f $HOME/.config/fish ] || rm -rf $HOME/.config/fish
#    [ -f $HOME/.local/share/fish/generated_completions ] || rm -rf $HOME/.local/share/fish/generated_completions
#    ln -sv $HOME/.dotfiles/shell/fish  $HOME/.config/fish
#    ln -sv $HOME/.dotfiles/share/fish_generated_scripts $HOME/.local/share/fish/generated_completions
#    printf "\033[0;32m + fish setted up\033[0m\n"
    printf "\033[0;33m - Initializing git \033[0m\n"
    mkdir -pv $HOME/.local/share/man/man1
    ln -svf $HOME/.dotfiles/git/man/ $HOME/.local/share/man/man1
    ln -svf $HOME/.dotfiles/git/commands $HOME/.gitbin
    ln -svf $HOME/.dotfiles/git/gitconfig $HOME/.gitconfig
    ln -svf $HOME/.dotfiles/git/gitmessage $HOME/.gitmessage
    printf "\033[0;32m + Initialized git \033[0m\n"
    printf "\033[0;33m - Initializing Xorg extras \033[0m\n"
    ln -svf  $HOME/.dotfiles/Xorg/xinitrc $HOME/.xinitrc
    ln -svf $HOME/.dotfiles/Xorg/xserverrc $HOME/.xserverrc
    ln -svf $HOME/.dotfiles/Xorg/Xdefaults $HOME/.Xdefaults
    ln -svf $HOME/.dotfiles/Xorg/Xresources $HOME/.Xresources
    printf "\033[0;32m + Initialized Xorg extras \033[0m\n"
    printf "\033[0;33m - Initializing Extra Configs \033[0m\n"
    ln -svf $HOME/.dotfiles/extras/mc $HOME/.config
    ln -svf $HOME/.dotfiles/extras/oomox $HOME/.config
    ln -svf $HOME/.dotfiles/extras/ncmpcpp $HOME/.ncmpcpp
    ln -svf $HOME/.dotfiles/extras/mpd $HOME/.mpd
    ln -svf $HOME/.dotfiles/extras/nitrogen $HOME/.config
    ln -svf $HOME/.dotfiles/extras/kitty $HOME/.config
    ln -svf $HOME/.dotfiles/extras/neofetch $HOME/.config
    printf "\033[0;32m + Initialized Extra Configs \033[0m\n"
    printf "YOU CAN RUN OUT :-)\n"
    touch $HOME/.zaryob
else
    echo "Zaryobizing was already made."
fi
