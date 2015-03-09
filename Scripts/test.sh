#!/usr/bin/env sh
                                                                                      set +o verbose
# Usage:
# ------
# This script runs both the unit-test suite and, if they've been downloaded, checks conformance with
# the Paws rulebooks.
# 
#    npm test
#    RUN_LETTERS=yes npm test    # To execute the Letters, as well
puts() { printf %s\\n "$*" ;}

test_env="$npm_package_config_test_ENV"
test_files="$npm_package_config_test_files"
mocha_ui="$npm_package_config_mocha_ui"
mocha_reporter="$npm_package_config_mocha_reporter"

if [ "$PRE_COMMIT" = "true" ]; then
   mocha_reporter='dot'
   RESPECT_TRACING='no'
fi

if [ -n "${RESPECT_TRACING##[NFnf]*}" ]; then
   trace_reactor='no'
   verbose='4'          # 'warning' and worse
fi

# FIXME: This should really support comma-seperated DEBUG values, as per `node-debug`:
#        https://github.com/visionmedia/debug
[ "$DEBUG" = 'Paws.js:scripts' ] && DEBUG_SCRIPTS=0
[ -n "$DEBUG_SCRIPTS" ] && puts "Script debugging enabled (in: `basename $0`)." >&2
[ -n "$DEBUG_SCRIPTS" ] && VERBOSE="${VERBOSE:-7}"

[ -n "$DEBUG_SCRIPTS" ] && puts \
   "Requested hook:        '$1'"                               \
   "Default hooks:         '$npm_package_config_git_hooks'"    \
   "" >&2


[ -z "${SILENT##[NFnf]*}${QUIET##[NFnf]*}" ] && [ "${VERBOSE:-4}" -gt 6 ] && set -x
set -e

env TRACE_REACTOR="$trace_reactor" VERBOSE="$verbose" \
    NODE_ENV="$test_env" ./node_modules/.bin/mocha    \
   --compilers coffee:coffee-script/register          \
   --reporter "$mocha_reporter" --ui "$mocha_ui"      \
   $MOCHA_FLAGS "$test_files"

if [ -d "$PWD/$npm_package_config_dirs_rulebook" ]; then
   env TRACE_REACTOR="$trace_reactor" VERBOSE="$verbose"       \
       NODE_ENV="$test_env" ./node_modules/.bin/taper          \
      --runner "$PWD/Executables/paws.js"                      \
      --runner-param='check'                                   \
      "$PWD/$npm_package_config_dirs_rulebook/The Ladder/"*    \
      "$PWD/$npm_package_config_dirs_rulebook/The Gauntlet/"*  \
      $TAPER_FLAGS -- $CHECK_FLAGS
   
if [ -n ${RUN_LETTERS+x} ]; then
   env TRACE_REACTOR="$trace_reactor" VERBOSE="$verbose"       \
       NODE_ENV="$test_env" ./node_modules/.bin/taper          \
      --runner "$PWD/Executables/paws.js"                      \
      --runner-param='check'                                   \
      --runner-param='--expose-specification'                  \
      "$PWD/$npm_package_config_dirs_rulebook/The Letters/"*   \
      $TAPER_FLAGS -- $CHECK_FLAGS $RULEBOOK_FLAGS
   
fi

else
   puts 'Clone the rulebook from this URL to `./'$npm_package_config_dirs_rulebook'` to check Rulebook compliance:'
   puts '   <https://github.com/Paws/Rulebook.git>'
fi
