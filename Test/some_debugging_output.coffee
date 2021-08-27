fs   = require 'fs'
path = require 'path'

Paws = require "../Source/Paws.coffee"

{  Reactor, parse
,  Thing, Label, Execution, Native
,  ThingSet, Relation, Liability, Combination, Position, Mask, Operation
,  ResponsibilityError }                                                                      = Paws

{  Context, Sequence, Expression }                                                           = parse

console.log "\nAn empty, anonymous thing:" # {{{1

thing = new Thing
console.log(thing.inspect())

console.log "\nA thing with one distant child:" # {{{1

thing = new Thing(new Thing)
console.log(thing.inspect())

console.log "\nA thing with one owned child:" # {{{1

thing = new Thing(new Thing)
thing.own_at 1
console.log(thing.inspect())

console.log "\nA thing with a few children:" # {{{1

thing = new Thing(new Thing, new Thing, new Thing)
thing.own_at 2
console.log(thing.inspect())

console.log "\nA thing with a lot of children:" # {{{1

thing = new Thing(new Thing, new Thing, new Thing, new Thing, new Thing, new Thing)
thing.own_at 2
console.log(thing.inspect())

console.log "\nA thing with a lot of descendants:" # {{{1

parent = new Thing(new Thing, new Thing, new Thing, new Thing, new Thing)
grand = new Thing(new Thing, new Thing, parent, new Thing, new Thing, new Thing)
ancestor = new Thing(grand)
# ancestor.own_at 1
console.log(ancestor.inspect())

console.log "\nA thing with one pair:" # {{{1

thing = new Thing
thing.define 'foo', new Thing
console.log(thing.inspect())

console.log "\nA thing with several pairs:" # {{{1

thing = new Thing
thing.define 'foo', new Thing
thing.define 'bar', new Thing
thing.define 'baz', new Thing
console.log(thing.inspect())

console.log "\nA thing with a mix of pairs and anonymous things:" # {{{1

thing = new Thing
thing.define 'foo', new Thing
thing.push new Thing
thing.define 'baz', new Thing
console.log(thing.inspect())

console.log "\nA thing with many pairs:" # {{{1

thing = new Thing
thing.define 'foo', new Thing
thing.define 'bar', new Thing
thing.push new Thing
thing.define 'baz', new Thing
thing.define 'widget', new Thing
thing.metadata.push undefined
thing.define 'thingie', new Thing
thing.define 'stuff', new Thing
console.log(thing.inspect())

console.log "\nA thing with a long-ish key that breaks the following Thing" # {{{1

thing = new Thing
thing.push new Thing(new Thing, new Thing(new Thing, new Thing), new Thing)
thing.define 'According to all known laws of aviation, ...',
   new Thing(new Thing, new Thing(new Thing, new Thing), new Thing)
thing.define 'baz', new Thing
console.log(thing.inspect())

console.log "\nA thing with a very long key:" # {{{1

thing = new Thing
thing.define 'foo', new Thing(new Thing, new Thing, new Thing)
thing.define 'According to all known laws of aviation, ...', new Thing(new Thing)
thing.define '... there is no way that a bee should be able to fly. Its wings are too small to get its fat little body off the ground. The bee, of course, flies anyway.',
   new Thing(new Thing, new Thing, new Thing, new Thing(new Thing))
thing.define 'baz', new Thing
console.log(thing.inspect())

console.log "\nWeird pairs that shouldn't be foreshortened:" # {{{1

normal_pair = Thing.pair('foo', new Thing)
label_has_md = Thing.pair('bar', new Thing)
label_has_md.at(1).push new Thing
pair_with_noughty = Thing.pair('baz', new Thing)
pair_with_noughty.set 0, new Thing
doesnt_own_label = Thing.pair('widget', new Thing)
doesnt_own_label.disown_at 1
thing = new Thing(normal_pair, label_has_md, pair_with_noughty, doesnt_own_label)
console.log(thing.inspect())

console.log "\nAn item repeated:" # {{{1

first = new Thing
parent = new Thing(first)
second = new Thing
thing = new Thing(parent, second, first)

console.log(thing.inspect())

console.log "\nA cycle:" # {{{1
first = new Thing
second = new Thing(first)
first.push second

console.log(first.inspect())

console.log "\nA sequence:" # {{{1

seq = parse "something bleh[];\nother blah[]"
console.log(seq.inspect())

console.log "\nA short Execution:" # {{{1

exec = new Execution parse 'hi'
console.log(exec.inspect())

console.log "\nA short Execution with metadata:" # {{{1

exec = new Execution parse 'hi'
exec.define 'foo', new Thing
exec.define 'bar', new Thing
exec.define 'baz', new Thing
exec.define 'widget', new Thing
console.log(exec.inspect())

console.log "\nA long Execution:" # {{{1

example_file = path.resolve __dirname, "../Examples/02.world.singleton.factory.bean.paws"
example_to_parse = fs.readFileSync example_file, 'utf8'
exec = new Execution parse parse.prepare example_to_parse
console.log(exec.inspect())

console.log "\nA thing with short Execution:" # {{{1

thing = new Thing
thing.define 'foo', new Execution parse 'hi'
thing.define 'bar', new Thing
thing.define 'baz', new Thing
console.log(thing.inspect())

console.log "\nA long Execution with generateRoot:" # {{{1

root = Paws.generateRoot example_to_parse
console.log(root.inspect())
