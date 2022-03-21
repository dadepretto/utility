filename="$HOME/.zshrc"

if ! /usr/bin/grep -q 'prompt=' "$filename"; then
    echo "-> Setting prompt style"
    echo 'prompt="%1~ %# "' >> $filename
else
    echo "-> Skipping prompt style"
fi

if ! /usr/bin/grep -q 'alias l=' "$filename"; then
    echo "-> Setting alias 'l' for ls"
    echo 'alias l="ls -1GlS"' >> $filename
else
    echo "-> Skipping alias 'l' for ls"
fi

if ! /usr/bin/grep -q 'alias c=' "$filename"; then
    echo "-> Setting alias 'c' for clear"
    echo 'alias c="clear"' >> $filename
else
    echo "-> Skipping alias 'c' for clear"
fi

if ! /usr/bin/grep -q 'alias docker=' "$filename"; then
    echo "-> Setting alias 'docker' for podman"
    echo 'alias docker="podman"' >> $filename
else
    echo "-> Skipping alias 'c' for clear"
fi