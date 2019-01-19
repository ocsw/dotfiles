#!/usr/bin/env bash

export DOTFILE_REPO="${HOME}/.dotfiles"
export PYPVUTIL_REPO="${HOME}/.pypvutil"
git clone git@github.com:ocsw/dotfiles.git "$DOTFILE_REPO"
git clone git@github.com:ocsw/pypvutil.git "$PYPVUTIL_REPO"

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

# shellcheck disable=SC1090
. "${DOTFILE_REPO}/dot.bashrc.d/to_back_up.post.sh"
cd "$HOME" || exit 1

touch .bash_history
ln_tbu .bash_history
touch .bashrc.local
ln_tbu .bashrc.local
touch .vimrc.local
ln_tbu .vimrc.local
#
mkdir -p .ssh
chmod 700 .ssh
touch .ssh/config
chmod 600 .ssh/config
ln_tbu .ssh/config
#
touch .gitconfig
ln_tbu .gitconfig
touch .gitignore_global
ln_tbu .gitignore_global
#
mkdir -p .ipython
ln_tbu .ipython
touch .python_history
ln_tbu .python_history
mkdir -p .pip
ln_tbu .pip
touch .pypirc
ln_tbu .pypirc
touch .flake8
ln_tbu .flake8
