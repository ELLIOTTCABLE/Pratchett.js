Reading Paws.js
===============
Reading source-code, also known as ‘[spelunking][]’, can be arduous for large projects; but it's
surely an [extremely rewarding activity][ReadGreatPrograms].

To me, Paws.js is meant as much as an educational resource as it is a proof-of-concept or actual
tool: I want newcomers (you!), especially those who consider themselves beginners, to be able to
*learn* from it.

(This is especially the case due to “building a programming language” being something that's
 considered difficult, arcane, scary, *even to otherwise experienced programmers*. It's one of my
 personal raisons d'être to demystify programming-language design, and make it accessible to
 programmers of all skill-levels!)

This document, although it may (at times) become somewhat out-of-sync with the codebase itself, is
intended as a starting-point and exploratory aid for those of you wishing to learn from Paws.js — if
any of the following apply, this is written for you!

 - You want to learn a little about building programming languages
 - You want to know what's involved in managing a large software project by one's lonesome
 - You're learning Paws itself, and wish to understand at a more fundamental level how it works

That feel like it applies to you? Cool! Let's get started.

   [spelunking]: <http://queue.acm.org/detail.cfm?id=945136>
      "Code Spelunking: Exploring Cavernous Code Bases — George V. Neville-Neil"
   [ReadGreatPrograms]: <http://wiki.c2.com/?ReadGreatPrograms>


Getting help
------------
I’m (the author, ELLIOTTCABLE, that is) an educator at heart: I love to *teach*. There’s really no
reason to go through reading this alone, unless you’re feeling particularly shy — I’d be ecstatic to
help you out, whether you’re actually interested in my project, or just want to ask beginners’
questions about programming-language design and development in a friendly place.

First off, I spend way too much of my day chatting in real-time on [Discord][], a text- and voice-
chat app. You can use it in your browser, download a computer client, or even just log in on your
phone. Go ahead and click here to join my community; there’s almost *always* interesting, friendly
folk chatting in there — and once you join, you can find me under the name `ec#2718`:

> ## Join #ELLIOTTCABLE on Discord: <br/> https://discord.gg/Mst2T9wnUY

I'm also very responsive on Twitter: [@ELLIOTTCABLE][]; you’re welcome to hit me up there, in public
or over direct-message. 💚

   [Discord]: <https://discord.com/> "A text- and voice-chat platform for communities."
   [@ELLIOTTCABLE]: <https://twitter.com/ELLIOTTCABLE> "ELLIOTTCABLE on Twitter"


History
-------
Paws.js development is undertaken using [git][] and [GitHub][]; this means that there is an
*extremely* thorough and completist history of every change made in the history of this project.
Notably, this includes every little bump, misstep, and dead-end explored as I work on it.

Knowing the basics of git will be very helpful to *any* code-spelunking adventure — it's very
helpful to know not just what the code says, but *how it came to say that*. If you've never used git
before, a quick [read through the tutorial][gittutorial] is very worth your time.

Unlike most projects, I am **very** careful with my project history: I put consistent effort into
keeping the history clean, clear, and communicative. In fact, I'm so obsessive about these topics,
that I created my own extra-obsessive processes, and have followed them for a solid decade: I follow
a pattern of git-usage that I call “[granular committing][],” and heavily use [.gitlabels][] to
summarize the contents/relevance of each commit.

As a quick overview of granular committing, it revolves around using git's “branches” — effectively
alternate histories for your code. Each foray into a new feature or change involves *two* kinds of
git branches, namely:

 - **Granular branches** (those ending with a `+`): This is where work happens in realtime, and
   where most of the aforementioned missteps and exploration happens. I very specifically push these
   branches *to be spelunked*, so dive in, and you can find out in detail how and why I wrote things
   a certain way, or problems I ran into while working on that feature.
 - **Safe branches** (the rest): When I reach a stopping-point on a new feature or fix (while
   working in one of those ‘granular branches’), I go back and “squash” the work thus far (combine
   it into fewer, well-documented commits) into the project's direct and official history. The
   history in these branches often elides missteps or reverted work, and is documented more
   thoroughly (though belatedly.)

----

As a newbie, the easiest way to browse the project's history is with GitHub. Amongst other features,
you might want to check out:

 - [/branches/active](https://github.com/ELLIOTTCABLE/Paws.js/branches/active):
   This should give you some idea of current, on-going work on the project.
 - [/compare/current...branchname](https://github.com/ELLIOTTCABLE/Paws.js/compare/current...queueless):
   To see the state of a given feature-branch, you can use GitHub's ‘compare’ feature. (Also check
   out the “Files changed” and “Commit comments” features!)
 - [/network](https://github.com/ELLIOTTCABLE/Paws.js/network):
   Despite the name, the ‘network’ graph is a great way to graphically explore the commit-history of
   the project in your browser
 - [/labels/good-for-beginners!](https://github.com/ELLIOTTCABLE/Paws.js/labels/good-for-beginners!):
   I sometimes attempt to record incomplete work that's approachable for someone new, here — if you
   *really* want to learn the codebase, there's no better way than trying to contribute a patch!
   (And remember: [I'm here to help!](./CONTRIBUTING.markdown))

The one downside is GitHub's lack of first-class support for my fancy-shmancy gitlabels. A
alternative, local method to browse the project's history is with [the `git log --graph`
functionality][git-log]:

```sh
git log --all --decorate --oneline --graph
```

This particular invocation is easy to remember, if you like [a dog][]. `;)` Further, thanks to the
pervasive use of gitlabels, you can also, for instance, browse only *major* changes with something
like `git log --all -F --grep='!!'`.

   [git]: <https://git-scm.com> "git: a free and open source distributed version control system"
   [GitHub]: <https://github.com> "GitHub: A development platform on top of git"
   [gittutorial]: <https://git-scm.com/docs/gittutorial> "Git's built-in tutorial for beginners"
   [granular committing]: <http://blog.elliottcable.name/posts/granular_committing.xhtml>
      "Granular Committing: ELLIOTTCABLE's system for clean project histories"
   [.gitlabels]: <http://ell.io/tt$.gitlabels#readme>
      ".gitlabels: ELLIOTTCABLE's system for git-commit filtering and searching"
   [git-log]: <http://gitready.com/advanced/2009/01/20/bend-logs-to-your-will.html>
      "git-ready's page on git-log"
   [a dog]: <https://stackoverflow.com/a/35075021/31897> "git adog!"


Tests
-----
I'm a strong adherent to [Test-First Development][tdd]. I strive for high coverage, at least across
all testing methods (some bits of a programming-language interpreter are difficult to unit test —
forgive me! 🤣)

One way to get an overview of the *entire project*, is to simply run the tests, and ask them to
print what they're testing as they go. This enables you to see simple, English-language descriptions
of lots of the moving parts of this codebase:

```sh
npm test -- --reporter spec
```

Each outdented section is a separate concern; if any of the descriptions catches your eye, you can
search for it in all the test-files, and start spelunking the codebase from there.

   [tdd]: <https://en.wikipedia.org/wiki/Test-driven_development> "Wikipedia on TDD"


Source code
-----------
And here we are — let's dive into the meat!

Paws.js is organized into a few separate concerns. Where possible, some of the functionality is
separated into somewhat-separate modules ([Executables/paws.js.coffee][] and
[Source/interactive.coffee][], etc); ... DOCME

   [Executables/paws.js.coffee]: <./Executables/paws.js.coffee>
