#!./node_modules/.bin/coffee
process.title = 'paws.js'

module.package = require '../package.json'
optional    = require 'optional'

bluebird    = require 'bluebird'
minimist    = require 'minimist'
mustache    = require 'mustache'
prettify    = require('pretty-error').start()
kexec       = optional '@jcoreio/kexec'

path        = require 'path'
fs          = bluebird.promisifyAll require 'fs'

bluebird.config
   warnings: true
   longStackTraces: true


Paws        = require '../Library/Paws.js'

{  Thing, Label, Execution, Native
,  Relation, Combination, Position, Mask
,  debugging, utilities: _                                                                  } = Paws

{  constructify, parameterizable, delegated
,  terminal: term                                                                              } = _

{  ENV, verbosity, is_silent, colour
,  emergency, alert, critical, error, warning, notice, info, debug, verbose, wtf       } = debugging

{ stdout: out, stderr: err } = process


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
   debugging.VERBOSE 6

ENV ['PAGINATE'], type: 'boolean', value: null
ENV ['PAGINATED'], immutable: yes, infect: yes, handler: (paginated)->
   info "-- Already paginated, disabling pagination"
   debugging.paginate no if paginated; return paginated

debugging.paginate(argf.paginate ? argf.pager) if _.isBoolean debugging.paginate()


sources = _([argf.e, argf.expr, argf.expression])
   .flatten().compact().map (expression, i)-> { from: '--expression #' + i, code: expression }
   .value()

if verbosity() >= debugging.verbosities['info']
   info "-- Arguments: ", argv.join(' :: ')
   info "-- Flags: ", argf
   info "-- Sources: ", sources

   wtf "-- Environment variables:"
   wtf process.env

choose = ->
   if debugging.paginate()
      info '-- Trying to paginate,'
      return page choose

   if argf.version
      info '-- Writing version and exiting.'
      return version -> process.exit 0

   if argf.help
      info '-- Displaying help-text and exiting.'
      return help -> process.exit 0

   if (_.isEmpty(argv[0]) and !sources.length)
      notice '-- No operation specified, displaying usage and exiting.'
      return help -> process.exit 1

   switch operation = argv.shift()

      when 'pa', 'parse'
         info '-- Invoking parse operation'
         go = -> _.forEach sources, (source)->
            info "-- Parse-tree for '#{term.bold source.from}':"
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
         info '-- Invoking check operation'
         {Collection} = require '../Source/rule.coffee'
         readSourcesAsync(argv).then (files)->
            # FIXME: Promisify this a bit more.
            _.forEach files, (file)->
               if /\.rules\.yaml$/i.test file.from then rule_file file else sources.push file

            _.forEach sources, (source)-> rule_unit source

         rule_file = (source)->
            info "-- Staging rules in '#{term.bold source.from}' from the command-line ..."
            _.forEach _.values(require('yamljs').parse source.code), (book)->
               collection = Collection.from book

               if argf['expose-specification'] == true
                  _.forEach collection.rules, (rule)->
                     rule.body.locals.inject Paws.primitives 'specification'

               collection.report()
               collection.on 'complete', (passed)-> goodbye 1 unless passed
               collection.close()

         rule_unit = (source)->
            info "-- Staging '#{term.bold source.from}' from the command-line ..."
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
         info '-- Invoking interact operation'
         Interactive = require '../Source/interactive.coffee'
         interact = new Interactive
         interact.on 'close', -> goodbye 0
         interact.start()

      when 'st', 'start'
         info '-- Invoking start operation'
         go = -> _.forEach sources, (source)->
            info "-- Staging '#{term.bold source.from}' from the command-line ..."
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

