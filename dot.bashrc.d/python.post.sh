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
    pyutil_wrapper () {
        # clean up after the python helpers, below
        if [[ -z "$1" ]]; then
            echo "Usage: pyutil_wrapper COMMAND [ARGS]"
            echo "ERROR: No command given."
            return 1
        fi

        local wrapped="$1"
        shift
        local prev_wd="$PWD"
        local prev_venv=$(pyenv version | sed 's/ (.*)$//')

        "$wrapped" "$@"
        retval="$?"

        cd "$prev_wd"
        cur_venv=$(pyenv version | sed 's/ (.*)$//')
        if [[ "$cur_venv" != "$prev_venv" ]]; then
            global_env=$(pyenv global)
            if [[ "$prev_venv" != "$global_env" ]]; then
                pyenv activate "$prev_venv"
            else
                pyenv deactivate
            fi
        fi

        return "$retval"
    }


    pyvirt () {
        # create a virtualenv with a bunch of tweaks and installs
        if [[ -z "$1" ]]; then
            echo "Usage: pyvirt SHORTNAME PYVERSION [PROJ_PATH]"
            echo "ERROR: No shortname given."
            return 1
        fi
        if [[ -z "$2" ]]; then
            echo "ERROR: No Python version given."
            return 1
        fi
        if [[ -n "$3" ]] && [[ ! -d "$3" ]]; then
            echo "ERROR: Bad project path."
            return 1
        fi
        pyutil_wrapper _pyvirt "$@"
    }

    _pyvirt () {
        local shortname="$1"
        local version="$2"
        local projpath="$3"
        local fullname="${shortname}-${version}"
        local i

        if ! pyenv virtualenv "$version" "$fullname"; then
            echo "ERROR: can't create virtualenv.  Stopping."
            return 1
        fi

        # symlink, mainly for Tox
        major=$(printf "%s\n" "$version" |
            sed 's/^\([0-9]\)\.[0-9]\.[0-9]$/\1/'
        )
        majorminor=$(printf "%s\n" "$version" |
            sed 's/^\([0-9]\.[0-9]\)\.[0-9]$/\1/'
        )
        cd "${HOME}/.pyenv/versions/${fullname}/bin"
        ln -s "python$major" "python$majorminor"

        pyenv activate "$fullname"
        pip install --upgrade pip
        if [[ -n "$projpath" ]]; then
            cd "$projpath"
            for i in *req*; do
                pip install -r "$i"
            done
        fi
        cat <<EOF

New python path:
    ${HOME}/.pyenv/versions/${fullname}/bin/python

EOF

        return 0
    }


    pyinst () {
        # replacement for pipsi; creates a virtualenv specifically for a 
        # python-based utility

        # to remove the virtualenv:
        #rm ~/bin/EXECUTABLE
        #pyenv uninstall $package-$version
        
        if [[ -z "$1" ]]; then
            echo "Usage: pyinst PACKAGE PYVERSION [PKG_PATH]"
            echo "ERROR: No package given."
            return 1
        fi
        if [[ -z "$2" ]]; then
            echo "ERROR: No Python version given."
            return 1
        fi
        pyutil_wrapper _pyinst "$@"
    }

    _pyinst () {
        local package="$1"
        local version="$2"
        local pkgpath="$3"
        local fullname="${package}-${version}"

        if ! pyvirt "$package" "$version"; then
            # error will already have been printed
            return 1
        fi
        pyenv activate "$fullname"
        if [[ -z "$pkgpath" ]]; then
            pip install "$package"
        else
            pip install "$pkgpath"
        fi
        if [[ $? != "0" ]]; then
            echo "ERROR: installation failed.  Stopping."
            return 1
        fi
        cd "${HOME}/bin"
        ln -s "../.pyenv/versions/${fullname}/bin/${package}" .
        cat <<EOF

To symlink other executables:
    cd "${HOME}/bin"
    ln -s "../.pyenv/versions/${fullname}/bin/EXECUTABLE" .

EOF

        return 0
    }


    pyreqs () {
        # install a project's requirements in a virtualenv
        if [[ -z "$1" ]]; then
            echo "Usage: pyreqs VIRTUALENV PROJ_PATH"
            echo "ERROR: No virtualenv given."
            return 1
        fi
        if [[ -z "$2" ]]; then
            echo "ERROR: No project path given."
            return 1
        fi
        if [[ ! -d "$2" ]]; then
            echo "ERROR: Bad project path."
            return 1
        fi
        pyutil_wrapper _pyreqs "$@"
    }

    _pyreqs () {
        local venv="$1"
        local projpath="$2"
        local i

        if ! pyenv activate "$venv"; then
            echo "ERROR: can't activate virtualenv.  Stopping."
            return 1
        fi
        cd "$projpath"
        for i in *req*; do
            pip install -r "$i"
        done

        return 0
    }
fi  # end test for pyenv and pyenv-virtualenv