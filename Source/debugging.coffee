util = require 'util'

class Debugging

class CommandLineDebugging extends Debugging
   # This is an exposed, bi-directional mapping of verbosity-names:
   #
   #     Paws.verbosities[4] === Paws.verbosities['warning']
   verbosities: verbosities =
      #    0       1      2       3      4      5     6     7      8     9
      "emergency alert critical error warning notice info debug verbose wtf".split(' ')
   verbosities[name] = minimum for name, minimum in verbosities


   write_browser = (console?.error || console?.log || noop).bind console
   write_cli = (objects...)->
      output = util.format.apply(util, arguments) + '\n'
      process.stderr.write output, 'utf8'

   # FIXME: Temporary. I'd really like this to be external, and more robust.
   write: write = if window? or process?.browser?
      write_browser
   else
      write_cli


   # Create a reporting function on a given object (of note, the root `Paws` object) for each
   # `verbosity` string (for instance, `Paws.warning`, or `Paws.info`) that calls `debugging.write`
   # if the debugging-level is set high enough.
   #
   # Also sets a few other debugging-relating settings (`Paws.use_colour()`, `Paws.is_silent()`,
   # `Paws.colour(...)`, and so on.)
   inject: (exports)->
      exports.verbosity  = -> verbosity
      exports.is_silent  = -> verbosity == 0

      exports.use_colour = -> use_colour

      for name, v in verbosities
         exports[name] = do (name, v)->-> if v <= verbosity

            if verbosity > 9 or process.env.DEBUG_VERBOSITY
               write "-- Verbosity of #{v}/#{verbosities[v]} ≤ "+
                   "#{verbosity}/#{verbosities[verbosity] ? '???'}; printing message:"

            write.apply debugging, arguments

      # We configure the `verbosity` itself in one of two ways: by calling an internal API at
      # runtime; or by setting an environment-variable before entry to the Paws library. (The
      # latter cannot affect the verbosity after the execution of this file.)
      #
      #     Paws.VERBOSE(9) // Very verbose output
      #     // (or `VERBOSE=9 ./program.paws`)
      #
      #     Paws.QUIET()    // Silence errors
      #     // (or `QUIET=true ./program.paws`)
      #
      # NOTE: Quieter-overrides-louder, in environment variables. For instance, if `SILENT` is
      #       defined, that overrides `VERBOSE`. To boot, the verbosity cannot be set *higher*
      #       via the API, if it has already been set by an environment variable (meaning
      #       `SILENT` will always mean `SILENT`.)
      # ----
      # TODO: Verify that this is compatible all the way back to IE6. I'm a bit iffy about the
      #       isFinite() shit.
      variables = SILENT: 0, QUIET: 2, VERBOSE: 8, WTF: 9

      for own name, ddefault of variables
         exports[name] = do (name, ddefault)-> (level = true, opts = {environmental: no})->
            if isFinite (l = parseInt level, 10)
               verbosity = l
            else if level == true or
                    level.charAt?(0) == 'y' or # yes
                    level.charAt?(0) == 't'    # true
               verbosity = ddefault unless max_verbosity < ddefault # Silence reigns.

            max_verbosity = verbosity if opts.environmental

            exports.wtf "-- Verbosity set to: #{verbosity}/#{verbosities[verbosity] ? '???'}"

         # FIXME: Move this out into its own function, and invoke upon ‘construction’
         if process.env[name]? and (max_verbosity == Infinity)
            exports[name](process.env[name], environmental: yes)

      exports.colour = exports.color = (use = true)->
         if use == no or
            use.charAt?(0) == 'n' or # no
            use.charAt?(0) == 'f'    # false
          use_colour = no
         else
          use_colour = yes

         exports.wtf "-- Colour set to: #{use_colour}"

      if env_colour = process.env['COLOUR'] ? process.env['COLOR']
         exports.colour env_colour

class BrowserDebugging extends Debugging
   inject: -> #noop

module.exports = debugging =
new (if process?.browser then BrowserDebugging else CommandLineDebugging)

# debugging.debug "++ Debugging available" # um...
