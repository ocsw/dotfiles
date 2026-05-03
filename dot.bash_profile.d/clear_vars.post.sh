#!/usr/bin/env bash

# shellcheck disable=SC2034

#
# There are some variables that are set in dot.bashrc.d that contain paths to
# repos and backup directories.  They are only set there if they are unset or
# empty, so that it's possible to e.g. run INSTALL.sh with custom values and
# not have them be immediately overwritten when it sources things from
# dot.bashrc.d.
#
# To change them permanently, set them in .bashrc.local.  But if you change
# them temporarily, and you don't have them set in .bashrc.local, you can't
# conveniently reset them by sourcing .bashrc.  This file makes it so that you
# can reset them by sourcing .bash_profile, but still have flexibility.
#

# See ../dot.bashrc.d/dotfiles.post.sh
DOTFILE_REPO=

# See ../dot.bashrc.d/system_setup.post.sh
SYSTEM_SETUP=

# See ../dot.bashrc.d/to_back_up.post.sh
TBU_DIR=
TBUV_DIR=
