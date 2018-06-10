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
        COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                       COMP_CWORD=$COMP_CWORD \
                       PIP_AUTO_COMPLETE=1 $1 ) )
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

    pycur_is_global() {
        [ -z "$PYENV_VERSION" ] && [ -z "$PYENV_VIRTUAL_ENV" ]
    }

    pycur_is_venv() {
        [ -n "$PYENV_VERSION" ] && [ -n "$PYENV_VIRTUAL_ENV" ]
    }

    pycur_is_dotfile () {
        [ -z "$PYENV_VERSION" ] && [ -n "$PYENV_VIRTUAL_ENV" ]
    }

    pyname_is_global () {
        local name="$1"
        if [ -z "$name" ]; then
            echo "Usage: pyname_is_global NAME"
            echo
            echo "ERROR: No name given."
            return 1
        fi
        pybases_installed | grep "^${name}\$" > /dev/null 2>&1
    }

    pyname_is_venv () {
        local name="$1"
        if [ -z "$name" ]; then
            echo "Usage: pyname_is_venv NAME"
            echo
            echo "ERROR: No name given."
            return 1
        fi
        pyvenvs | grep "^${name}\$" > /dev/null 2>&1
    }


    _py_base_complete () {
        local ver_func="$1"
        local add="$2"
        local cur_word="${COMP_WORDS[$COMP_CWORD]}"
        if [ -z "$add" ]; then
            # seems to not be necessary, but just in case...
            COMPREPLY=()
        fi
        while read -r line; do
            COMPREPLY+=("$line")
        done < <("$ver_func" | grep "^${cur_word}")
        if [ -z "$cur_word" ]; then
            COMPREPLY+=(2 3)
        elif [ "$cur_word" = "2" ]; then
            COMPREPLY+=(2)
        elif [ "$cur_word" = "3" ]; then
            COMPREPLY+=(3)
        fi
    }

    _py_venv_complete () {
        local add="$1"
        if [ -z "$add" ]; then
            # seems to not be necessary, but just in case...
            COMPREPLY=()
        fi
        local cur_word="${COMP_WORDS[$COMP_CWORD]}"
        while read -r line; do
            COMPREPLY+=("$line")
        done < <(pyvenvs | grep "^${cur_word}")
    }

    _py_all_complete () {
        _py_base_complete pybases_installed
        _py_venv_complete add
    }

    pyact () {
        local venv="$1"
        if [ -z "$venv" ]; then
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
        versions=$(pyenv install --list | tail -n +2 | sed 's/^..//' | \
            grep "^${major_version}\.[0-9]" | grep -vi "[a-z]" | \
            awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--]}')

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
            echo
            echo "ERROR: No command given."
            return 1
        fi

        shift
        local prev_wd="$PWD"
        local prev_venv
        local global_env
        local retval
        prev_venv=$(pycur)

        "$wrapped" "$@"
        retval="$?"

        cd "$prev_wd" || true  # ignore failure
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


    pyfix () {
        # fix a couple of things in a virtualenv that don't seem to come out
        # right by default
        pyutil_wrapper _pyfix "$@"
    }

    _pyfix () {
        local venv="$1"
        local py_version
        local major
        local major_minor

        if [ -z "$venv" ]; then
            echo "Usage: pyfix VIRTUALENV"
            echo
            echo "ERROR: No virtualenv given."
            return 1
        fi
        if ! pyvenvs | grep "^$venv\$" > /dev/null 2>&1; then
            echo "ERROR: \"$venv\" is not a valid virtualenv."
            return 1
        fi

        # tox seems to look directly in virtualenvs' bin directories, and
        # requires a minor-versioned python binary (e.g. python3.6), which the
        # above doesn't seem to provide (at least for python3).
        py_version=$(grep "^version *= *" \
            "${PYENV_ROOT}/versions/${venv}/pyvenv.cfg" | \
            sed 's/^version *= *//')
        major=$(printf "%s\n" "$py_version" | \
            sed 's/^\([0-9]\)\.[0-9]\.[0-9]$/\1/')
        major_minor=$(printf "%s\n" "$py_version" | \
            sed 's/^\([0-9]\.[0-9]\)\.[0-9]$/\1/')
        if ! cd "${PYENV_ROOT}/versions/${venv}/bin"; then
            cat << EOF

ERROR: Can't change to bin directory.  Stopping.
    Target: ${PYENV_ROOT}/versions/${venv}/bin

EOF
            return 1
        fi
        ln -s "python$major" "python$major_minor"

        # I haven't figured out how to make new virtualenvs have new pip;
        # pyenv global 3.6.5; pyenv deactivate; pip install --upgrade pip
        # will update the base image, but that apparently won't affect the new
        # ones.  I thought the problem might be with ensurepip, but that
        # doesn't seem to be it either.
        pyenv activate "$venv"
        pip install --upgrade pip
    }

    _pyfix_complete () {
        if [ "$COMP_CWORD" = "1" ]; then
            _py_venv_complete
        fi
    }
    complete -o default -F _pyfix_complete pyfix

    pyfix_all () {
        local venv
        for venv in $(pyvenvs); do
            echo "Fixing virtualenv \"$venv\"..."
            pyfix "$venv"
        done
        echo "Done."
    }


    pyvenv () {
        # create a pyenv-virtualenv virtualenv with a bunch of tweaks and
        # installs
        pyutil_wrapper _pyvenv "$@"
    }

    _pyvenv () {
        local short_name="$1"
        local py_version="$2"
        local project_dir="$3"
        local full_name
        local i

        if [ -z "$short_name" ]; then
            cat <<EOF
Usage: pyvenv SHORT_NAME PY_VERSION [PROJECT_DIRECTORY]
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
        if [ -n "$project_dir" ] && [ ! -d "$project_dir" ]; then
            echo "ERROR: Bad project directory."
            return 1
        fi
        if [ -n "$project_dir" ] && \
                ! compgen -G "$project_dir/*requirements.txt" \
                > /dev/null 2>&1; then
            cat <<EOF
ERROR: No requirements files in project directory; try again without it.
EOF
            return 1
        fi

        if [ "$py_version" = "2" ] || [ "$py_version" = "3" ]; then
            py_version=$(pylatest "$py_version" "installed_only")
        fi
        full_name="${short_name}-${py_version}"

        if ! pyenv virtualenv "$py_version" "$full_name"; then
            echo
            echo "ERROR: Can't create virtualenv.  Stopping."
            echo
            return 1
        fi
        pyfix "$full_name"
        if [ -n "$project_dir" ]; then
            pyreqs "$full_name" "$project_dir"
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


    pybin_dir () {
        local venv="$1"
        if [ -z "$venv" ]; then
            echo "Usage: pybin_dir VIRTUALENV"
            echo
            echo "ERROR: No virtualenv given."
            return 1
        fi
        printf "%s\n" "${PYENV_ROOT}/versions/${venv}/bin"
    }

    _pybin_dir_complete () {
        if [ "$COMP_CWORD" = "1" ]; then
            _py_venv_complete
        fi
    }
    complete -o default -F _pybin_dir_complete pybin_dir

    pybin_ls () {
        local venv="$1"
        if [ -z "$venv" ]; then
            echo "Usage: pybin_ls VIRTUALENV [LS_ARGS]"
            echo
            echo "ERROR: No virtualenv given."
            return 1
        fi
        shift
        ls "$@" "${PYENV_ROOT}/versions/${venv}/bin"
    }

    _pybin_ls_complete () {
        if [ "$COMP_CWORD" = "1" ]; then
            _py_venv_complete
        fi
    }
    complete -o default -F _pybin_ls_complete pybin_ls

    pyln () {
        local venv="$1"
        local exec_name="$2"
        local target_dir="$3"
        local source_path
        local target_path

        if [ -z "$venv" ]; then
            cat <<EOF
Usage: pyln VIRTUALENV EXECUTABLE TARGET_DIR
If TARGET_DIR is omitted, it defaults to the value of the PYLN_DIR environment
variable; if that is unset, it defaults to \$HOME/bin.

ERROR: No virtualenv given.
EOF
            return 1
        fi
        if [ -z "$exec_name" ]; then
            echo "ERROR: No executable name given."
            return 1
        fi
        if [ -z "$target_dir" ]; then
            if [ -n "$PYLN_DIR" ]; then
                target_dir="$PYLN_DIR"
            else
                target_dir="${HOME}/bin"
            fi
        fi
        if ! [ -d "$target_dir" ]; then
            echo "ERROR: Target directory doesn't exist or isn't a directory."
            echo "    Target: $target_dir"
            return 1
        fi

        source_path="${PYENV_ROOT}/versions/${venv}/bin/${exec_name}"
        target_path="${target_dir}/${exec_name}"
        if ln -s "$source_path" "$target_path"; then
            echo "Symlink \"${target_dir}/${exec_name}\" created."
        else
            cat <<EOF

WARNING: Symlink not created.
    Source: $source_path
    Target: $target_path

EOF
        fi
    }

    _pyln_complete () {
        if [ "$COMP_CWORD" = "1" ]; then
            _py_venv_complete
        elif [ "$COMP_CWORD" = "2" ]; then
        while read -r line; do
            COMPREPLY+=("$line")
        done < <(pybin_ls "${COMP_WORDS[1]}" 2>/dev/null | \
                grep "^${COMP_WORDS[2]}")
        fi
    }
    complete -o default -F _pyln_complete pyln


    pyinst () {
        # replacement for pipsi; creates a pyenv-virtualenv virtualenv
        # specifically for a Python-based utility

        # to remove the virtualenv:
        #rm PYLN_DIR/EXECUTABLE
        #pyenv uninstall $package_name-$py_version

        pyutil_wrapper _pyinst "$@"
    }

    _pyinst () {
        local package_name="$1"
        local py_version="$2"
        local package_path="$3"
        local full_name
        local install_string
        local pyln_dir_string

        if [ -z "$package_name" ]; then
            cat <<EOF
Usage: PYLN_DIR=SYMLINK_TARGET_DIR pyinst PACKAGE_NAME PY_VERSION [PACKAGE_PATH]
If PY_VERSION is 2 or 3, the latest installed Python release with that major
version will be used.
If PYLN_DIR is not set, SYMLINK_TARGET_DIR defaults to \$HOME/bin.

ERROR: No package name given.
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
        full_name="${package_name}-${py_version}"

        if ! pyvenv "$package_name" "$py_version"; then
            # error will already have been printed
            return 1
        fi
        pyenv activate "$full_name"
        if [ -z "$package_path" ]; then
            install_string="$package_name"
        else
            install_string="$package_path"
        fi
        if ! pip install "$install_string"; then
            echo
            echo "ERROR: Installation failed.  Stopping."
            echo
            return 1
        fi
        if [ -e "$(pybin_dir "${full_name}")/${package_name}" ]; then
            pyln "${full_name}" "${package_name}" "$PYLN_DIR"
        fi
        pyln_dir_string=""
        if [ -n "$PYLN_DIR" ]; then
            pyln_dir_string=" \"$PYLN_DIR\""
        fi
        cat <<EOF

To symlink other executables:
    pyln "${full_name}" "EXECUTABLE"$pyln_dir_string

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
        local project_dir="$2"
        local i

        if [ -z "$venv" ]; then
            echo "Usage: pyreqs VIRTUALENV PROJECT_DIRECTORY"
            echo
            echo "ERROR: No virtualenv given."
            return 1
        fi
        if [ -z "$project_dir" ]; then
            echo "ERROR: No project directory given."
            return 1
        fi
        if [ ! -d "$project_dir" ]; then
            echo "ERROR: Bad project directory."
            return 1
        fi
        if ! compgen -G "$project_dir/*requirements.txt" \
                > /dev/null 2>&1; then
            echo "ERROR: No requirements files in project directory."
            return 1
        fi

        if ! pyenv activate "$venv"; then
            echo
            echo "ERROR: Can't activate virtualenv.  Stopping."
            echo
            return 1
        fi
        if ! cd "$project_dir"; then
            echo
            echo "ERROR: Can't change to project directory.  Stopping."
            echo
            return 1
        fi
        for i in *requirements.txt; do
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