#!/usr/bin/env node

// Absolutes; `from` still ain’t complete, and packaging doesn’t work as of
// this writing.
var poopy = from.absolute('/Users/elliottcable/Code/poopy.js/lib/poopy.js').wait(),
     paws = from.relative('../lib/Paws.js').wait();

// OMGDEBUGGING
// from.absolute('/Users/elliottcable/Code/probe/lib/probe.js').wait().probe(paws);

// Normally, we’d cat a file here, and hand it to `paws.compile`. Instead,
// we’re going to jump directly to interpreting a routine root:
// var ast = ['routine', ['statement',
//   ['word', 'foo'], ['word', ' '],
//   ['word', 'bar'], ['word', ' '],
//   ['word', 'baz'], ['word', ' '],
//   ['word', 'qux'], ['word', ' '],
//   ['word', 'quux'], ['word', ' '],
//   ['word', 'corge'], ['word', ' '],
//   ['word', 'grault'], ['word', ' '],
//   ['call', ['statement',
//     ['word', 'garply'], ['word', ' '],
//     ['word', 'waldo'], ['word', ' '],
//     ['word', ','], ['word', ' '],
//     ['word', 'fred'], ['word', ' '],
//     ['word', 'plugh']
//   ]], ['word', ' '],
//   ['word', 'xyzzy'], ['word', ' '],
//   ['word', 'thud']
// ]];

// Too complex for now! Let’s go simpler:
var ast = ['routine', ['statement',
  ['word', 'foo'], ['word', ' '],
  ['word', 'bar'], ['word', ' '],
  ['word', 'baz'], ['word', ' ']
]];

var rootRoutine = paws.routine.beget({ body : ast });
    rootRoutine     .run();
