#!/usr/bin/env bash

export DOTFILE_REPO="${HOME}/.dotfiles"
git clone git@github.com:ocsw/dotfiles.git "$DOTFILE_REPO"

# shellcheck disable=SC1090
. "${DOTFILE_REPO}/dot.bashrc.d/dotfiles.post.sh"

ln_dotfile .bash_profile
ln_dotfile .bash_profile.d
ln_dotfile .bashrc
ln_dotfile .bashrc.d
ln_dotfile .inputrc
cp_dotfile .bashrc.local
#ln_dotfile .bash_logout  # maybe
#
ln_dotfile .vimrc
ln_dotfile .vimrc.d
cp_dotfile .vimrc.local
#
#ln_dotfile .muttrc  # maybe

touch .bash_history
ln_tbu .bash_history
touch .bashrc.local
ln_tbu .bashrc.local
touch .vimrc.local
ln_tbu .vimrc.local
#
mkdir -p .ipython
ln_tbu .ipython
touch .python_history
ln_tbu .python_history
mkdir -p .pip
ln_tbu .pip
touch .pypirc
ln_tbu .pypirc
#
mkdir -p .vscode
ln_tbu .vscode
