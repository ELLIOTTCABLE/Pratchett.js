# Hello! I am Paws! Come read about me, and find out how I work.
#
#                        ,d88b.d88b,
#                        88888888888
#                        `Y8888888Y'
#                          `Y888Y'
#                            `Y'

_         = require './utilities.coffee'
debugging = require './debugging.coffee'


# Assembling the API
# ==================
module.exports =
Paws         = require './datagraph.coffee'
Paws.parse   = require './parser.coffee'


Paws.primitives = (bag)->
   require("./primitives/#{bag}.coffee")()

Paws.generateRoot = (code = '', name)->
   code = Paws.parse Paws.parse.prepare code if typeof code == 'string'
   code = new Paws.Execution code
   code.rename name if name
   debugging.info "~~ Root-execution generated for #{_.terminal.bold name}" if name

   code.locals.inject Paws.primitives 'infrastructure'
   code.locals.inject Paws.primitives 'implementation'

   return code

Paws.start =
Paws.js = (code)->
   root = Paws.generateRoot code

   here = new Paws.reactor.Unit
   here.stage root

   here.start()


Paws.infect = (target)-> @utilities.extend (target ? global), this


# XXX: Loading order:
#      0. Paws.☕️
#      1. += utilities.☕️
#      2.    -> debugging.☕️ ...
#         += debugging.☕️      (-> utilities.☕️ )
#      3. += datagraph.☕️      (-> utilities.☕️ , debugging.☕️ )
#      4. += parser.☕️         (-> utilities.☕️ , debugging.☕️ )
#      6, += primitives/*

debugging.info "++ API available"
