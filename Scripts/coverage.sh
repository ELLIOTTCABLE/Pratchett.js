#!/usr/bin/env sh
                                                                              set +o verbose
# Usage:
# ------
# This will run 'coffee-coverage' across the unit-test suite, and then generate HTML coverage to
# file-descriptor 3.
#
#     npm run-script coverage
#     # (This runs, effectively: `./Scripts/coverage.sh 3>./Library/coverage.html`)
puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}

unit_dir="$npm_package_config_dirs_test"
mocha_ui="$npm_package_config_mocha_ui"
mocha_reporter="$npm_package_config_mocha_reporter"

# FIXME: This should support *excluded* modules with a minus, as per `node-debug`:
#        https://github.com/visionmedia/debug
echo "$DEBUG" | grep -qE '(^|,\s*)(\*|Paws.js(:(scripts|\*))?)($|,)' && DEBUG_SCRIPTS=0
[ -n "$DEBUG_SCRIPTS" ] && pute "Script debugging enabled (in: `basename $0`)."
[ -n "$DEBUG_SCRIPTS" ] && VERBOSE="${VERBOSE:-7}"

if [ "$npm_package_config_mocha_reporter" != 'mocha-lcov-reporter' ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Using LCOV reporter"
   mocha_reporter='html-cov'
fi

[ -z "${SILENT##[NFnf]*}${QUIET##[NFnf]*}" ] && [ "${VERBOSE:-4}" -gt 6 ] && print_commands=yes
go () { [ -z ${print_commands+x} ] || puts '`` '"$*" >&2 ; "$@" || exit $? ;}

[ -n "$DEBUG_SCRIPTS" ] && puts \
   "Mocha reporter:        '$mocha_reporter'"                                 \
   "Tests directory:       '$unit_dir'"                                       \
   "" >&2


go env NODE_ENV=coverage ./node_modules/.bin/mocha                            \
   --compilers coffee:coffee-script/register                                  \
   --reporter "$mocha_reporter" --ui "$mocha_ui"                              \
   --require Library/register-handlers.js                                     \
   "$unit_dir"/*.tests.coffee "$@" >&3
