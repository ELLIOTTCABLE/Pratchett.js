#!/usr/bin/env sh
                                                                              set +o verbose
# Usage:
# ------
# This script exists solely for [Travis CI] to run our test-suite. There should be no need to invoke
# it interactively.
#
#    ./Scripts/travis.sh --prep
#    ./Scripts/travis.sh --test
#
# (Of especial note, `$PATH` modifications *cannot* be done inside this script; they must be
#  hardcoded into `.travis.yml.`)
#
# The CI setup here is fairly complicated:
#  - The Travis environment needs a little cleaning, updating, and setting-up before e can
#    effectively test: `travis.sh --prep` performs this setup.
#
#  - Travis invokes this script (via `npm run-script ci`) a large number of times; this is the
#    “build matrix.” When `npm test` is run locally, a series of test-suites are usually run
#    (unit-tests, integration tests, Rulebook tests ...); but Travis *parallelizes* these across the
#    matrix (and across dependency versions.)
#
#    This script ensures that each Travis worker only runs the single suite that was indicated (that
#    is, usually `BATS=yes npm test` doesn't imply that `UNIT=no`; but when `CI` is enabled, that
#    behaviour is inverted: explicitly enabling any suite *disables all other suites*.)
#
#  - Finally, `--after` (thanks to `travis-after-all`) invokes *the entire test-suite* again, unit,
#    integration, rulebooks, and all; enabling coverage-generation while doing so. It then ships the
#    generated coverage-data off to Coveralls.io.
#
# XXX: Two version numbers (`coveralls` and `travis-after-all`) are hardcoded into this script!


puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}

# shellcheck disable=SC2154
{
   rulebook_dir="$npm_package_config_dirs_rulebook"
   coverage_dir="$npm_package_config_dirs_coverage"
}

coverage_file="./$coverage_dir/lcov.info"

# FIXME: This should support *excluded* modules with a minus, as per `node-debug`:
#        https://github.com/visionmedia/debug
if echo "$DEBUG" | grep -qE '(^|,\s*)(\*|Paws.js(:(scripts|\*))?)($|,)'; then
   pute "Script debugging enabled (in: $(basename "$0"))."
   DEBUG_SCRIPTS=yes
   VERBOSE="${VERBOSE:-7}"
fi

[ -z "${SILENT##[NFnf]*}${QUIET##[NFnf]*}" ] && [ "${VERBOSE:-4}" -gt 6 ] && print_commands=yes
go() { [ -z ${print_commands+0} ] || puts '`` '"$*" >&2 ; "$@" || exit $? ;}


for ARG; do case $ARG in
   --prep)
      [ -n "$DEBUG_SCRIPTS" ] && pute "Preforming Travis preperations"

      [ -n "$DEBUG_SCRIPTS" ] && pute "Installing travis-after-all ..."
      go npm install 'travis-after-all@^1.4.4'

      if [ -n "${COVERAGE##[NFnf]*}" ]; then
         UNIT="${UNIT:-yes}"
         BATS="${BATS:-yes}"
         RULEBOOK="${RULEBOOK:-yes}"

         [ -n "$DEBUG_SCRIPTS" ] && pute "Installing coveralls ..."
         go npm install 'coveralls@^2.11.6'
      fi

      if [ -n "${BATS##[NFnf]*}" ] && [ ! -e "$HOME/bats/bin/bats" ]; then
         [ -n "$DEBUG_SCRIPTS" ] && pute 'Installing `bats` ...'
         go git clone --depth 1 "https://github.com/sstephenson/bats.git" "./bats"
         go ./bats/install.sh "$HOME/bats"
      fi

      if [ -n "${RULEBOOK##[NFnf]*}" ]; then
         [ -n "$DEBUG_SCRIPTS" ] && pute "Cloning Rulebook ..."
         go git clone --depth 1 "https://github.com/Paws/Rulebook.git" "$rulebook_dir"
      fi

      exit 0;;

   --test)
      [ -n "$DEBUG_SCRIPTS" ] && pute "Invoking tests"

      export npm_package_config_mocha_reporter='list'

      CI=yes go ./Scripts/test.sh;;

   --after)
      [ -n "$DEBUG_SCRIPTS" ] && pute "Finishing up"

      # On the last Travis worker, if the overall build has succeeded, we re-run *all* the tests to
      # generate coverage information and submit it to Coveralls.io.
      if "$(npm bin)/travis-after-all"; then
         [ -n "$DEBUG_SCRIPTS" ] && pute "Matrix-build successful, generating coverage!"

         export CI=yes COVERAGE=yes
         export npm_package_config_mocha_reporter='dot'

         go ./Scripts/travis.sh --prep    # Re-prep the environment with `bats`, etc.
         go ./Scripts/test.sh

         [ -n "$DEBUG_SCRIPTS" ] && pute "Coverage taken, sending '$coverage_file' to Coveralls"
         [ -s "$coverage_file" ] || exit 66
         "$(npm bin)/coveralls" <"$coverage_file"
      else
         exit 0
      fi
      ;;

esac; done
