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
#    npm test -- --grep 'Parser'          # Run a specific unit-test suite
#    BATS=no npm test                     # Disable execution of any shell-tests
#    INTEGRATION=no npm test              # Run the unit-tests *only* (not the integration tests)
#    RULEBOOK=no npm test                 # Ignore the Rulebook, even if present
#    LETTERS=yes npm test                 # Execute the Letters, as well as the rest of the Rulebook
#
#    WATCH=yes npm test                   # Watch filesystem for changes, and automatically re-run
#    DEBUGGER=yes npm test                # Expose the Blink debugger-tools on localhost:8080
#    COVERAGE=yes npm test                # Generate a coverage report with Istanbul
#    RESPECT_TRACING=no npm test          # Disable debugging and tracing during the tests
#
# Given `$COVERAGE`, a coverage-report will be constructed as the test suites execute. By default,
# this results in an HTML page (`Docs/Coverage/index.html`), and a textual summary along with the
# test-output.
#
# If the tests pass as invoked, then a `.tests-succeeded` file is created to cache this status, with
# SHA-sums of the source-code and test files; this cache allows automatic pre-commit runs to be
# omitted when tests have been already run. (NOTE: This intentionally ignores `--grep` and other
# flags; meaning that it's possible to commit broken code by excluding broken tests!)

puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}
argq() { printf "'%s' " "$@" ;}

source_dir="$npm_package_config_dirs_source"
unit_dir="$npm_package_config_dirs_test"
integration_dir="$npm_package_config_dirs_integration"
rulebook_dir="$npm_package_config_dirs_rulebook"
coverage_dir="$npm_package_config_dirs_coverage"

mocha_ui="$npm_package_config_mocha_ui"
mocha_reporter="$npm_package_config_mocha_reporter"

cache_file="$unit_dir/.tests-succeeded"

export NODE_ENV='test'

# FIXME: This should support *excluded* modules with a minus, as per `node-debug`:
#        https://github.com/visionmedia/debug
echo "$DEBUG" | grep -qE '(^|,\s*)(\*|Paws.js(:(scripts|\*))?)($|,)' && DEBUG_SCRIPTS=0
[ -n "$DEBUG_SCRIPTS" ] && pute "Script debugging enabled (in: `basename $0`)."
[ -n "$DEBUG_SCRIPTS" ] && VERBOSE="${VERBOSE:-7}"

