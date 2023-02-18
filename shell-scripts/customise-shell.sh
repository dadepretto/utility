#!/bin/zsh

if ! /usr/bin/grep -q 'prompt=' "$HOME/.zshrc"; then
    echo "-> Setting prompt style"
    echo 'prompt="%1~ %# "' >> $HOME/.zshrc
else
    echo "-> Skipping prompt style"
fi

if ! /usr/bin/grep -q 'alias l=' "$HOME/.zshrc"; then
    echo "-> Setting alias 'l' for ls"
    echo 'alias l="ls -1GlS"' >> $HOME/.zshrc
else
    echo "-> Skipping alias 'l' for ls"
fi

if ! /usr/bin/grep -q 'alias c=' "$HOME/.zshrc"; then
    echo "-> Setting alias 'c' for clear"
    echo 'alias c="clear"' >> $HOME/.zshrc
else
    echo "-> Skipping alias 'c' for clear"
fi
