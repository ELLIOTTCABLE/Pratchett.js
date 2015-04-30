#!./node_modules/.bin/coffee
process.title = 'paws.js'

module.package = require '../package.json'
bluebird = require 'bluebird'
minimist = require 'minimist'
mustache = require 'mustache'
prettify = require('pretty-error').start()

path     = require 'path'
fs       = bluebird.promisifyAll require 'fs'

Paws     = require '../Library/Paws.js'
term     = Paws.utilities.terminal
_        = Paws.utilities._

out = process.stdout
err = process.stderr

heart = '💖 '
salutations = [
   'Paws loves you.'
   'ELLIOTTCABLE loves you, too.'
   "Don't be a stranger"
   'Miss you already'
   'You look amazing today!'
   'Best friends forever,'
   'Bye!'
]

# TODO: Ensure this works well for arguments passed to shebang-files
# TODO: Use minimist's aliasing-functionality
# TODO: Rename to `flags`
argf = minimist process.argv.slice(2), boolean: true
argv = argf._

# TODO: Support -VV / -VVV
if argf.V || argf.verbose
   Paws.VERBOSE 6


sources = _([argf.e, argf.expr, argf.expression])
   .flatten().compact().map (expression, i)-> { from: '--expression #' + i, code: expression }
   .value()

Paws.info "-- Arguments: ", argv.join(' :: ')
Paws.info "-- Flags: ", argf
Paws.info "-- Sources: ", sources

Paws.wtf "-- Environment variables:"
Paws.wtf process.env

choose = ->
   if (argf.help)
      return help()
   if (argf.version)
      return version()

   help() if _.isEmpty(argv[0]) and !sources.length

   switch operation = argv.shift()

      when 'pa', 'parse'
         go = -> _.forEach sources, (source)->
            Paws.info "-- Parse-tree for '#{term.bold source.from}':"
            seq = Paws.parse Paws.parse.prepare source.code
            out.write seq.serialize() + "\n"

         if _.isEmpty argv[0]
            go()
         else
            readSourcesAsync(argv).then (files)->
               sources.push files...
               go()

      # FIXME: Single TAP count / output, for all Collections
      # FIXME: OHFUCK, any input files need to be started *in serial*, despite asynchronicity
      when 'ch', 'check'
         {Collection} = require '../Source/rule.coffee'
         readSourcesAsync(argv).then (files)->
            # FIXME: Promisify this a bit more.
            _.forEach files, (file)->
               if /\.rules\.yaml$/i.test file.from then rule_file file else sources.push file

            _.forEach sources, (source)-> rule_unit source

         rule_file = (source)->
            Paws.info "-- Staging rules in '#{term.bold source.from}' from the command-line ..."
            _.forEach _.values(require('yamljs').parse source.code), (book)->
               collection = Collection.from book

               if argf['expose-specification'] == true
                  _.forEach collection.rules, (rule)->
                     rule.body.locals.inject Paws.primitives 'specification' 

               collection.report()
               collection.on 'complete', (passed)-> goodbye 1 unless passed
               collection.close()

         rule_unit = (source)->
            Paws.info "-- Staging '#{term.bold source.from}' from the command-line ..."
            root = Paws.generateRoot source.code, path.basename source.from, '.paws'
            root.locals.inject Paws.primitives 'specification' 

            # FIXME: Respect `--expose-specification` for the *bodies* of libside rules

            # FIXME: Rules created in libspace using the `specification` namespace will get added to
            #        the same `Collection` as the ‘root’ rules. This is fixed for YAML rulebooks,
            #        wherein we can specifically add the rulebook rules to their own collection, and
            #        then instantiate a new `Collection` for any rules created during the tests; but
            #        it's broken here. (This may not matter, as the only rulebooks actually
            #        *testing* `specification` functionality are currently, intentionally, in YAML.)
            collection = new Collection
            collection.report()
            collection.on 'complete', (passed)-> goodbye 1 unless passed

            here = new Paws.reactor.Unit

            # FIXME: This is a bit of a hack. Need a first-class citizen methdoology to predicate
            #        code on the completion of a Unit, *and* some better way to determine when to
            #        dispatch tests.
            here.on 'flushed', ->
               if root.complete()
                  collection.close()

            here.stage root
            here.start() if argf.start == true

      when 'in', 'interact', 'interactive'
         Interactive = require '../Source/interactive.coffee'
         interact = new Interactive
         interact.on 'close', -> goodbye 0
         interact.start()

      when 'st', 'start'
         go = -> _.forEach sources, (source)->
            Paws.info "-- Staging '#{term.bold source.from}' from the command-line ..."
            root = Paws.generateRoot source.code, path.basename source.from, '.paws'

            here = new Paws.reactor.Unit
            here.stage root

            here.start() unless argf.start == false

         if _.isEmpty argv[0]
            go()
         else
            readSourcesAsync(argv).then (files)->
               sources.push files...
               go()

      else argv.unshift('start', operation) and choose()

