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
#    INTEGRATION=no npm test              # Run the unit-tests *only* (not the integration tests)
#
#    BATS=no npm test                     # Disable execution of any shell-tests
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
argq() { [ $# -gt 0 ] && printf "'%s' " "$@" ;}

# shellcheck disable=SC2154
{
   source_dir="$npm_package_config_dirs_source"
   bin_dir="$npm_package_config_dirs_bin"
   unit_dir="$npm_package_config_dirs_test"
   integration_dir="$npm_package_config_dirs_integration"
   rulebook_dir="$npm_package_config_dirs_rulebook"
   coverage_dir="$npm_package_config_dirs_coverage"

   mocha_ui="$npm_package_config_mocha_ui"
   mocha_reporter="$npm_package_config_mocha_reporter"

   node_version="$npm_config_node_version"
}

cache_file="$unit_dir/.tests-succeeded"

# ‘cache results’
cr=yes

export NODE_ENV='test'

# FIXME: This should support *excluded* modules with a minus, as per `node-debug`:
#        https://github.com/visionmedia/debug
if echo "$DEBUG" | grep -qE '(^|,\s*)(\*|Paws.js(:(scripts|\*))?)($|,)'; then       # 1.  $DEBUG_SCRIPTS
   pute "Script debugging enabled (in: $(basename "$0"))."
   DEBUG_SCRIPTS=yes
   VERBOSE="${VERBOSE:-7}"
fi


# Configuration-variable setup
# ----------------------------
# The continuous-integration system on Travis is special-cased. See the header of `travis.sh` for
# more details about how all of this interacts.
if [ -n "${CI##[NFnf]*}" ]; then                                              cr=no # 2.  $CI
   [ -n "$DEBUG_SCRIPTS" ] && pute "Enabling CI mode."

   #mocha_reporter="..." # This is manually manipulated in `travis.sh`
   BATS_FLAGS="$BATS_FLAGS --tap"

   # In CI-mode, the runners *default* to being exclusive of eachother, except when generating final
   # coverage after a successful build.
   if   [ -n "${COVERAGE##[NFnf]*}" ]; then
      UNIT="${UNIT:-yes}"
      BATS="${BATS:-yes}"
      RULEBOOK="${RULEBOOK:-yes}"
      LETTERS="${LETTERS:-yes}"

   elif [ -n "${RULEBOOK##[NFnf]*}" ]; then
      UNIT="${UNIT:-no}"
      BATS="${BATS:-no}"
      LETTERS="${LETTERS:-yes}"
   elif [ -n "${BATS##[NFnf]*}" ]; then
      UNIT="${UNIT:-no}"
      RULEBOOK="${RULEBOOK:-no}"
   else
      UNIT="${UNIT:-yes}"
      BATS="${BATS:-no}"
      RULEBOOK="${RULEBOOK:-no}"
   fi

elif [ -n "${PRE_COMMIT##[NFnf]*}" ]; then                                    cr=no # 3.  $PRE_COMMIT
   [ -n "$DEBUG_SCRIPTS" ] && pute "Enabling pre-commit mode."

   mocha_reporter="dot"             # Be quiet,
   COVERAGE_REPORTER='text-summary'
   RESPECT_TRACING=no               # if the user has a ‘loud’ environment configured, ignore it,
   RULEBOOK=no                      # don't guarantee that the Rulebook passes on every commit,
   BATS=no                          # nor executable-integration-tests,
   INTEGRATION=no                   # nor integration-tests;
   UNIT=yes COVERAGE=yes            # ... but run all of the unit-tests and calculate coverage.

else
   [ -n "$DEBUG_SCRIPTS" ] && pute "Running in interactive-invocation mode."

   # When raw arguments are passed (presumably, for `mocha`) or the Node debugger is enabled, we
   # default to not running the other suites.
   if [ -n "$*" ] || [ -n "${DEBUGGER##[NFnf]*}" ]; then                      cr=no
      [ -z "$BATS" ]       && BATS=no                                               # 4.  $BATS
      [ -z "$RULEBOOK" ]   && RULEBOOK=no                                           # 5.  $RULEBOOK
   fi

   # If you're running the (slow) BATS integration-suite, *and* running the rest of the unit tests,
   # there's no reason whatsoever not to also run the mocha integration tests.
   [ -z "${BATS##[YTyt]*}" ]           && INTEGRATION=yes                           # 6.  $INTEGRATION

   if [ -n "${DEBUGGER##[NFnf]*}" ]; then                                     cr=no # 7.  $DEBUGGER
      debugging=yes

      # FIXME: It's actually specifiaclly Node v6.3.0 that first introduced native `--inspect`
      #        support; I need to do a true semver comparison for this — this will fail between
      #        v6.0.0 and v6.3.0.
      [ "${node_version%%.*}" -lt 6 ] && \
         debug_with_module=yes

      WATCH='no'

      if [ -n "$debug_with_module" ]; then
         if [ ! -x "./node_modules/.bin/node-debug" ]; then
            pute 'You must `npm install node-inspector` to use the $DEBUGGER flag on Node versions'
            pute '   prior to v6.3.0.'
            exit 127
         fi

         [ -z "${DEBUG_MODULES##[NFnf]*}" ] && \
            hidden='--hidden node_modules/'

         invocation_guard="./node_modules/.bin/node-debug $hidden --cli --config \
            './Scripts/node-inspectorrc.json'"
      else
         invocation_guard="node --inspect-brk"
      fi
   fi

   if [ -n "${WATCH##[NFnf]*}" ]; then                                              # 8. $WATCH
      [ ! -x "./node_modules/.bin/chokidar" ] &&
         pute 'You must `npm install chokidar-cli` to use the $WATCH flag!' && exit 127
   fi
fi

# Aliases so I can stop tying `YTyt` :P
[ -z "${INTEGRATION##[YTyt]*}" ]    && integration=yes
[ -n "${COVERAGE##[NFnf]*}" ]       && coverage=yes


# Verbosity and printing configuration
# ------------------------------------
if [ -n "${RESPECT_TRACING##[YTyt]*}" ]; then                                    # 9.  $RESPECT_TRACING
   [ -n "$DEBUG_SCRIPTS" ] && pute "Disrespecting tracing flags"
   VERBOSE=4            # 'warning' and worse
   unset TRACE_REACTOR
fi
                                                                                 # 10. $print_commands
[ -z "${SILENT##[NFnf]*}${QUIET##[NFnf]*}" ] && [ "${VERBOSE:-4}" -gt 6 ] && print_commands=yes

[ -n "$DEBUG_SCRIPTS" ] && puts \
   "Pre-commit mode:       ${PRE_COMMIT:--}"                                  \
   "CI (Travis) mode:      ${CI:--}"                                          \
   "Caching results:       ${cr:--}"                                          \
   "" \
   "Tracing reactor:       ${TRACE_REACTOR:+Yes!}"                            \
   "Watching filesystem:   ${WATCH:--}"                                       \
   "Running debugger:      ${DEBUGGER:--}"                                    \
   "Using node-inspector:  ${debug_with_module:-No!}"                         \
   "Generating coverage:   ${COVERAGE:--}"                                    \
   "Debugging modules:     ${DEBUG_MODULES:--}"                               \
   "" \
   "Verbosity:            '$VERBOSE'"                                         \
   "Printing commands:     ${print_commands:--}"                              \
   "" \
   "Tests dir:            '$unit_dir'"                                        \
   "Integration dir:      '$integration_dir'"                                 \
   "Rulebook dir:         '$rulebook_dir'"                                    \
   "Coverage dir:         '$coverage_dir'"                                    \
   "" \
   "Running units:         ${UNIT:--}"                                        \
   "Running shell tests:   ${BATS:--}"                                        \
   "Running integration:   ${INTEGRATION:--}"                                 \
   "Checking rulebook:     ${RULEBOOK:--}"                                    \
   "Checking letters:      ${LETTERS:--}"                                     \
   "" >&2

[ -n "$DEBUG_SCRIPTS" ] && [ "${VERBOSE:-4}" -gt 8 ] && \
   pute "Environment variables:" && env >&2

# Helper-function setup
# ---------------------
go () { [ -n "$print_commands" ] && puts '`` '"$*" >&2 ; "$@" || exit $? ;}

mochaify() {
   export TS_NODE_PROJECT='./Test/tsconfig.json'

   # shellcheck disable=SC2086
   [ -z "${UNIT##[YTyt]*}" ] && go $invocation_guard                          \
      "./node_modules/.bin/${invocation_guard:+_}${coverage:+_}mocha"         \
      ${debugging:+ --no-timeouts }                                           \
      ${coverage:+ --require './Library/register-coffee-coverage.js' }        \
      --require mocha-clean/brief                                             \
      --require coffee-script/register                                        \
      --require ts-node/register                                              \
      --reporter "$mocha_reporter" --ui "$mocha_ui"                           \
      "$@"                                                                    ;}

batsify() {
   if [ -z "${BATS##[YTyt]*}" ] && command -v bats >/dev/null; then
      # shellcheck disable=SC2086
      go bats --pretty $BATS_FLAGS "$@"                                       ;fi ;}

ruleify() {
   book="$1"; shift

   if [ -d "$PWD/$rulebook_dir/$book/" ]; then
      # shellcheck disable=SC2086
      go $invocation_guard ./node_modules/.bin/taper                          \
         --runner "$PWD/Executables/paws.js" --runner-param='check'           \
         "$PWD/$rulebook_dir/$book"/*                                         \
         $TAPER_FLAGS -- $CHECK_FLAGS "$@"                                    ;fi ;}

cache() {
   shasum "$source_dir"/* "$bin_dir"/* "$unit_dir"/* "$integration_dir"/* 2>/dev/null
}

gen_cache() {
   if [ "$cr" != 'no' ]; then
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
   pute 'Pre-commit: Using cached test exit-status from recent `npm test`!'
   exit 0
fi

if [ -n "${WATCH##[NFnf]*}" ]; then
   [ "${VERBOSE:-4}" -gt 7 ] && chokidar_verbosity='--verbose'

   unset WATCH COVERAGE DEBUGGER
   export UNIT BATS INTEGRATION RULEBOOK LETTERS VERBOSE TRACE_REACTOR

   # shellcheck disable=SC2086
   go exec chokidar \
      "${chokidar_verbosity:---silent}"                                       \
      --initial --ignore '**/.*'                                              \
      "$source_dir" "$bin_dir" "$unit_dir"                                    \
      ${integration:+"$integration_dir"} ${RULEBOOK:+"$rulebook_dir"}         \
      $CHOKIDAR_FLAGS -c "$0 $(argq "$@")"
fi


# Execution of tests
# ------------------                                                             # i) Mocha,
# shellcheck disable=SC2140
mochaify \
   "$unit_dir"/*.tests.coffee "$unit_dir"/*.tests.ts \
   ${integration:+"$integration_dir/"*.tests.coffee "$integration_dir/"*.tests.ts} "$@"

                                                                                 # ii) Istanbul,
[ -n "$coverage" ] && istanbul report --config='Scripts/istanbul.config.js' $COVERAGE_REPORTER

batsify "$unit_dir"/*.tests.bats ${integration:+"$integration_dir/"*.tests.bats}

if ! command -v bats >/dev/null; then
   [ -n "$DEBUG_SCRIPTS" ] && pute '`bats` not installed.'

   puts 'Install `bats` to run the executable'\''s tests and CLI integration tests:'
   puts '   <https://github.com/sstephenson/bats>'

   # If explicitly requested, then the command missing is a fatal error.
   [ -n "${BATS##[NFnf]*}" ] && exit 10
fi

if [ -z "${RULEBOOK##[YTyt]*}" ]; then
   ruleify "The Ladder"                                                          # iv) Rulebooks,
   ruleify "The Gauntlet"
   [ -n "${LETTERS##[NFnf]*}" ] && \
      ruleify "The Letters" --expose-specification

   if [ ! -d "$PWD/$rulebook_dir" ]; then
      [ -n "$DEBUG_SCRIPTS" ] && pute "Rulebook directory not found."

      puts 'Clone the rulebook from this URL to `./'"$rulebook_dir"'` to check Rulebook compliance:'
      puts '   <https://github.com/Paws/Rulebook.git>'

      # If explicitly requested, then the Rulebook missing is a fatal error.
      [ -n "${RULEBOOK##[NFnf]*}" ] && exit 11
   fi
fi

gen_cache                                                                        # v) cache!
