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


# see common.sh
_pip_wrapper () {
    local cmd="$1"
    if ! is_available pyenv ||
            ! [[ "$(which "$cmd")" =~ /shims/ ]] ||
            [[ "$(pyenv version)" =~ ^system\  ]]; then
        umask_wrap 022 "$@"
        return "$?"
    fi
    command "$@"
}
pip () {
    _pip_wrapper pip "$@"
}
pip2 () {
    _pip_wrapper pip2 "$@"
}
pip3 () {
    _pip_wrapper pip3 "$@"
}


# can't use is_available() because we just defined functions with the same names
if in_path pip ||
        in_path pip2 ||
        in_path pip3; then
    _pip_completion () {
        # shellcheck disable=SC2207
        COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                       COMP_CWORD=$COMP_CWORD \
                       PIP_AUTO_COMPLETE=1 $1 ) )
    }
    in_path pip && complete -o default -F _pip_completion pip
    in_path pip2 && complete -o default -F _pip_completion pip2
    in_path pip3 && complete -o default -F _pip_completion pip3
fi

if is_available pyenv; then
    eval "$(pyenv init - | grep -vi 'path' | grep -v '^fi; done; $')"
fi
if is_available pyenv-virtualenv-init; then
    eval "$(pyenv virtualenv-init - | grep -v "PATH")"
fi
export PYPVUTIL_HOME="${HOME}/repos/pypvutil"
if is_available pyenv pyenv-virtualenv-init && \
        [ -f "${PYPVUTIL_HOME}/pypvutil_init.sh" ]; then
    export PYPVUTIL_PREFIX="py"
    # shellcheck disable=SC1091
    . "${PYPVUTIL_HOME}/pypvutil_init.sh"
else
    unset PYPVUTIL_HOME
    unset PYPVUTIL_PREFIX
fi
