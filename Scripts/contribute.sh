#!/usr/bin/env sh
                                                                              set +o verbose
# Usage:
# ------
# This script does some basic setup of a local git-clone of the repository, and displays some
# information for new contributors.
#
#    npm run-script contribute!

puts() { printf %s\\n "$@" ;}
pute() { printf %s\\n "~~ $*" >&2 ;}
argq() { printf "'%s' " "$@" ;}

rulebook_dir="$npm_package_config_dirs_rulebook"
repository_url="$(node -pe "require('./package').repository.url")"
#repository_url="$npm_package_repository_url" # Broken: <https://github.com/npm/npm/issues/10815>

export NODE_ENV='test'

# FIXME: This should support *excluded* modules with a minus, as per `node-debug`:
#        https://github.com/visionmedia/debug
if echo "$DEBUG" | grep -qE '(^|,\s*)(\*|Paws.js(:(scripts|\*))?)($|,)'; then    # 1.  $DEBUG_SCRIPTS
   pute "Script debugging enabled (in: `basename $0`)."
   DEBUG_SCRIPTS=yes
   VERBOSE="${VERBOSE:-7}"
fi

[ -z "${SILENT##[NFnf]*}${QUIET##[NFnf]*}" ] && [ "${VERBOSE:-4}" -gt 6 ] && print_commands=yes
go() { [ -z ${print_commands+0} ] || puts '`` '"$*" >&2 ; "$@" || exit $? ;}


# ### Repository set-up

[ ! -d ".git" ] && \
   puts "-- We use Git to collaborate on Paws.js; you'll have to obtain this project as a" \
        "   Git clone to get started contributing!"                           \
        "      \`git clone '${repository_url}'\`" >&2 && exit 1

if [ ! -d "Source/primatives" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Cloning submodules,"
   go git submodule update --init
fi

if [ ! -d "$rulebook_dir" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Cloning Rulebook,"
   go git clone 'https://github.com/Paws/Rulebook.git' "$rulebook_dir"
fi

if [ ! -d "./node_modules" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Installing dependencies,"
   go npm install --dev
fi

if [ ! -e ".git/hooks/pre-commit" ]; then
   [ -n "$DEBUG_SCRIPTS" ] && pute "Configuring local Git clone,"
   go npm run-script install-git-hooks
fi

[ -n "$DEBUG_SCRIPTS" ] && pute "Displaying CONTRIBUTING information!"
pager="${PAGER:-less --chop-long-lines}"
"$pager" ./CONTRIBUTING.markdown

puts ""                                                                       \
     "Thanks for reading all that! 😅"                                        \
     "Now, get started with your first contribution:"                         \
     ""                                                                       \
     "    git checkout --track Current -b my-awesome-feature+"                \
     ""
