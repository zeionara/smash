#!/usr/bin/zsh

. "$HOME/smash/.zshrc"

pushd test

for file in $(smashd bar.sh); do
    echo $file
    cat $(smash $file)
    echo
done

popd
