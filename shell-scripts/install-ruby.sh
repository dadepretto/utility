brew install rbenv ruby-build -q
rbenv install 3.0.0 -s
rbenv global 3.0.0

if ! /usr/bin/grep -q 'eval "$(rbenv init - zsh)"' "$HOME/.zprofile"; then
    echo 'eval "$(rbenv init - zsh)"' >> $HOME/.zprofile
    eval "$(rbenv init - zsh)"
    exec zsh
fi

# bundle install
# bundle update --bundler
