#!/bin/zsh

comment=${1-$(hostname)}
filename=${2-github}

echo "-> Generating key"
ssh-keygen -t rsa -b 4096 -a 128 -f ~/.ssh/${filename} -q -N "" -C $comment

echo "-> Running ssh agent"
eval "$(ssh-agent -s)" >> /dev/null

echo "-> Adding ssh configuration"
echo "Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/${filename}
" >> ~/.ssh/config

echo "-> Adding key to ssh agent"
ssh-add -q --apple-use-keychain ~/.ssh/${filename}

echo "-> Copying public key to your clipboard. Use CMD+V (paste) to paste wherever you need!"
cat ~/.ssh/${filename}.pub | pbcopy
