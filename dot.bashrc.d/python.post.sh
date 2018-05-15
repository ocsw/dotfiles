_python_venv_prompt () {
    if [ -n "$PYENV_VERSION" ]; then
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
    py_cur_venv () {
        printf "%s\n" "$(pyenv version | sed 's/ (.*)$//')"
    }

    pyact () {
        venv="$1"
        if [ -n $venv ]; then
            pyenv activate "$venv"
        else
            pyenv deactivate
        fi
    }


   pylatest () {
        # get the latest available (or latest locally installed) version of
        # Python for a specified major version in pyenv
        local majorver="$1"
        local installed_only="$2"
        local versions ver

        if [ -n "$majorver" ] && [ "$majorver" != "2" ] && \
                [ "$majorver" != "3" ]; then
            cat <<EOF
Usage: pylatest [MAJOR_PYVERSION] [INSTALLED_ONLY]
MAJOR_PYVERSION defaults to 3.
If INSTALLED_ONLY is given, only installed pyenv base versions will be
examined.

ERROR: If given, MAJOR_PYVERSION must be 2 or 3.
EOF
            return 1
        fi
        [ -z "$majorver" ] && majorver="3"

        # see:
        # https://stackoverflow.com/questions/742466/how-can-i-reverse-the-order-of-lines-in-a-file
        # https://web.archive.org/web/20090208232311/http://student.northpark.edu/pemente/awk/awk1line.txt
        versions=$(pyenv install --list | tail -n +2 | sed "s/^..//" |
            grep "^${majorver}\.[0-9]" | grep -vi "[a-z]" |
            awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--]}'
        )

        if [ -z "$installed_only" ]; then
            printf "%s\n" "$versions" | head -n 1
            return 0
        fi
        for ver in $versions; do
            if [ -d "${HOME}/.pyenv/versions/$ver" ]; then
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
        local version="$1"

        if [ -z "$version" ]; then
            cat <<EOF
Usage: pybase PYVERSION [PYENV_INSTALL_ARGS]
If PYVERSION is 2 or 3, the latest available Python release with that major
version will be used.

ERROR: No version given.
EOF
            return 1
        fi
        if [ "$version" = "2" ] || [ "$version" = "3" ]; then
            version=$(pylatest "$version")
        fi
        shift        

        CFLAGS="$cflags_add $CFLAGS" pyenv install "$@" "$version"
    }


    pyutil_wrapper () {
        # clean up after the python helpers, below
        if [ -z "$1" ]; then
            echo "Usage: pyutil_wrapper COMMAND [ARGS]"
            echo "ERROR: No command given."
            return 1
        fi

        local wrapped="$1"
        shift
        local prev_wd="$PWD"
        local prev_venv=$(py_cur_venv)

        "$wrapped" "$@"
        retval="$?"

        cd "$prev_wd"
        if [ "$(py_cur_venv)" != "$prev_venv" ]; then
            global_env=$(pyenv global)
            if [ "$prev_venv" != "$global_env" ]; then
                pyenv activate "$prev_venv"
            else
                pyenv deactivate
            fi
        fi

        return "$retval"
    }


    pyvirt () {
        # create a pyenv-virtualenv virtualenv with a bunch of tweaks and
        # installs
        if [ -z "$1" ]; then
            cat <<EOF
Usage: pyvirt SHORTNAME PYVERSION [PROJ_PATH]
If PYVERSION is 2 or 3, the latest installed Python release with that major
version will be used.

ERROR: No shortname given.
EOF
            return 1
        fi
        if [ -z "$2" ]; then
            echo "ERROR: No Python version given."
            return 1
        fi
        if [ -n "$3" ] && [ ! -d "$3" ]; then
            echo "ERROR: Bad project path."
            return 1
        fi
        pyutil_wrapper _pyvirt "$@"
    }

    _pyvirt () {
        local shortname="$1"
        local version="$2"
        local projpath="$3"
        local fullname
        local i

        if [ "$version" = "2" ] || [ "$version" = "3" ]; then
            version=$(pylatest "$version" "installed_only")
        fi
        fullname="${shortname}-${version}"

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
        if [ -n "$projpath" ]; then
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
        # replacement for pipsi; creates a pyenv-virtualenv virtualenv
        # specifically for a python-based utility

        # to remove the virtualenv:
        #rm ~/bin/EXECUTABLE
        #pyenv uninstall $package-$version
        
        if [ -z "$1" ]; then
            cat <<EOF
Usage: pyinst PACKAGE PYVERSION [PKG_PATH]
If PYVERSION is 2 or 3, the latest installed Python release with that major
version will be used.

ERROR: No package given.
EOF
            return 1
        fi
        if [ -z "$2" ]; then
            echo "ERROR: No Python version given."
            return 1
        fi
        pyutil_wrapper _pyinst "$@"
    }

    _pyinst () {
        local package="$1"
        local version="$2"
        local pkgpath="$3"
        local fullname

        if [ "$version" = "2" ] || [ "$version" = "3" ]; then
            version=$(pylatest "$version" "installed_only")
        fi
        fullname="${package}-${version}"

        if ! pyvirt "$package" "$version"; then
            # error will already have been printed
            return 1
        fi
        pyenv activate "$fullname"
        if [ -z "$pkgpath" ]; then
            pip install "$package"
        else
            pip install "$pkgpath"
        fi
        if [ $? != "0" ]; then
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
        # install a project's requirements in a pyenv-virtualenv virtualenv
        if [ -z "$1" ]; then
            echo "Usage: pyreqs VIRTUALENV PROJ_PATH"
            echo
            echo "ERROR: No virtualenv given."
            return 1
        fi
        if [ -z "$2" ]; then
            echo "ERROR: No project path given."
            return 1
        fi
        if [ ! -d "$2" ]; then
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