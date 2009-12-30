#!/usr/bin/env node

// Absolutes; `from` still ain’t complete, and packaging doesn’t work as of
// this writing. This should become `from.package('poopy.js')` and
// `from.package('Paws.js')`.
var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait(),
     paws = from.relative('../Packages/Paws.js/Paws.js').wait();

// OMGDEBUGGING
// from.absolute('/Users/elliottcable/Code/probe/lib/probe.js').wait().probe(paws);

// Normally, we’d cat a file here, and hand it to `paws.compile`. Instead,
// we’re going to jump directly to interpreting a routine root:
// var ast = ['routine', ['statement'
// , ['word', 'foo']
// , ['word', 'bar']
// , ['word', 'baz']
// , ['word', 'qux']
// , ['word', 'quux']
// , ['word', 'corge']
// , ['word', 'grault']
// , ['call', ['statement'
//   , ['word', 'garply']
//   , ['word', 'waldo']
//   , ['word', ',']
//   , ['word', 'fred']
//   , ['word', 'plugh']
//   ]]
// , ['word', 'xyzzy']
// , ['word', 'thud']
// ]];

// Too complex for now! Let’s go simpler:
var ast = ['routine', ['statement'
, ['word', 'foo']
, ['word', 'bar']
, ['word', 'baz']
]];

var rootRoutine = paws.routine.beget({ body : ast });
    rootRoutine     .run();
