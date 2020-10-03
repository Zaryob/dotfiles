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
    printf "\033[0;33m - Generating vim links\033[0m\n"
    ln -svf $HOME/.dotfiles/editors/vim/vimrc $HOME/.vimrc
    printf "\033[0;32m + Linked vim configs\033[0m\n"
    printf "\033[0;33m - Copying fonts\033[0m\n"
    [ -f $HOME/.fonts ] || rm -rf $HOME/.fonts
    mkdir -v $HOME/.fonts
    cp -vf $HOME/.dotfiles/fonts/* $HOME/.fonts
    printf "\033[0;32m + Copied fonts\033[0m\n"
    printf "\033[0;33m - Setting i3wm up\033[0m\n"
    [ -f $HOME/.config/i3 ] || rm -rf $HOME/.config/i3
    mkdir -v $HOME/.config/i3
    ln -svf $HOME/.dotfiles/i3-themes/simplicity/config/clipit  $HOME/.dotfiles/i3-themes/simplicity/config/i3  $HOME/.config/i3
    
    ln -svf $HOME/.dotfiles/i3-themes/simplicity/fehbg $HOME/.fehbg
    printf "\033[0;32m + i3wm setted up\033[0m\n"
    printf "\033[0;33m - Initializing git \033[0m\n"
    mkdir -pv $HOME/.local/share/man/man1
    cp -vf $HOME/.dotfiles/git/man/man1/* $HOME/.local/share/man/man1
    [ -f $HOME/.git ] || rm -rf $HOME/.git
    mkdir -v $HOME/.git
    ln -svf $HOME/.dotfiles/git/commands $HOME/.git/commands
    ln -svf $HOME/.dotfiles/git/gitconfig $HOME/.gitconfig
    ln -svf $HOME/.dotfiles/git/gitmessage $HOME/.gitmessage
    printf "\033[0;32m + Initialized git \033[0m\n"
    printf "\033[0;33m - Initializing Xorg extras \033[0m\n"
    [ -f $HOME/.wallpapers ] || rm -rf $HOME/.wallpapers
    mkdir $HOME/.wallpapers
    cp ./wallpapers/* $HOME/.wallpapers/
    ln -svf $HOME/.dotfiles/Xorg/xsession $HOME/.xsession
    ln -svf $HOME/.dotfiles/Xorg/Xdefaults $HOME/.Xdefaults
    printf "\033[0;32m + Initialized Xorg extras \033[0m\n"
    printf "YOU CAN RUN OUT :-)\n"
    touch $HOME/.zaryob
else
    echo "Zaryobizing was already made."
fi
