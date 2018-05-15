if in_path pyenv; then
    if [ -z "$PYENV_ROOT" ] && [ -d "$HOME/.pyenv" ]; then
        export PYENV_ROOT="$HOME/.pyenv"
    fi
    if ! is_path_component "$PYENV_ROOT/bin" &&
            [ -d "$PYENV_ROOT/bin" ]; then
        export PATH="$PYENV_ROOT/bin:$PATH"
    fi
    if ! is_path_component "$PYENV_ROOT/shims" &&
            [ -d "$PYENV_ROOT/shims" ]; then
        export PATH="$PYENV_ROOT/shims:$PATH"
    fi
fi
if in_path pyenv-virtualenv-init; then
    if ! is_path_component "/pyenv-virtualenv/"; then
        eval "$(pyenv virtualenv-init - | grep PATH)"
    fi
    export PYENV_VIRTUALENV_DISABLE_PROMPT=1
fi
