#!/usr/bin/env bash

# bash 3.1+ required

_python_venv_prompt () {
    # Note: 'pyenv activate' uses $PYENV_VERSION, which pyenv checks first.
    # In order for a .python_version to take effect (which uses
    # $PYENV_VIRTUAL_ENV), you must be on the global pyenv version (i.e. do
    # 'pyenv deactivate').
    # ('pyenv activate' actually also sets $PYENV_VIRTUAL_ENV, but what matters
    # for us here is $PYENV_VERSION.)
    if [ -n "$PYENV_VERSION" ]; then
        printf "%s " "$PYENV_VERSION"
    elif [ -n "$PYENV_VIRTUAL_ENV" ]; then
        printf "%s " "${PYENV_VIRTUAL_ENV##*/}"
    fi
}

if in_path pip ||
        in_path pip2 ||
        in_path pip3; then
    _pip_completion () {
        while read -r -a line; do
            COMPREPLY+=("${line[@]}")
        done < <(COMP_WORDS="${COMP_WORDS[*]}" \
                COMP_CWORD="$COMP_CWORD" \
                PIP_AUTO_COMPLETE=1 "$1")
        [ -n "$line" ] && COMPREPLY+=("${line[@]}")
    }
    in_path pip && complete -o default -F _pip_completion pip
    in_path pip2 && complete -o default -F _pip_completion pip2
    in_path pip3 && complete -o default -F _pip_completion pip3
fi

if in_path pyenv; then
    eval "$(pyenv init - | grep -v "PATH")"
fi
if in_path pyenv-virtualenv-init; then
    eval "$(pyenv virtualenv-init - | grep -v "PATH")"
fi
if in_path pyenv && in_path pyenv-virtualenv-init && \
        [ -f "${HOME}/.pypvutil/pypvutil_init.sh" ]; then
    # shellcheck disable=SC1090
    . "${HOME}/.pypvutil/pypvutil_init.sh"
fi
