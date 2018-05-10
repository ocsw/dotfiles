_python_venv_prompt () {
    if [[ -n "$PYENV_VERSION" ]]; then
        printf "%s " "$PYENV_VERSION"
    fi
}

if in_path pip ||
        in_path pip2 ||
        in_path pip3; then
    _pip_completion () {
        COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                       COMP_CWORD=$COMP_CWORD \
                       PIP_AUTO_COMPLETE=1 $1 ) )
    }
    in_path pip && complete -o default -F _pip_completion pip
    in_path pip2 && complete -o default -F _pip_completion pip2
    in_path pip3 && complete -o default -F _pip_completion pip3
fi

if in_path pyenv; then
    eval "$(pyenv init - | grep -v PATH)"
fi
if in_path pyenv-virtualenv-init; then
    eval "$(pyenv virtualenv-init - | grep -v PATH)"
fi
if in_path pyenv && in_path pyenv-virtualenv-init; then
    pyinst () {
        if [[ -z "$1" ]]; then
            echo "ERROR: No package given."
            return
        fi
        if [[ -z "$2" ]]; then
            echo "ERROR: No version given."
            return
        fi
        local package="$1"
        local version="$2"
        local pkgpath="$3"
        local prev_wd="$PWD"
        local prev_venv=$(pyenv version | sed 's/ (.*)$//')
        local PIP
        pyenv virtualenv "$version" "${package}-${version}"
        pyenv activate "${package}-${version}"
        if [[ "$version" =~ ^2 ]]; then
            PIP=pip2
        else
            PIP=pip3
        fi
        if [[ -z "$pkgpath" ]]; then
            "$PIP" install "$package"
        else
            "$PIP" install "$pkgpath"
        fi
        cd "${HOME}/bin"
        ln -s "../.pyenv/versions/${package}-${version}/bin/${package}" .
        cat <<EOF

To symlink other executables:
    cd "${HOME}/bin"
    ln -s "../.pyenv/versions/${package}-${version}/bin/EXECUTABLE" .

EOF
        cd "$prev_wd"
        if [[ "$prev_venv" != "system" ]]; then
            pyenv activate "$prev_venv"
        else
            pyenv deactivate
        fi
    }

    ### To remove:
    # rm ~/bin/EXECUTABLE
    # pyenv uninstall $package-$version
    ###
fi