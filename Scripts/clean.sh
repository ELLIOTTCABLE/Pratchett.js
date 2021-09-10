#!/usr/bin/env sh

mv node_modules/ node_modules-PRECLEAN/
mv .coveralls.yml .coveralls.yml-PRECLEAN
git clean -Xdf
mv .coveralls.yml-PRECLEAN .coveralls.yml
mv node_modules-PRECLEAN/ node_modules/