# Configuration-variable setup
# ----------------------------
if [ -n "${CI##[NFnf]*}" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Enabling CI mode."

   # The Travis parallelizes across a matrix; and each invocation runs only a single suite.
   [ -z "${VAR##[NFnf]*}" ] && [ -n "${BATS##[NFnf]*}${RULEBOOK##[NFnf]*}" ] && non_mocha=yes
fi

if [ -n "${PRE_COMMIT##[NFnf]*}" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Enabling pre-commit mode."
   mocha_reporter=dot
   WATCH=no
   DEBUGGER=no
   RESPECT_TRACING=no
   INTEGRATION=no
   RULEBOOK=no
fi

# Conveniences so I don't have to keep typing `YTyt` :P
[ -z "${INTEGRATION##[YTyt]*}" ]    && integration=yes
[ -n "${COVERAGE##[NFnf]*}" ]       && coverage=yes

# When raw arguments are passed for `mocha`, don't run the other suites
[ -n "$*" ] && [ -z "$BATS" ]       && BATS=no
[ -n "$*" ] && [ -z "$RULEBOOK" ]   && RULEBOOK=no

if [ -n "${RESPECT_TRACING##[YTyt]*}" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Disrespecting tracing flags"
   VERBOSE='4'          # 'warning' and worse
   unset TRACE_REACTOR
fi

if [ -n "${DEBUGGER##[NFnf]*}" ]; then
   [ ! -x "./node_modules/.bin/node-debug" ] && \
      pute 'You must `npm install node-inspector` to use the $DEBUGGER flag!' && exit 127

   WATCH='no'

   [ -z "${DEBUG_MODULES##[NFnf]*}" ] && hidden='--hidden node_modules/'
   node_debugger="./node_modules/.bin/node-debug $hidden --cli --config './Scripts/node-inspectorrc.json'"
fi

if [ -n "${WATCH##[NFnf]*}" ]; then
   [ ! -x "./node_modules/.bin/chokidar" ] &&
      pute 'You must `npm install chokidar-cli` to use the $WATCH flag!' && exit 127
fi

[ -z "${SILENT##[NFnf]*}${QUIET##[NFnf]*}" ] && [ "${VERBOSE:-4}" -gt 6 ] && print_commands=yes

[ -n "$DEBUG_SCRIPTS" ] && puts \
   "Pre-commit mode:       ${PRE_COMMIT:--}"                                  \
   "Tracing reactor:       ${TRACE_REACTOR:+Yes!}"                            \
   "Watching filesystem:   ${WATCH:--}"                                       \
   "Running debugger:      ${DEBUGGER:--}"                                    \
   "Generating coverage:   ${COVERAGE:--}"                                    \
   "Debugging modules:     ${DEBUG_MODULES:--}"                               \
   "Verbosity:             '$VERBOSE'"                                        \
   "Printing commands:     ${print_commands:--}"                              \
   "Tests directory:       '$unit_dir'"                                       \
   "Integration directory: '$integration_dir'"                                \
   "Rulebook directory:    '$rulebook_dir'"                                   \
   "Coverage directory:    '$coverage_dir'"                                   \
   "Running "'`bats`'" tests:  ${BATS:--}"                                    \
   "Running integration:   ${INTEGRATION:--}"                                 \
   "Checking rulebook:     ${RULEBOOK:--}"                                    \
   "Checking letters:      ${LETTERS:--}"                                     \
   "" >&2


# Helper-function setup
# ---------------------
go () { [ -z ${print_commands+0} ] || puts '`` '"$*" >&2 ; "$@" || exit $? ;}

mochaify() {
   [ -z $non_mocha ] && go $node_debugger                                     \
      "./node_modules/.bin/${node_debugger:+_}${coverage:+_}mocha"            \
      ${node_debugger:+ --no-timeouts }                                       \
      ${coverage:+ --require './Library/register-coffee-coverage.js' }        \
      --compilers coffee:coffee-script/register                               \
      --reporter "$mocha_reporter" --ui "$mocha_ui"                           \
      "$@"                                                                    ;}

batsify() {
   if [ -z "${BATS##[YTyt]*}" ] && command -v bats >/dev/null; then
      go bats --pretty $BATS_FLAGS "$@"                                       ;fi ;}

ruleify() {
   book="$1"; shift

   if [ -z "${RULEBOOK##[YTyt]*}" ] \
   && [ -d "$PWD/$rulebook_dir/$book/" ]; then
      go env NODE_ENV=test $node_debugger ./node_modules/.bin/taper           \
         --runner "$PWD/Executables/paws.js" --runner-param='check'           \
         "$PWD/$rulebook_dir/$book"/*                                         \
         $TAPER_FLAGS -- $CHECK_FLAGS "$@"                                    ;fi ;}

cache() {
   shasum "$source_dir"/* "$unit_dir"/* "$integration_dir"/* 2>/dev/null      ;}

gen_cache() {
  #if [ -z "${WATCH##[NFnf]*}" ] && [ -z "${INTEGRATION##[YTyt]*}" ]; then
   if [ -z "${WATCH##[NFnf]*}" ]; then
      [ -n "$DEBUG_SCRIPTS" ] && pute "Generating cache of successful test-status"
      cache >"$cache_file"
      true                                                                    ;fi ;}

check_cache() {
   if [ -n "$DEBUG_SCRIPTS" ]; then
      pute "Checking test-status cache"
      [ -f "$cache_file" ] && shasum -c "$cache_file"
   else
      [ -f "$cache_file" ] && shasum -c "$cache_file" >/dev/null 2>&1         ;fi ;}


# Pre-execution
# -------------
if [ -n "${PRE_COMMIT##[NFnf]*}" ] && check_cache; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Pre-commit: Using existing test exit-status."
   exit 0
fi

if [ -n "${WATCH##[NFnf]*}" ]; then
   [ "${VERBOSE:-4}" -gt 7 ] && chokidar_verbosity='--verbose'

   unset WATCH
   export VERBOSE TRACE_REACTOR BATS INTEGRATION RULEBOOK LETTERS
   go exec chokidar \
      "$source_dir" "$unit_dir" ${integration:+"$integration_dir"} ${RULEBOOK:+"$rulebook_dir"} \
      "${chokidar_verbosity:---silent}"                                       \
      --initial --ignore '**/.*'                                              \
      $CHOKIDAR_FLAGS -c "$0 $(argq "$@")"
fi


# Execution of tests
# ------------------
if [ -n "$integration" ]
   then mochaify "$unit_dir"/*.tests.coffee "$integration_dir/"*.tests.coffee "$@"
   else mochaify "$unit_dir"/*.tests.coffee "$@"
fi

[ -n "$coverage" ] && istanbul report --config='Scripts/istanbul.config.js' $COVERAGE_REPORTER

if [ -n "$integration" ]
   then batsify "$unit_dir"/*.tests.bats "$integration_dir/"*.tests.bats
   else batsify "$unit_dir"/*.tests.bats
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

if [ ! -d "$PWD/$rulebook_dir" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Rulebook directory not found."

   puts 'Clone the rulebook from this URL to `./'$rulebook_dir'` to check Rulebook compliance:'
   puts '   <https://github.com/Paws/Rulebook.git>'
fi

gen_cache
