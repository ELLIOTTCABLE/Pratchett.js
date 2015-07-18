#!/usr/bin/env sh
                                                                              set +o verbose
# Usage:
# ------
# This script runs both our test-suites, and, if they've been downloaded, checks conformance with
# the Paws rulebooks.
#
# Of note, our test suite is spread across three toolsets:
#
#  - `mocha`, to run most of the unit-tests and the the JavaScript API integration tests,
#  - `bats`, to run the executable's unit-tests as well as the CLI integration tests,
#  - and finally `paws.js check` itself (via `taper`) to check Rulebook conformance.
#
#    npm test
#
#    npm test --grep 'Parser'             # Run a specific unit-test suite
#    RESPECT_TRACING=no npm test          # Disable debugging and trcing during the tests
#    INTEGRATION=no npm test              # Ignore the Rulebook, even if present
#    RULEBOOK=no npm test                 # Ignore the Rulebook, even if present
#    LETTERS=yes npm test                 # To execute the Letters, as well

puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}

unit_dir="$npm_package_config_dirs_test"
integration_dir="$npm_package_config_dirs_integration"
rulebook_dir="$npm_package_config_dirs_rulebook"
mocha_ui="$npm_package_config_mocha_ui"
mocha_reporter="$npm_package_config_mocha_reporter"

# FIXME: This should support *excluded* modules with a minus, as per `node-debug`:
#        https://github.com/visionmedia/debug
echo "$DEBUG" | grep -qE '(^|,\s*)(\*|Paws.js(:(scripts|\*))?)($|,)' && DEBUG_SCRIPTS=0
[ -n "$DEBUG_SCRIPTS" ] && pute "Script debugging enabled (in: `basename $0`)."
[ -n "$DEBUG_SCRIPTS" ] && VERBOSE="${VERBOSE:-7}"

if [ -n "${PRE_COMMIT##[NFnf]*}" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Enabling pre-commit mode."
   mocha_reporter=dot
   RESPECT_TRACING=no
   INTEGRATION=no
   RULEBOOK=no
fi

if [ -n "$*" ] && [ -z "$BATS" ];      then BATS='no'    ;fi
if [ -n "$*" ] && [ -z "$RULEBOOK" ];  then RULEBOOK='no';fi

if [ -n "${RESPECT_TRACING##[YTyt]*}" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Disrespecting tracing flags"
   VERBOSE='4'          # 'warning' and worse
   unset TRACE_REACTOR
fi

[ -z "${SILENT##[NFnf]*}${QUIET##[NFnf]*}" ] && [ "${VERBOSE:-4}" -gt 6 ] && print_commands=yes
go () { [ -z ${print_commands+x} ] || puts '`` '"$*" >&2 ; "$@" || exit $? ;}

[ -n "$DEBUG_SCRIPTS" ] && puts \
   "Pre-commit mode:       ${PRE_COMMIT:--}"                                  \
   "Tracing reactor:       ${TRACE_REACTOR:+Yes!}"                            \
   "Verbosity:             '$VERBOSE'"                                        \
   "Printing commands:     ${print_commands:--}"                              \
   "Tests directory:       '$unit_dir'"                                       \
   "Integration directory: '$integration_dir'"                                \
   "Rulebook directory:    '$rulebook_dir'"                                   \
   "Running "'`bats`'" tests:  ${BATS:--}"                                    \
   "Running integration:   ${INTEGRATION:--}"                                 \
   "Checking rulebook:     ${RULEBOOK:--}"                                    \
   "Checking letters:      ${LETTERS:--}"                                     \
   "" >&2


mochaify() {
   go env NODE_ENV=test ./node_modules/.bin/mocha                             \
      --compilers coffee:coffee-script/register                               \
      --reporter "$mocha_reporter" --ui "$mocha_ui"                           \
      "$@"                                                                    ;}

batsify() {
   if [ -z "${BATS##[YTyt]*}" ] && command -v bats >/dev/null; then
      go bats --pretty $BATS_FLAGS "$@"                                       ;fi ;}

ruleify() {
   book="$1"; shift

   if [ -z "${RULEBOOK##[YTyt]*}" ] \
   && [ -d "$PWD/$npm_package_config_dirs_rulebook/$book/" ]; then
      go env NODE_ENV=test ./node_modules/.bin/taper                          \
         --runner "$PWD/Executables/paws.js"                                  \
         --runner-param='check'                                               \
         "$PWD/$npm_package_config_dirs_rulebook/$book"/*                     \
         $TAPER_FLAGS -- $CHECK_FLAGS "$@"                                    ;fi ;}


if [ -n "${INTEGRATION##[YTyt]*}" ]; then
   mochaify "$unit_dir"/*.tests.coffee "$@"
   batsify "$unit_dir"/*.tests.bats
else
   mochaify "$unit_dir"/*.tests.coffee "$integration_dir/"*.tests.coffee "$@"
   batsify "$unit_dir"/*.tests.bats "$integration_dir/"*.tests.bats
fi

if ! command -v bats >/dev/null; then
   [ -n "$DEBUG_SCRIPTS" ] && pute '`bats` not installed.'

   puts 'Install `bats` to run the executable'\''s tests and CLI integration tests:'
   puts '   <https://github.com/sstephenson/bats>'
fi

ruleify "The Ladder"
ruleify "The Gauntlet"
[ -n "${LETTERS##[NFnf]*}" ] && \
   ruleify "The Letters" --expose-specification

if [ ! -d "$PWD/$npm_package_config_dirs_rulebook" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Rulebook directory not found."

   puts 'Clone the rulebook from this URL to `./'$npm_package_config_dirs_rulebook'` to check Rulebook compliance:'
   puts '   <https://github.com/Paws/Rulebook.git>'
fi
