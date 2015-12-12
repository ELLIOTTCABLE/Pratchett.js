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


puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}

# FIXME: This should support *excluded* modules with a minus, as per `node-debug`:
#        https://github.com/visionmedia/debug
echo "$DEBUG" | grep -qE '(^|,\s*)(\*|Paws.js(:(scripts|\*))?)($|,)' && DEBUG_SCRIPTS=0
[ -n "$DEBUG_SCRIPTS" ] && pute "Script debugging enabled (in: `basename $0`)."
[ -n "$DEBUG_SCRIPTS" ] && VERBOSE="${VERBOSE:-7}"

[ -z "${SILENT##[NFnf]*}${QUIET##[NFnf]*}" ] && [ "${VERBOSE:-4}" -gt 6 ] && print_commands=yes
go() { [ -z ${print_commands+x} ] || puts '`` '"$*" >&2 ; "$@" || exit $? ;}


for ARG; do case $ARG in
   --prep)
      [ -n "$DEBUG_SCRIPTS" ] && pute "Preforming Travis preperations"

      case "$(npm --version)" in
         1.*)
            [ -n "$DEBUG_SCRIPTS" ] && pute 'Updating `npm`'
            go npm install -g npm
            [ -n "$DEBUG_SCRIPTS" ] && pute '`npm` now at: '"$(npm --version)";;
         *)
            [ -n "$DEBUG_SCRIPTS" ] && pute '`npm` appears recent'
                                                                              ;; esac
      [ -n "$DEBUG_SCRIPTS" ] && pute "Installing travis-after-all ..."
      npm install 'travis-after-all@^1.4.4'

      if [ -n "${BATS##[NFnf]*}" ] && [ ! -e "$HOME/bats/bin/bats" ]; then
         [ -n "$DEBUG_SCRIPTS" ] && pute 'Installing `bats` ...'
         go git clone --depth 1 "https://github.com/sstephenson/bats.git" "./bats"
         go ./bats/install.sh "$HOME/bats"
      fi

      if [ -n "${RULEBOOK##[NFnf]*}" ]; then
         [ -n "$DEBUG_SCRIPTS" ] && pute "Cloning Rulebook ..."
         go git clone --depth 1 "https://github.com/Paws/Rulebook.git" "./Test/Rulebook"
      fi

      exit 0;;

   --test)
      [ -n "$DEBUG_SCRIPTS" ] && pute "Invoking tests"

      export INTEGRATION=yes npm_package_config_mocha_reporter='list'

      if   [ -n "${BATS##[NFnf]*}" ];     then export RULEBOOK=no
      elif [ -n "${RULEBOOK##[NFnf]*}" ]; then export BATS=no LETTERS=yes
                                          else export BATS=no RULEBOOK=no     ;fi

      go ./Scripts/test.sh;;

   --after)
      [ -n "$DEBUG_SCRIPTS" ] && pute "Finishing up"

      export LETTERS=yes INTEGRATION=yes npm_package_config_mocha_reporter='dot'

      if true; then
         COVERAGE=yes go ./Scripts/test.sh
      else
         exit 0
      fi
      ;;

esac; done
