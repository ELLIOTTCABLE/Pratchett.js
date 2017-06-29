#!/usr/bin/env sh
                                                                              set +o verbose
# Usage:
# ------
# This script will convert your local .git/hooks directory to allow for multiple scripts for each
# `git`-hook, and will then install the hooks associated with contributing to this project.
#
#     VERBOSE=4 npm run-script install-git-hooks
#
# It takes as its optional first argument a particular git-hook to install scripts for, and as its
# second, a particular git-directory to install the hooks in:
#
#     npm run-script install-git-hooks -- pre-commit a/project/dir/.git

puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}

hook_dir="${2:-.git}/hooks"
tracked_dir="$npm_package_config_dirs_hooks"
requested_hook="$1"

# ‘Arrays’ in POSIX shell are a nasty topic. It's possible to work relatively sanely with
# newline-delimited strings, but since git hooks' names contain no spaces, I'll simply use a
# space-delimited string for this.  /=
default_hooks="$npm_package_config_git_hooks"


# FIXME: This should support *excluded* modules with a minus, as per `node-debug`:
#        https://github.com/visionmedia/debug
if echo "$DEBUG" | grep -qE '(^|,\s*)(\*|Paws.js(:(scripts|\*))?)($|,)'; then
   pute "Script debugging enabled (in: `basename $0`)."
   DEBUG_SCRIPTS=yes
   VERBOSE="${VERBOSE:-7}"
fi

[ -n "$DEBUG_SCRIPTS" ] && puts \
   "Requested hook:         ${1:--}"                                          \
   "Default hooks:         '$default_hooks'"                                  \
   "Installing to:         '$hook_dir'"                                       \
   "" >&2

[ ! -d ".git" ] && \
   pute 'You must be in the root directory of a `git` project to use this script!' \
   && exit 10

[ ! -d "$tracked_dir" ] && \
   pute "The tracked hooks-dir, '$tracked_dir', doesn't seem to exist. Check your package.json?" \
   && exit 11

mkdir -p "$hook_dir"

# An attempt to make a Dropbox-compatible (i.e. doesn't care if you flatten symlinks) alternative to
# `ln -s`.
install_link() {
   existing="$1"
   new="$2"

   if [ -h "$new" ]; then
      rm "$new"                                                               || return 21
   fi

   # If the file exists, and isn't identical / a symlink, then move it aside ...
   if [ -e "$new" ] && ! diff "$existing" "$new" >/dev/null; then
      pute "Moving your '$new' to '$new-preexisting' ..."
      mv "$new" "$new-preexisting"                                            || return 22 ;fi

   # ... and link the requested contents.
   ln -s "$existing" "$new"                                                   || return 23
}

install_hook() {
   hook_name="$1"

   [ "$VERBOSE" -ge 4 ] && pute "Installing '$hook_name' hooks ..."

   # First, link the hook-chaining script to process these hooks
   install_link "$tracked_dir/chain-hooks.sh" "$hook_dir/$hook_name"          || exit $?

   # Then, for each tracked hook in the repository,
   for tracked_path in "$tracked_dir/$hook_name"-*; do
      if [ ! -x "$tracked_path" ]; then continue                              ;fi

      hook_path="$hook_dir/$(basename "$tracked_path")"
      [ "$VERBOSE" -ge 4 ] && pute " - '$hook_path'"
      [ "$VERBOSE" -ge 6 ] && pute " -> '$tracked_path'"

      # create a symlink back to the tracked hook-file
      install_link "$tracked_path" "$hook_path"                               || exit $?; done
}

for hook in ${requested_hooks:-$default_hooks}; do
   install_hook $hook                                                         ;done
