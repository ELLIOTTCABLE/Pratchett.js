#!/usr/bin/env sh
set -e

# Usage:
# ------

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


[ -z "${SILENT##[NFnf]*}${QUIET##[NFnf]*}" ] && [ "${VERBOSE:-4}" -gt 6 ] && set -x

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
   
fi ; fi
