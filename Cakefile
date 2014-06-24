_       = require 'lodash'

option '-g', '--grep [PATTERN]', '(test) see `mocha --help`'
option '-i', '--invert',         '(test) see `mocha --help`'
option '-r', '--reporter [REP]', '(test) specify Mocha reporter to display test results'
option '-t', '--tests',          '(compile:client) include tests in the bundle'
option '-W', '--wait',           '(*:open) open browser and wait'
option '-a', '--browser [BROW]', '(*:open) select browser to use'

Package = require './package.json'
config  = Package.config


# I try to use standard `make`-target names for these tasks.
# See: http://www.gnu.org/software/make/manual/make.html#Standard-Targets
task 'test', 'run testsuite through Mocha', (options) ->
   Mocha = require 'mocha'
   glob  = require 'glob'
   path  = require 'path'
   
   require 'coffee-script/register'
   
   mocha = new Mocha config.mocha
   
   mocha.invert() if options.invert
   mocha.grep options.grep if options.grep?
   
   glob path.join(config.dirs.test, config.mocha.files), (err, files)->
      files.forEach (file)-> mocha.addFile file
      mocha.run (failures)-> process.on 'exit', (status)->
         if status == 0 and failures
            process.exit 1


# TODO: Only works on OS X, right now. Needs Windows and Linux alternatives to `open`.
open_wait_task = (opts, path) ->
   {spawn}  = require 'child_process'
   browser = spawn 'open',
      _.compact [ path, '-a', opts.browser ? config.docco.browser, (if opts.wait then '-W') ]
   
   if opts.wait
      browser.on 'exit', -> invoke 'clean'

task 'test:client', (options) ->
   options.tests = true
   
   invoke 'compile:client'
   invoke 'test:client:open'

task 'test:client:open', (options) ->
   open_wait_task options, require('path').join config.dirs.documentation, 'tests.html'

task 'compile:client', "bundle JavaScript through Browserify", (options) ->
   browserify = require 'browserify'
   coffeeify  = require 'coffeeify'
   glob       = require 'glob'
   path       = require 'path'
   fs         = require 'fs'
   
   bundle = browserify()
     #watch: options.watch # FIXME: Lost in 1.0 -> 2.0
     #cache: true # FIXME: Lost in 1.0 -> 2.0
     #exports: ['require', 'process'] # FIXME: Lost in 1.0 -> 2.0
   bundle.transform coffeeify
   
   bundle.ignore 'blessed'
   
   bundle.add path.resolve process.cwd(), config.dirs.source, 'Paws.coffee'
   if options.tests
      for file in glob.sync path.join(config.dirs.test, config.mocha.files)
         bundle.add path.resolve process.cwd(), file
   
   bundle.bundle(debug: yes).pipe fs.createWriteStream(
      Package.main.replace(/(?=\.(?:js|coffee))|$/, '.bundle') )


# Requires Pygments, so that's a mess. ಠ_ಠ
task 'docs', 'generate HTML documentation via Docco', (options) ->
   { document: docco } = require 'docco'
   glob           = require 'glob'
   path           = require 'path'
   
   glob path.join(config.dirs.source, config.docco.files), (err, files)->
   #  docco _.flatten [ null, null, files,
   #     '--output', config.dirs.documentation ]
      docco {
         args:   files   # It's stupid that this can't be called as `sources`.
         output: config.dirs.documentation
      }, (error)->
         throw error if error
         invoke 'docs:open' if options.wait

task 'docs:open', (options) ->
   path = require 'path'
   open_wait_task options, path.join config.dirs.documentation, 'Paws.html'
