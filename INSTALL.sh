#!/usr/bin/env bash

umask 077

mkdir -p "${HOME}/bin"
mkdir -p "${HOME}/repos"

DOTFILE_REPO="${DOTFILE_REPO:-${HOME}/repos/dotfiles}"
PYPVUTIL_REPO="${PYPVUTIL_REPO:-${HOME}/repos/pypvutil}"
SYSTEM_SETUP="${SYSTEM_SETUP:-${HOME}/repos/system-setup}"
TBU_DIR="${TBU_DIR:-${HOME}/.to_back_up}"

# Note: This requires setting up GitHub access first; see
# https://github.com/ocsw/system-setup/blob/main/unix-common/git.psh.
# Alternatively, use https://github.com/ocsw/REPO.git for read-only access.
#
# See https://github.com/ocsw/dotfiles, https://github.com/ocsw/pypvutil, and
# https://github.com/ocsw/system-setup
git clone git@github.com:ocsw/dotfiles.git "$DOTFILE_REPO"
git clone git@github.com:ocsw/pypvutil.git "$PYPVUTIL_REPO"
git clone git@github.com:ocsw/system-setup.git "$SYSTEM_SETUP"

# See https://github.com/ocsw/dotfiles/blob/main/dot.bashrc.d/dotfiles.post.sh
# shellcheck disable=SC1091
. "${DOTFILE_REPO}/dot.bashrc.d/dotfiles.post.sh"

ln_dotfile .bash_profile
ln_dotfile .bash_profile.d
ln_dotfile .bashrc
ln_dotfile .bashrc.d
ln_dotfile .inputrc
cp_dotfile .bashrc.local
#ln_dotfile .bash_logout  # maybe
ln_dotfile .hstr_blacklist
#
ln_dotfile .vimrc
ln_dotfile .vimrc.d
cp_dotfile .vimrc.local
#
#ln_dotfile .muttrc  # maybe

# See https://github.com/ocsw/dotfiles/blob/main/dot.bashrc.d/to_back_up.post.sh
# shellcheck disable=SC1091
. "${DOTFILE_REPO}/dot.bashrc.d/to_back_up.post.sh"
cd "$HOME" || exit 1

touch .bash_history
chmod 600 .bash_history
ln_tbu .bash_history
touch .bashrc.local
ln_tbu .bashrc.local
touch .hstr_favorites
ln_tbu .hstr_favorites
touch .vimrc.local
ln_tbu .vimrc.local
#
mkdir -p .ssh
chmod 700 .ssh
touch .ssh/config
chmod 600 .ssh/config
ln_tbu .ssh/config
touch .ssh/known_hosts
chmod 600 .ssh/known_hosts
ln_tbu .ssh/known_hosts
#
mkdir -p .gnupg
touch .gnupg/dirmngr.conf
ln_tbu .gnupg/dirmngr.conf
touch .gnupg/gpg-agent.conf
ln_tbu .gnupg/gpg-agent.conf
touch .gnupg/gpg.conf
ln_tbu .gnupg/gpg.conf
# if [ "$(uname)" = "Darwin" ]; then
#     mkdir -p .gnupg_pre_2.1
#     touch .gnupg_pre_2.1/dirmngr.conf
#     ln_tbu .gnupg_pre_2.1/dirmngr.conf
#     touch .gnupg_pre_2.1/gpg-agent.conf
#     ln_tbu .gnupg_pre_2.1/gpg-agent.conf
#     touch .gnupg_pre_2.1/gpg.conf
#     ln_tbu .gnupg_pre_2.1/gpg.conf
# fi
#
touch .gitconfig
ln_tbu .gitconfig
touch .gitconfig_rewrites
ln_tbu .gitconfig_rewrites
while IFS= read -r file; do
    ln_tbu "$file"
done < <(compgen -G ".gitconfig_*")
touch .gitignore_global
ln_tbu .gitignore_global
#
mkdir -p .ipython
chmod 700 .ipython
ln_tbu .ipython
touch .python_history
chmod 600 .python_history
ln_tbu .python_history
mkdir -p .pip
ln_tbu .pip
touch .pypirc
ln_tbu .pypirc
touch .flake8
ln_tbu .flake8
#
vscode_confdir=""
if [ "$(uname)" = "Darwin" ]; then
    vscode_confdir="Library/Application Support/Code/User"
fi
if [ -n "$vscode_confdir" ]; then
    mkdir -p "$vscode_confdir"
    touch "$vscode_confdir/keybindings.json"
    ln_tbu "$vscode_confdir/keybindings.json"
    touch "$vscode_confdir/settings.json"
    ln_tbu "$vscode_confdir/settings.json"
    mkdir -p "$vscode_confdir/snippets"
    ln_tbu "$vscode_confdir/snippets"
fi
unset vscode_confdir
