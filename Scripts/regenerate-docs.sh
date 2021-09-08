#!/usr/bin/env sh
# shellcheck shell=dash
                                                                              set +o verbose
# Usage:
# ------
# TODO: DOCME

puts() { printf %s\\n "$@"; }
pute() { printf %s\\n "~~ $*" >&2; }

docs_dir="$npm_package_config_dirs_documentation"

stash_desc="${__filename}: HIDING UNSTAGED WORK FROM DOCS"

__filename="$(basename "$0")"
# FIXME: This should support *excluded* modules with a minus, as per `node-debug`:
#        https://github.com/visionmedia/debug
if echo "$DEBUG" | grep -qE '(^|,\s*)(\*|Paws.js(:(scripts|\*))?)($|,)'; then       # 1.  $DEBUG_SCRIPTS
   pute "Script debugging enabled (in: $__filename)."
   DEBUG_SCRIPTS=yes
   VERBOSE="${VERBOSE:-7}"
fi

[ -z "${SILENT##[NFnf]*}${QUIET##[NFnf]*}" ] && [ "${VERBOSE:-4}" -gt 6 ] && print_commands=yes
may() { # commands which are allowed to fail
   [ -z ${print_commands+0} ] || puts '`` '"$*" >&2
   "$@" || return $?
}
must() { # commands that must succeed
   [ -z ${print_commands+0} ] || puts '`` '"$*" >&2
   "$@" || exit $?
}

# 'stash working-tree changes'
stash_working=_no

# Check if there are any changes
may update-index --refresh
if may diff-index --quiet HEAD -- .':!'"$docs_dir"; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Enabling working-dir stashing"
   stash_working=_yes
fi

if [ "$stash_working" != "_no" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Stashing working-dir changes"
   must git stash push --include-untracked --keep-index --quiet -m "$stash_desc" \
      -- . ':!'"$docs_dir"
fi

may typedoc
typedoc_exit_status=$?

if [ "$stash_working" != "_no" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Popping working-dir changes"
   if may git stash pop --quiet; then
      true # no-op
   else
      pop_exit_status=$?
      [ -n "$DEBUG_SCRIPTS" ] && pute "Popping failed"
      # shellcheck disable=SC2016
      (
         pute '!! `git stash pop` failed during working-tree restoration; merging of index'
         pute '   files may be necessary. Check `git status` and `git stash show`; and don'\''t'
         pute '   forget to `git stash drop` once you have successfully used `git stash apply`.'
      )
      exit $pop_exit_status
   fi
fi

exit $typedoc_exit_status
