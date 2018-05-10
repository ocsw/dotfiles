# --- tools used in both .bash_profile and .bashrc (and their modules) ---

# note: if we define or include these only in .bash_profile, sub-shells won't
# get them

# check for command in path
in_path () {
  hash "$@" > /dev/null 2>&1
}

# check for component of $PATH itself
is_path_component () {
  [[ "$PATH" =~ (^|:)$1(:|$) ]]  # no quotes around regex
}
