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
            npm install -g npm
            [ -n "$DEBUG_SCRIPTS" ] && pute '`npm` now at: ' $(npm --version) ;;
         *)
            [ -n "$DEBUG_SCRIPTS" ] && pute '`npm` appears up-to-date'
                                                                              ;; esac

      if [ ! -e "$HOME/bats/bin/bats" ]                                       ;then
         [ -n "$DEBUG_SCRIPTS" ] && pute 'Installing `bats` ...'
         go git clone --depth 1 "https://github.com/sstephenson/bats.git" "./bats"
         go ./bats/install.sh "$HOME/bats"
      else
         [ -n "$DEBUG_SCRIPTS" ] && pute 'Found `bats` in Travis cache'       ;fi

      go git clone --depth 1 "https://github.com/Paws/Rulebook.git" "./Test/Rulebook"
                                                                              ;;
   --test)
      [ -n "$DEBUG_SCRIPTS" ] && pute "Invoking tests"

      if [ -z "$BATS" ];      then export BATS='yes'                          ;fi
      if [ -z "$RULEBOOK" ];  then export RULEBOOK='yes'                      ;fi
      if [ -z "$LETTERS" ];   then export LETTERS='yes'                       ;fi

      go npm run-script test -- --reporter list
                                                                              ;;
   --after)
      go npm run-script coveralls
                                                                              ;; esac; done
