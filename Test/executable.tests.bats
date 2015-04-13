#!/usr/bin/env bats
load 'support'

export COLOUR=no

# Usage
# =====
@test 'The executable exists as `paws.js`' {
   command -v paws.js
}


@test 'The executable responds to `--version`' {
   run paws.js --version
   [ "$status" -eq 1 ]
   [ -n "$output" ]
}

@test '`--version` includes the name of the package' {
   run paws.js --version
   contains "$output" 'Paws.js'
}


@test 'The executable responds to `--help`' {
   run paws.js --help
   [ "$status" -eq 1 ]
   [ -n "$output" ]
}

@test 'Invocation of the executable with no arguments prints the usage' {
   run paws.js
   [ "$status" -eq 1 ]
   contains "$output" '--help'
}


@test '`--help` spreads the love' {
   run paws.js --help
   contains "$output" 'I love you'
}

@test '`--help` describes usable operations' {
   run paws.js --help
   contains "$output" 'interact'
}

@test '`--help` describes some available flags' {
   run paws.js --help
   contains "$output" '--expression'
}

@test '`--help` lists environment variables as well' {
   run paws.js --help
   contains "$output" 'SILENT'
}

@test '`--help` tells users where to get more help' {
   run paws.js --help
   contains "$output" 'https://github.com/ELLIOTTCABLE/Paws.js'
}


# Flags
# =====
@test '`-V` enabes verbose output' {
   run paws.js -V
   contains "$output" '-- Flags:'
}


# `parse`
# =======
@test 'The executable accepts `parse` as an operation' {
   file="$(tempfile)"
   run paws.js parse "$file"

   [ "$status" -eq 0 ]
}

@test '`parse` re-serializes the original Script' {
   file="$(tempfile)"
   echo 'foo   bar' >"$file"
   run paws.js parse "$file"

     contains "$output" 'bar'
   ! contains "$output" '   '
}


# `check`
# =======
@test 'The executable accepts `check` as an operation' {
   file="$(tempfile)"

   run paws.js check "$file"

   [ "$status" -eq 0 ]
   contains "${lines[0]}" 'TAP'
}

@test '`check` executes rules' {
   file="$(tempfile)"
   cat >"$file" <<book
specification rule[] “something” {
   pass[]
}
book

   run paws.js check "$file"

   [ "$status" -eq 0 ]
   [ -n "${lines[1]}" ]
   contains "${lines[1]}" 'ok'
}

@test '`check` exits non-zero if rules fail' {
   file="$(tempfile)"
   cat >"$file" <<book
specification rule[] “something” {
   fail[]
}
book

   run paws.js check "$file"

   [ "$status" -eq 1 ]
   [ -n "${lines[1]}" ]
   contains "${lines[1]}" 'not ok'
}

@test '`check` reads rulebooks written in YAML' {
   file="$(tempfile).rules.yaml"
   cat >"$file" <<book
%YAML 1.2 # Paws Rulebook
A book:
 - name: "something"
   body: pass[]
book

   run paws.js check "$file"

   [ "$status" -eq 0 ]
   [ -n "${lines[1]}" ]
   contains "${lines[1]}" 'ok'
}

@test '`check` accepts `--expose-specification` for self-testing' {
   file="$(tempfile).rules.yaml"
   cat >"$file" <<book
%YAML 1.2 # Paws Rulebook
A book:
 - name: "has specification"
   body: |
      specification;
      pass[]
   eventually: fail[]
book

   run paws.js check "$file"

   [ "$status" -eq 1 ]
   [ -n "${lines[1]}" ]
   [ "${lines[1]}" == "not ok 1 has specification" ]

   run paws.js check --expose-specification "$file"

   [ "$status" -eq 0 ]
   [ -n "${lines[1]}" ]
   [ "${lines[1]}" == "ok 1 has specification" ]
}