# Re-executes the current invocation of `paws.js`, with the output wrapped in `$PAGER`; then invokes
# the callback in the new, paginated process.
#---
# FIXME: Check for existence of `less` if `$PAGER` is not defined.
# FIXME: `less` seems to mangle the emoji heart above by default.
page = (cb)->
   if debugging.paginated() or debugging.paginate() == no
      info '-- Refusing to paginate: ' +
         if debugging.paginated() then 'already paginated.' else 'pagination disabled.'
      return cb()

   # A simpler hack, to send `-R` to `less`, if possible.
   pager = process.env.PAGER || 'less --chop-long-lines'
   pager = pager.replace /less(\s|$)/, 'less --RAW-CONTROL-CHARS$1'

   # This is a horrible hack. Thanks, Stack Overflow. http://stackoverflow.com/a/22827128/31897
   escapeShellArg = (cmd)-> "'" + cmd.replace(/\'/g, "'\\''") + "'"

   process.env['SIMPLE_ANSI'] = true
   process.env['PAGINATED'] = true
   process.env['PAGINATED_COLUMNS'] = term.columns # XXX: Would `COLUMNS` work?

   # These are passed to `"sh" "-c" ...` by `kexec()`.
   params = process.argv.slice()
   params = params.map (arg)-> escapeShellArg arg
   params.push '|'
   params.push pager

   Paws.debug "!! Forking and exec'ing to pager: `#{pager}`"
   Paws.wtf "-- Invocation via `sh -c`:", params.join ' '
   kexec params.join ' '

help = (cb)-> page -> readFilesAsync([extra('help.mustache'), extra('figlets.mustache.asv')]).then ([template, figlets])->
   figlets = records_from figlets

   divider = term.invert( new Array(Math.ceil((term.columns + 1) / 2)).join('- ') )

   prompt = '>'

   usage = divider + "\n" + _(figlets).sample() + template + divider
   #  -- standard 80-column terminal -------------------------------------------------|

   usage = mustache.render usage+"\n",
      heart: if colour() then heart else '<3'
      b: ->(text, r)-> term.bold r text
      u: ->(text, r)-> term.underline r text
      c: ->(text, r)-> if colour() then term.invert ' '+r(text)+' ' else '`'+r(text)+'`'

      # `op` and `flag` are meant to be used inline in other text, as they surround their content
      # with backticks when COLOUR is disabled. The other four are meant to be used in code-samples
      # or headlines, where backticks are unnecessary.
      op:      ->(text, r)-> if colour() then term.fg 2, r text else '`'+r(text)+'`'
      bgop:    ->(text, r)-> term.bg 2, r text
      opdef:   ->(text, r)-> term.fg 2, r text

      flag:    ->(text, r)-> if colour() then term.fg 6, r text else '`'+r(text)+'`'
      bgflag:  ->(text, r)-> term.bg 6, r text
      flagdef: ->(text, r)-> term.fg 6, r text

      var:     ->(text, r)-> if colour() then term.fg 5, r text else '`'+r(text)+'`'
      bgvar:   ->(text, r)-> term.bg 5, r text
      vardef:  ->(text, r)-> term.fg 5, r text

      title: ->(text, r)->
         text = r text.toUpperCase() # FIXME: Well, will obviously break with embedded codes ...
         if colour()
            term.bold term.underline text
         else
            text + "\n" + _.repeat '=', text.length

      link:  ->(text, r)->
         if colour() then term.sgr(34) + term.underline(r text) + term.sgr(39) else r text

      arcane: ->(text, r)-> if argf.arcane then r text else ''
      important: ->(text, r)->
         info '-- Disabling blink' unless debugging.blink()
         carets = (arr...)->
            if colour() and term.tput.max_colors == 256
               arr[0] = term.xfg 52, arr[0]
               arr[1] = term.xfg 124, arr[1]
               arr[2] = term.xfg 196, arr[2]
            else if colour()
               arr[0] = term.fg 10, arr[0]
               arr[1] = term.fg 1, arr[1]
               arr[2] = term.fg 11, arr[2]
            return arr

         # FIXME: Why isn't exit-blink in the termcap o_O?
         blink = if debugging.blink() then [ term.sgr(5), term.sgr(25) ] else ['', '']

         # FIXME: This Unicode may be fuuuuugly on Linux / Windows.
         wrap = [ carets('❮ ','❮ ','❮ ').join(''), carets(' ❯',' ❯',' ❯').reverse().join('') ]

         line = blink[0]+wrap[0]+blink[1] + r(text) + blink[0]+wrap[1]+blink[1]

        #padding = _.floor (term.columns - term.strip(line).length) / 2
         padding = _.floor (80- term.strip(line).length) / 2
         (_.repeat ' ', padding) + line

      prompt: -> # Probably only makes sense inside {{pre}}. Meh.
         if colour() and not debugging.simple_ansi()
            term.sgr(27) + term.csi('3D') + term.fg(7, prompt+' ') + term.sgr(7) + term.sgr(90)
         else prompt
      pre:  ->(text, r)-> term.block r(text), (line, _, sanitized)->
         line = if colour() and not debugging.simple_ansi() and sanitized.charAt(0) == prompt
            line.slice 0, -3 # Compensate for columns lost to `prompt`'s ANSI ‘CUB’
         else
            line.slice 0, -6

         if colour()
            "   #{term.invert term.fg 10, " #{line}"}   "
         else
            "   #{line}"

   out.write usage, 'utf8', -> version cb

version = (cb)->
   # TODO: Extract this `git describe`-style, platform-independent?
   release      = module.package['version'].split('.')[0]
   release_name = module.package['version-name']
   spec_name    = module.package['spec-name']
   out.write """
      Paws.js release #{release}, “#{release_name}”
         conforming to: #{spec_name}
   """ + "\n", 'utf8', cb

ENV 'BLINK', value: colour()
goodbye = (code = 0)->
   if not process.env['_PAGINATED'] and verbosity() >= debugging.verbosities['error']
      salutation = _(salutations).sample()
      salutation = ' ~ '+salutation+' '+ (if colour() then heart else '<3')

      if colour()
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
   debug "!! Possibly unhandled rejection:"
   console.error error.stack if error.stack
   process.exit 1
