_python_venv_prompt () {
    # Note: 'pyenv activate' uses $PYENV_VERSION, which pyenv checks first.
    # In order for a .python_version to take effect (which uses
    # $PYENV_VIRTUAL_ENV), you must be on the global pyenv version (i.e. do
    # 'pyenv deactivate').
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
    pycur () {
        printf "%s\n" "$(pyenv version | sed 's/ (.*$//')"
    }

    pybases_available () {
        pyenv install --list | tail -n +2 | sed 's/^..//'
    }

    pybases_installed () {
        # see https://unix.stackexchange.com/questions/275637/limit-posix-find-to-specific-depth
        find "${PYENV_ROOT}/versions/." ! -name . -prune -type d | \
            sed "s|^${PYENV_ROOT}/versions/\./||"
    }

    pyvenvs () {
        pyenv virtualenvs | sed -e 's/^..//' -e 's/ (.*$//' | \
            grep -v "/envs/" 
    }


    _py_base_complete () {
        local ver_func="$1"
        local cur_word="${COMP_WORDS[$COMP_CWORD]}"
        COMPREPLY=( $("$ver_func" | grep "^${cur_word}") )
        if [ -z "$cur_word" ]; then
            COMPREPLY+=( 2 3 )
        elif [ "$cur_word" = "2" ]; then
            COMPREPLY+=( 2 )
        elif [ "$cur_word" = "3" ]; then
            COMPREPLY+=( 3 )
        fi
    }

    _py_venv_complete () {
        local cur_word="${COMP_WORDS[$COMP_CWORD]}"
        COMPREPLY=( $(pyvenvs | grep "^${cur_word}") )
    }


    pyact () {
        local venv="$1"
        if [ -n "$venv" ]; then
            pyenv activate "$venv"
        else
            pyenv deactivate
        fi
    }

    _pyact_complete () {
        if [ "$COMP_CWORD" = "1" ]; then
            _py_venv_complete
        fi
    }
    complete -o default -F _pyact_complete pyact


    pylatest () {
        # get the latest available (or latest locally installed) version of
        # Python for a specified major version in pyenv
        local major_version="$1"
        local installed_only="$2"
        local versions ver

        if [ -n "$major_version" ] && [ "$major_version" != "2" ] && \
                [ "$major_version" != "3" ]; then
            cat <<EOF
Usage: pylatest [MAJOR_PY_VERSION] [INSTALLED_ONLY]
MAJOR_PY_VERSION defaults to 3.
If INSTALLED_ONLY is given, only installed pyenv base versions will be
examined.

ERROR: If given, MAJOR_PY_VERSION must be 2 or 3.
EOF
            return 1
        fi
        [ -z "$major_version" ] && major_version="3"

        # see:
        # https://stackoverflow.com/questions/742466/how-can-i-reverse-the-order-of-lines-in-a-file
        # https://web.archive.org/web/20090208232311/http://student.northpark.edu/pemente/awk/awk1line.txt
        versions=$(pyenv install --list | tail -n +2 | sed 's/^..//' |
            grep "^${major_version}\.[0-9]" | grep -vi "[a-z]" |
            awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--]}'
        )

        if [ -z "$installed_only" ]; then
            printf "%s\n" "$versions" | head -n 1
            return 0
        fi
        for ver in $versions; do
            if [ -d "${PYENV_ROOT}/versions/$ver" ]; then
                printf "%s\n" "$ver"
                return 0
            fi
        done

        return 1
    }

    # don't use aliases so no other args will be passed
    py3latest () { pylatest 3; }
    py2latest () { pylatest 2; }
    pylatest_local () { pylatest "$1" "installed_only"; }
    py3latest_local () { pylatest_local 3; }
    py2latest_local () { pylatest_local 2; }


    pybase () {
        # install a version of Python in pyenv
        local cflags_add="-O2"
        local py_version="$1"

        if [ -z "$py_version" ]; then
            cat <<EOF
Usage: pybase PY_VERSION [PYENV_INSTALL_ARGS]
If PY_VERSION is 2 or 3, the latest available Python release with that major
version will be used.

ERROR: No Python version given.
EOF
            return 1
        fi
        if [ "$py_version" = "2" ] || [ "$py_version" = "3" ]; then
            py_version=$(pylatest "$py_version")
        fi
        shift        

        CFLAGS="$cflags_add $CFLAGS" pyenv install "$@" "$py_version"
    }

    _pybase_complete () {
        if [ "$COMP_CWORD" = "1" ]; then
            _py_base_complete pybases_available
        fi
    }
    complete -o default -F _pybase_complete pybase


    pyutil_wrapper () {
        # clean up after the Python helpers, below
        local wrapped="$1"
        if [ -z "$wrapped" ]; then
            echo "Usage: pyutil_wrapper COMMAND [ARGS]"
            echo "ERROR: No command given."
            return 1
        fi

        shift
        local prev_wd="$PWD"
        local prev_venv=$(pycur)
        local global_env
        local retval

        "$wrapped" "$@"
        retval="$?"

        cd "$prev_wd"
        if [ "$(pycur)" != "$prev_venv" ]; then
            global_env=$(pyenv global)
            if [ "$prev_venv" != "$global_env" ]; then
                pyenv activate "$prev_venv"
            else
                pyenv deactivate
            fi
        fi

        return "$retval"
    }


    pyvenv () {
        # create a pyenv-virtualenv virtualenv with a bunch of tweaks and
        # installs
        pyutil_wrapper _pyvenv "$@"
    }

    _pyvenv () {
        local short_name="$1"
        local py_version="$2"
        local proj_path="$3"
        local full_name
        local major
        local major_minor
        local i

        if [ -z "$short_name" ]; then
            cat <<EOF
Usage: pyvenv SHORT_NAME PY_VERSION [PROJ_PATH]
If PY_VERSION is 2 or 3, the latest installed Python release with that major
version will be used.

ERROR: No short name given.
EOF
            return 1
        fi
        if [ -z "$py_version" ]; then
            echo "ERROR: No Python version given."
            return 1
        fi
        if [ -n "$proj_path" ] && [ ! -d "$proj_path" ]; then
            echo "ERROR: Bad project path."
            return 1
        fi

        if [ "$py_version" = "2" ] || [ "$py_version" = "3" ]; then
            py_version=$(pylatest "$py_version" "installed_only")
        fi
        full_name="${short_name}-${py_version}"

        if ! pyenv virtualenv "$py_version" "$full_name"; then
            echo "ERROR: can't create virtualenv.  Stopping."
            return 1
        fi

        # symlink, mainly for Tox
        major=$(printf "%s\n" "$py_version" |
            sed 's/^\([0-9]\)\.[0-9]\.[0-9]$/\1/'
        )
        major_minor=$(printf "%s\n" "$py_version" |
            sed 's/^\([0-9]\.[0-9]\)\.[0-9]$/\1/'
        )
        cd "${PYENV_ROOT}/versions/${full_name}/bin"
        ln -s "python$major" "python$major_minor"

        pyenv activate "$full_name"
        pip install --upgrade pip
        if [ -n "$proj_path" ]; then
            cd "$proj_path"
            for i in *req*; do
                pip install -r "$i"
            done
        fi
        cat <<EOF

New Python path:
    ${PYENV_ROOT}/versions/${full_name}/bin/python

EOF

        return 0
    }

    _pyvenv_complete () {
        if [ "$COMP_CWORD" = "2" ]; then
            _py_base_complete pybases_installed
        fi
    }
    complete -o default -F _pyvenv_complete pyvenv


    pyinst () {
        # replacement for pipsi; creates a pyenv-virtualenv virtualenv
        # specifically for a Python-based utility

        # to remove the virtualenv:
        #rm ~/bin/EXECUTABLE
        #pyenv uninstall $package-$py_version

        pyutil_wrapper _pyinst "$@"
    }

    _pyinst () {
        local package="$1"
        local py_version="$2"
        local pkg_path="$3"
        local full_name

        if [ -z "$package" ]; then
            cat <<EOF
Usage: pyinst PACKAGE PY_VERSION [PKG_PATH]
If PY_VERSION is 2 or 3, the latest installed Python release with that major
version will be used.

ERROR: No package given.
EOF
            return 1
        fi
        if [ -z "$py_version" ]; then
            echo "ERROR: No Python version given."
            return 1
        fi

        if [ "$py_version" = "2" ] || [ "$py_version" = "3" ]; then
            py_version=$(pylatest "$py_version" "installed_only")
        fi
        full_name="${package}-${py_version}"

        if ! pyvenv "$package" "$py_version"; then
            # error will already have been printed
            return 1
        fi
        pyenv activate "$full_name"
        if [ -z "$pkg_path" ]; then
            pip install "$package"
        else
            pip install "$pkg_path"
        fi
        if [ $? != "0" ]; then
            echo "ERROR: installation failed.  Stopping."
            return 1
        fi
        cd "${HOME}/bin"
        ln -s "${PYENV_ROOT}/versions/${full_name}/bin/${package}" .
        cat <<EOF

To symlink other executables:
    cd "${HOME}/bin"
    ln -s "${PYENV_ROOT}/versions/${full_name}/bin/EXECUTABLE" .

EOF

        return 0
    }

    _pyinst_complete () {
        if [ "$COMP_CWORD" = "2" ]; then
            _py_base_complete pybases_installed
        fi
    }
    complete -o default -F _pyinst_complete pyinst


    pyreqs () {
        # install a project's requirements in a pyenv-virtualenv virtualenv
        pyutil_wrapper _pyreqs "$@"
    }

    _pyreqs () {
        local venv="$1"
        local proj_path="$2"
        local i

        if [ -z "$venv" ]; then
            echo "Usage: pyreqs VIRTUALENV PROJ_PATH"
            echo
            echo "ERROR: No virtualenv given."
            return 1
        fi
        if [ -z "$proj_path" ]; then
            echo "ERROR: No project path given."
            return 1
        fi
        if [ ! -d "$proj_path" ]; then
            echo "ERROR: Bad project path."
            return 1
        fi

        if ! pyenv activate "$venv"; then
            echo "ERROR: can't activate virtualenv.  Stopping."
            return 1
        fi
        cd "$proj_path"
        for i in *req*; do
            pip install -r "$i"
        done

        return 0
    }

    _pyreqs_complete () {
        if [ "$COMP_CWORD" = "1" ]; then
            _py_venv_complete
        fi
    }
    complete -o default -F _pyreqs_complete pyreqs
fi  # end test for pyenv and pyenv-virtualenv