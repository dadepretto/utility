brew install rbenv ruby-build -q
rbenv install 3.0.0 -s
rbenv global 3.0.0

filename="/Users/$(whoami)/.zshrc"
if ! /usr/bin/grep -q 'eval "$(rbenv init - zsh)"' "$filename"; then
    echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
    eval "$(rbenv init - zsh)"
    exec zsh
fi

bundle update --bundler
bundle install
