<div align="center">
   <img src="http://elliottcable.s3.amazonaws.com/p/paws.js-cathode-3.png"><br>
   <img alt='Maintenance status: Under rapid development pre-release' src="https://img.shields.io/badge/maintained%3F-pre--release-orange.svg?style=flat-square"><img src="http://elliottcable.s3.amazonaws.com/p/8x8.png"><a href="https://github.com/ELLIOTTCABLE/Paws.js/releases"><img alt='Latest GitHub release' src="https://img.shields.io/github/release/ELLIOTTCABLE/Paws.js.svg?style=flat-square&label=release"></a><img src="http://elliottcable.s3.amazonaws.com/p/8x8.png"><a target="_blank" href="https://npmjs.com/package/paws.js"><img alt='Latest NPM version' src="https://img.shields.io/npm/v/paws.js.svg?style=flat-square&label=semver"></a><img src="http://elliottcable.s3.amazonaws.com/p/8x8.png"><a target="_blank" href="https://discord.gg/Mst2T9wnUY"><img alt='Chat: #ELLIOTTCABLE on Discord' src="https://img.shields.io/discord/706585477351735326?label=%23ELLIOTTCABLE&logo=discord&logoColor=24272a&labelColor=5865F2&style=flat-square"></a><img src="http://elliottcable.s3.amazonaws.com/p/8x8.png"><a target="_blank" href="https://twitter.com/intent/follow?screen_name=ELLIOTTCABLE"><img alt='Follow my work on Twitter' src="https://img.shields.io/twitter/follow/ELLIOTTCABLE.svg?style=flat-square&label=%40ELLIOTTCABLE&color=blue"></a><br>
   <a target="_blank" href="https://travis-ci.org/ELLIOTTCABLE/Paws.js/branches"><img alt='CI status' src="https://img.shields.io/travis/ELLIOTTCABLE/Paws.js/Current.svg?style=flat-square&label=tests"></a><img src="http://elliottcable.s3.amazonaws.com/p/8x8.png"><a target="_blank" href="https://coveralls.io/r/ELLIOTTCABLE/Paws.js?branch=Current"><img alt='Coverage status' src="https://img.shields.io/coveralls/ELLIOTTCABLE/Paws.js/Current.svg?style=flat-square"></a><img src="http://elliottcable.s3.amazonaws.com/p/8x8.png"><a target="_blank" href="https://gemnasium.com/ELLIOTTCABLE/Paws.js"><img alt='Dependency status' src="https://img.shields.io/gemnasium/ELLIOTTCABLE/Paws.js.svg?style=flat-square&label=deps"></a>
</div>

**Hello, friend.** This is a JavaScript implementation of the Paws machine, intended both to be included
into client-side code executed by browsers, and to be embedded into [Node.js][] projects.

**“What's a Paws,”** you ask? [Paws][] could be seen either as a *type* of programming language, or
as a design for a VM *on which* languages of that type can be run. Paws is a project sitting
somewhere between a pure VM for language development (think: the JVM), and a family of languages
(think: the LISPs.)

Paws lends itself well to highly *asynchronous* programming, meaning it's designed for things
involving the network requests (by design, web applications), and other tasks where concurrency is
desirable. In addition, things built on top of Paws can *distribute* themselves across multiple
environments and machines (this means your database, and your user's browsers, can all talk amongst
one-another.) Finally, Paws is designed from the ground-up to be *concurrency*-aware, ensuring tasks
can parallelize when they won't affect eachother negatively.

**“Cool! Can I use it?”** Probably not, I'm afraid, although it's adorable that you ask.
Unfortunately, this project is basically just a VM, with some excruciatingly-primative primatives
with which one can construct abstractions. (Writing code that will run on this machine is
approximately analogous to writing raw assembler.) Before this project will be useful to you,
somebody'll need to write some abstractions (basically, a language) on top of it!

To boot, the Paws system as a whole is still under heavy design and development; lots of things are
still likely to change. Although there's a [specification for the current version,][spec] lots of
relatively fundamental aspects of the machine's semantics are still subject to evolution. In fact,
some of the neatest features of the design aren't nailed down into the specification yet (nor are
they implemented in this codebase); so anybody trying to write those abstractions for you is
probably going to have some of their work invalidated in the future. **tl;dr: the Paws design isn't
stable, yet!**

**“Okay, well, I like language design. Can I write stuff on top of this machine?”** I'm so glad you
asked! You're my favourite kind of person! Assuming you understand the caveat mentioned above (that
this project is in flux), you can *absolutely* start experimenting with abstractions on top of the
Paws machine.

If you want to learn more, you should definitely make a Discord account, and join the chatroom where
we discuss Paws (as well as entirely-too-much other stuff! Well, mostly dogs, if I'm being honest.)
All newcomers are welcome, and contribution is hugely appreciated!

<div align="center">

## Join `#ELLIOTTCABLE` on Discord: <br/> https://discord.gg/Mst2T9wnUY

</div>

   [Node.js]: <http://nodejs.org> "A server-side JavaScript platform"
   [Paws]: <http://paws.mu> "An asynch-heavy distributed platform for concurrent programming"
   [spec]: <http://ell.io/spec> "Specification for the 10th iteration of the Paws design"

Using
-----
This implementation of a Paws machine can be used in two ways: interactively, at the command-line;
or directly, via its embedding API. More information about command-line usage can be acquired by
querying the executable at the command-line:

    npm install                     # (Must be run before the executable can be used)
    ./Executables/paws.js --help
    ./Executables/paws.js interact  # Example, opens an interactive ‘REPL’ to play with

As for embedding the `Paws.js` API, you'll have to dive into the code and poke around a bit, for the
moment. I'm also happy to give you a quick overview, if you join [our channel][webchat] and ask!

*(I swear, API documentation is coming soon! `:P` )*

Contributing
------------
I consistently put a lot of effort into ensuring that this codebase is easy to spelunk. Hell, I
reduced myself to using [CoffeeScript][], to make everything easier to read! `(=`

Any and all [issues / pull-requests][issues] are welcome. There's a rather comprehensive test-suite
for the reactor itself; it's appreciated if any changes are contributed with passing test-cases, of
course.

After `git clone`'ing the codebase, you should immediately `npm run-script hi`; this will help you
set up your local copy for hacking.

More specific information ~~can be found in [CONTRIBUTING](./blob/Master/CONTRIBUTING.markdown)~~.
(Well, eventually. `>,>`)

   [CoffeeScript]: <http://coffeescript.org> "A little language that transpiles into JavaScript"
   [issues]: <https://github.com/ELLIOTTCABLE/Paws.js/issues> "Issue-tracker for Paws.js"

<br>
----
<div align='center' id='npm-and-browser-support'>
   <a href="https://npmjs.org/package/paws.js">
      <img alt="npm downloads" src="https://nodei.co/npm-dl/paws.js.png?months=9"></a>
<!--
   <h4>Browser support:</h4>
   <a href="https://ci.testling.com/ELLIOTTCABLE/Paws.js">
      <img alt="Current browser-support status on HEAD (generated by Testling-CI)" src="https://ci.testling.com/ELLIOTTCABLE/Paws.js.png"> </a>
-->
</div>
