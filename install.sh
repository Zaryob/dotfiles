#! /bin/sh

## DIALOG variables
: "${DIALOG=dialog}"

: "${DIALOG_OK=0}"
: "${DIALOG_CANCEL=1}"
: "${DIALOG_HELP=2}"
: "${DIALOG_EXTRA=3}"
: "${DIALOG_ITEM_HELP=4}"
: "${DIALOG_TIMEOUT=5}"
: "${DIALOG_ESC=255}"

: "${SIG_NONE=0}"
: "${SIG_HUP=1}"
: "${SIG_INT=2}"
: "${SIG_QUIT=3}"
: "${SIG_KILL=9}"
: "${SIG_TERM=15}"

dotfile_install_parts () {
  if ([ $1 = "Emacs" ] || [ $1 = "Vim" ]) && ([ ! "$(ls -A $HOME/.dotfiles/editors/emacs/submodules/emms-player/)" ]  ||  [ ! "$(ls -A $HOME/.dotfiles/editors/vim/pack/default/start/gruvbox/)" ])
  then
    git submodule update --init --recursive --depth=1
  fi
  if ([ $1 = "Emacs" ]) && [ ! -f  $HOME/.dotfiles/editors/emacs/submodules/emms-player/emms-auto.el ]
  then
    cd $HOME/.dotfiles/editors/emacs/submodules/emms-player/
    make emms-auto.el
    cd $HOME/.dotfiles/
  fi
  if ([ $1 = "Emacs" ] || [ $1 = "Vim" ]) && [ ! -d $HOME/.fonts ]
  then
    printf "\033[0;33m - Copying fonts\033[0m\n"
    [ -f $HOME/.fonts ] || rm -rf $HOME/.fonts
    mkdir -v $HOME/.fonts
    cp -vf $HOME/.dotfiles/fonts/* $HOME/.fonts
    printf "\033[0;32m + Copied fonts\033[0m\n"
  fi
  if ([ $1 = "Bash" ] || [ $1 = "Zsh" ] ||  [ $1 = "Fish" ]) && [ ! -L $HOME/.aliases ]
  then
    printf "\033[0;31m* Setting shells.\033[0m\n"
    ln -svf $HOME/.dotfiles/shell/aliases $HOME/.aliases
    ln -svf $HOME/.dotfiles/shell/inputrc $HOME/.inputrc
  fi
  case "$1" in
  "Emacs")
    printf "\033[0;33m - Installing emacs config\033[0m\n"
    [ -f $HOME/.emacs.d ] || rm -rf $HOME/.emacs.d
    ln -svf $HOME/.dotfiles/editors/emacs $HOME/.emacs.d
    printf "\033[0;33m + emacs config made\033[0m\n"
    ;;
  "Vim")
    printf "\033[0;33m - Installing vim plugins\033[0m\n"
    [ -f $HOME/.vim ] || rm -rf $HOME/.vim
    [ -f $HOME/.cache/vim ] || rm -rf $HOME/.cache/vim
    mkdir -vp $HOME/.cache/vim
    mkdir -vp $HOME/.vim/pack/default/start
    ln -svf $HOME/.dotfiles/editors/vim/pack/default/start/gruvbox $HOME/.vim/pack/default/start/gruvbox
    printf "\033[0;32m + Installed vim plugins\033[0m\n"
    printf "\033[0;33m - Generating vim links\033[0m\n"
    ln -svf $HOME/.dotfiles/editors/vim/vimrc $HOME/.vimrc
    printf "\033[0;32m + Linked vim configs\033[0m\n"
    ;;
  "Bash")
    printf "\033[0;33m - Generating bash links\033[0m\n"
    ln -svf $HOME/.dotfiles/shell/bash/bash_logout $HOME/.bash_logout
    ln -svf $HOME/.dotfiles/shell/bash/bashrc $HOME/.bashrc
    ln -svf $HOME/.dotfiles/shell/bash/profile $HOME/.profile
    printf "\033[0;32m + Linked bash configs\033[0m\n"
    ;;
  "Zsh")
    printf "\033[0;33m - Generating zsh links\033[0m\n"
    ln -svf $HOME/.dotfiles/shell/zsh/zshrc $HOME/.zshrc
    ln -svf $HOME/.dotfiles/shell/zsh/zlogout $HOME/.zlogout
    ln -svf $HOME/.dotfiles/shell/zsh/zprofile $HOME/.zprofile
    printf "\033[0;32m + Linked zsh configs\033[0m\n"
    ;;
#  "Fish")
#    printf "\033[0;33m - Initializing fish \033[0m\n"
#    [ -f $HOME/.config/fish ] || rm -rf $HOME/.config/fish
#    [ -f $HOME/.local/share/fish/generated_completions ] || rm -rf $HOME/.local/share/fish/generated_completions
#    ln -sv $HOME/.dotfiles/shell/fish  $HOME/.config/fish
#    ln -sv $HOME/.dotfiles/share/fish_generated_scripts $HOME/.local/share/fish/generated_completions
#    printf "\033[0;32m + fish setted up\033[0m\n"
#    ;;
  "Tmux")
    printf "\033[0;33m - Initializing tmux \033[0m\n"
    ln -svf $HOME/.dotfiles/shell/tmux/tmux.conf $HOME/.tmux.conf
    ln -svf $HOME/.dotfiles/shell/tmux/tmux-themepack $HOME/.tmux-themepack
    printf "\033[0;32m + tmux setted up\033[0m\n"
    ;;
  "Git")
    printf "\033[0;33m - Initializing git \033[0m\n"
    mkdir -pv $HOME/.local/share/man
    ln -svf $HOME/.dotfiles/git/share/man $HOME/.local/share/man/man1
    ln -svf $HOME/.dotfiles/git/commands $HOME/.gitbin
    ln -svf $HOME/.dotfiles/git/gitconfig $HOME/.gitconfig
    ln -svf $HOME/.dotfiles/git/gitmessage $HOME/.gitmessage
    ln -svf $HOME/.dotfiles/git/share/license $HOME/.local/share/license
    printf "\033[0;32m + Initialized git \033[0m\n"
    ;;
  *)
    echo "Return code was $returncode";;
esac

   echo "(?) Parameter was $1"
}



### MAIN FUNCTION ###
if [ ! -f "$HOME/.zaryob" ]; then
    echo "Installing Zaryob's dotfiles."
    git clone --depth=1 https://github.com/Zaryob/dotfiles.git "$HOME/.dotfiles"
    cd "$HOME/.dotfiles"
    tempfile=`(tempfile) 2>/dev/null` || tempfile=/tmp/test$$
    trap "rm -f $tempfile" 0 $SIG_NONE $SIG_HUP $SIG_INT $SIG_QUIT $SIG_TERM

    $DIALOG --help-button --item-help --colors --backtitle "\Z1No Such\Zn Organization" \
	        --title "Installation" "$@" \
            --checklist "Hi, this is Zaryob dotfile installation script \n\
You can use this to install specifical dotfile configs \n\
You can use the \Z4UP/DOWN\Zn arrow keys, the first letter \n\
 of the choice as a hot key, or the number keys 1-9 to choose an option. \n\
Press \Zb\ZrSPACE\Zn to toggle an option on/off. \n\n\
  Which of the following are configs that you use?" 20 61 5 \
            "Emacs"      "Editor: \Z1Emacs\Zn configs."                    ON  "emacs" \
            "Vim"        "Editor: \Z2Vim\Zn config"                        off "vim" \
            "Git"        "General git config for email and name specific"  off "git" \
            "Bash"       "Bourne Agains SHell"                             off "bash" \
            "Zsh"        "ZSH"                                             off "zsh" \
            "Fish"       "Fish"                                            off "fish" \
            "Tmux"       "Tmux shell environment "                         off "tmux"  2> $tempfile

    returncode=$?

    case "${returncode:-0}" in
        $DIALOG_OK)
            for word in `cat "$tempfile"`; do
                dotfile_install_parts $word
            done

            echo "Result: `cat "$tempfile"`"
            ;;
        $DIALOG_CANCEL)
            echo "Canceled dotfile installation";;
        $DIALOG_HELP)
            echo "Help pressed: `cat "$tempfile"`";;
        $DIALOG_EXTRA)
            echo "Extra button pressed.";;
        $DIALOG_ITEM_HELP)
            echo "Item-help button pressed: `cat "$tempfile"`";;
        $DIALOG_TIMEOUT)
            echo "Timeout expired.";;
        $DIALOG_ESC)
            echo "ESC pressed." ;;
        *)
            echo "Return code was $returncode";;
    esac
    printf "YOU CAN RUN OUT :-)\n"
    touch $HOME/.zaryob
else
    echo "Zaryobizing was already made."
fi



#    printf "\033[0;33m - Setting conky up\033[0m\n"
#    ln -svf $HOME/.dotfiles/conky/conkyrc $HOME/.conkyrc
#    printf "\033[0;32m + Conky setted\033[0m\n"
#    printf "\033[0;33m - Setting i3wm up\033[0m\n"
#    ln -svf $HOME/.dotfiles/i3-themes/simplicity/compton.conf $HOME/.config
#    [ -f $HOME/.config/i3 ] || rm -rf $HOME/.config/i3
#    [ -f $HOME/.config/clipit ] || rm -rf $HOME/.config/clipit
#    ln -svf $HOME/.dotfiles/i3-themes/simplicity/config/clipit  $HOME/.dotfiles/i3-themes/simplicity/config/i3  $HOME/.config/
#    ln -svf $HOME/.dotfiles/i3-themes/simplicity/fehbg $HOME/.fehbg
#    printf "\033[0;32m + i3wm setted up\033[0m\n"
#    printf "\033[0;33m - Initializing Xorg extras \033[0m\n"
#    ln -svf  $HOME/.dotfiles/Xorg/xinitrc $HOME/.xinitrc
#    ln -svf $HOME/.dotfiles/Xorg/xserverrc $HOME/.xserverrc
#    ln -svf $HOME/.dotfiles/Xorg/Xdefaults $HOME/.Xdefaults
#    ln -svf $HOME/.dotfiles/Xorg/Xresources $HOME/.Xresources
#    printf "\033[0;32m + Initialized Xorg extras \033[0m\n"
#    printf "\033[0;33m - Initializing Extra Configs \033[0m\n"
#    ln -svf $HOME/.dotfiles/extras/mc $HOME/.config
#    ln -svf $HOME/.dotfiles/extras/oomox $HOME/.config
#    ln -svf $HOME/.dotfiles/extras/ncmpcpp $HOME/.ncmpcpp
#    ln -svf $HOME/.dotfiles/extras/mpd $HOME/.mpd
#    ln -svf $HOME/.dotfiles/extras/nitrogen $HOME/.config
#    ln -svf $HOME/.dotfiles/extras/kitty $HOME/.config
#    ln -svf $HOME/.dotfiles/extras/neofetch $HOME/.config
#    printf "\033[0;32m + Initialized Extra Configs \033[0m\n"