process.nextTick choose


# ---- --- ---- --- ----

help = -> readFilesAsync([extra('help.mustache'), extra('figlets.mustache.asv')]).then ([template, figlets])->
   figlets = records_from figlets

   divider = term.invert( new Array(Math.ceil((term.columns + 1) / 2)).join('- ') )

   prompt = '>'

   usage = divider + "\n" + _(figlets).sample() + template + divider
   #  -- standard 80-column terminal -------------------------------------------------|

   err.write mustache.render usage+"\n",
      heart: if Paws.colour() then heart else '<3'
      b: ->(text, r)-> term.bold r text
      u: ->(text, r)-> term.underline r text
      c: ->(text, r)-> if Paws.colour() then term.invert r text else '`'+r(text)+'`'

      op:   ->(text, r)-> term.fg 2, r text
      bgop: ->(text, r)-> term.bg 2, r text
      flag: ->(text, r)-> term.fg 6, r text
      bgflag: ->(text, r)-> term.bg 6, r text

      title: ->(text, r)-> term.bold term.underline r text
      link:  ->(text, r)->
         if Paws.colour() then term.sgr(34) + term.underline(r text) + term.sgr(39) else r text
      prompt: -> # Probably only makes sense inside {{pre}}. Meh.
         if Paws.colour()
            term.sgr(27) + term.csi('3D') + term.fg(7, prompt+' ') + term.sgr(7) + term.sgr(90)
         else prompt
      pre:  ->(text, r)-> term.block r(text), (line, _, sanitized)->
         line = if Paws.colour() and sanitized.charAt(0) == prompt
            line.slice 0, -3 # Compensate for columns lost to `prompt`'s ANSI ‘CUB’
         else
            line.slice 0, -6

         if Paws.colour()
            "   #{term.invert term.fg 10, " #{line}"}   "
         else
            "   #{line}"

   version()

version = ->
   # TODO: Extract this `git describe`-style, platform-independant?
   release      = module.package['version'].split('.')[0]
   release_name = module.package['version-name']
   spec_name    = module.package['spec-name']
   err.write """
      Paws.js release #{release}, “#{release_name}”
         conforming to: #{spec_name}
   """ + "\n"
   process.exit 1

debugging.ENV 'BLINK'
goodbye = (code = 0)->
   if debugging.verbosity() >= debugging.verbosities['error']
      salutation = _(salutations).sample()
      salutation = ' ~ '+salutation+' '+ (if Paws.colour() then heart else '<3')

      if Paws.colour()
         err.write term.tput.column_address term.columns - salutation.length
         err.write term.tput.clr_eol()
         err.write term.tput.enter_blink_mode() unless debugging.blink()
         err.write if term.tput.max_colors == 256 then term.xfg 219, salutation else term.fg 5, salutation
      else
         err.write "\n"
         err.write salutation

   err.write "\n"
   process.exit code

process.on 'SIGINT', -> goodbye 255

# TODO: More robust file resolution
readFilesAsync = (files)->
   bluebird.map files, (file)-> fs.readFileAsync file, 'utf8'

readSourcesAsync = (files)->
   bluebird.map files, (file)->
      fs.readFileAsync file, 'utf8'
      .then (source)-> from: file, code: source

extra = (extra)-> path.join __dirname, 'Extras', extra

records_from = (asv)->
   # Using ASCII-delimited records: http://ell.io/i10pCz
   record_seperator = String.fromCharCode 30
   asv.split record_seperator


# ---- --- ---- --- ----

prettify.skipNodeFiles()
bluebird.onPossiblyUnhandledRejection (error)->
   Paws.debug "!! Possibly unhandled rejection:"
   console.error error.stack if error.stack
   process.exit 1
