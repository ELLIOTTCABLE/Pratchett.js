Contributing to Paws
====================
Hi, and welcome! I'm Elliott. This is my project¹, and I'm super-glad² you want
to help me build this software. There's a few things that it'll be really
helpful to know while you get started, and I'll cover those herein.

I know that for some, contributing to a programming language may be a daunting
prospect (and for others, contributing to *any* open-source project), so please,
if any of the following is true, I want to make it clear: _I **want** your
input_!

 * You have experience in developing, or communicating in, online communities;
   and you like the sound of there existing one more safe (and productive!)
   space in our field.³
 * You're curious about *how* programming languages are designed and built, or
   why certain decisions are made in the process of designing a programming
   language.
 * You're a software developer that wants to see if a new and fledgling language
   can meet your needs as a dev, and you want to influence its evolution and
   development in positive ways.

If any of these describe you ... read on, m'friend.  (｡◕‿◕｡)

Venues
------

 * **IRC:** #ELLIOTTCABLE [on the Freenode network](http://ell.io/IRC)

   IRC is our real-time communication method of choice (sorry, [Slack][]).
   There's *always* somebody chatting in my channel; and as often as not, it
   could be about Paws. If you have any questions, want help getting started, or
   just want to make some new friends, grab yourself an IRC client (or just
   click the link above!) and come say hi! (We're all social creatures at heart,
   so why don't you introduce yourself a bit when you join? I'd love to get to
   know you better.)

 * **Mailing list:** <pratchett-dev@googlegroups.com>

   Joining the mailing list simply involves sending an empty e-mail to
   <pratchett-dev+subscribe@googlegroups.com>. As with IRC, may I gently suggest
   you send an e-mail saying hello and introducing yourself after joining? (=

 * **GitHub Issues:** <https://github.com/ELLIOTTCABLE/Paws.js/issues>

   Actual bugs, technical issues, or any propositions or feature-requests should
   be directed to Issues. As with any technical project, the *more information*,
   the *better*, with no exceptions. It never hurts to ask on IRC, first; but
   even if the solution is simple, I'll likely ask you to post it on Issues
   *anyway*, for posterity (i.e., future frens experiencing the same problem.)

   [Slack]: <http://randsinrepose.com/archives/why-i-slack/>

Comportment and behaviour
-------------------------
Now that you know *where* to talk, I need to touch on *how* to. As the creator
of these various venues, I've been systematically blessed(?) with some
procedural control over the conversations that happen therein (read: banning,
muting, and other forms of censorship.) Now, I am, unfortunately, just another
flawed human being, like yourself; but because I created these spaces, it falls
on me to exercise these tools to the benefit of us all. To that end, I've
written a [CODE OF CONDUCT][] *~dun dun dunnn~* to help set the tone for our
community; and all jokes aside, I *will* see it adhered to.

There's more information available in that document, and I do require that you
read it in full before participating in any space I am responsible for; but I
want to proffer the following simplification: There exists between myself,
Elliott, and you, as a member of my community, a covenant. This convenant says:

1. I will *swiftly*, and prejudicially, eject people who are *hurting you* (or
   who are hurting any member of the community); or who's presence is actively
   damaging the community as a whole.

2. However should *you* be so removed, I will still make myself available to
   you. Your feelings will not go unreceived, and you will have a thoroguh
   explanation of my decision. (Understand that this does not guarantee you will
   be re-admitted, unfortunately. /= )

That said, please, please go read the [CODE OF CONDUCT][]. It's not some legal
document; it's simple, straightforward, and will help us all get along and have
lots of fun improving the world together.

   [CODE OF CONDUCT]: <http://ell.io/-CoCONDUCT>

How to contribute
-----------------
There's lots of ways you can contribute to Paws. Besides the obvious technical
ways, which I'll (finally!) go into more detail about below, there's lots of
non-technical progress to be made. Some of the types of contributions I'm
looking for include:

 * **Ideas:** Participate in a conversation on IRC, submit your own original
   thoughts to the mailing list or comment on Issues, and make your voice heard.
 * **Design:** Paws still doesn't have a landing page, website, or even logo!
 * **Writing:** You may have noticed that I like my prose. There's plenty of
   copywriting to be done, both in terms of technical documentation, tutorials
   and information for newcomers, and in terms of ‘marketing.’
 * **Feedback:** There's nothing out there better than constructive criticism;
   and if you have some for me, I'd love to hear it. This can be as simple as
   bugs, errors, and typos; it can be in criticisms of Paws' design, or it can
   even be criticisms of my approach to building a community.

Technical contributions
=======================
Phew! That got long-winded. Let's move on to what you probably came here for:
how to navigate the code-base, how to get started improving things, and how to
submit those improvements.

### Finding the code
Paws.js is spread across three individual projects: The interpreter and primary
codebase (this repository), the glue-mappings that actually implement the
standard library of primitives ([primitives.js][]), and the suite of language-
specification conformance tests, known as the [Rulebook][].

The `Master` branch on GitHub is usually substantailly out-of-date with current
work; as of this writing, when Paws is actively under heavy and breaking
development, it's usually kept at a point in the development-history where the
language Actually Runs Code. All successful feature-branches are merged or
fast-forwarded, instead, onto the [`Current`][] branch. (Some relatively trivial
development work even happens directly in the `Current+` branch.)

Implementation of the core datatypes, the primary algorithms that power Paws,
the reactor that evaluates code, and the parser that consumes ‘canonical Paws’
as text-files, are all found in this repository. These things are exposed via a
JavaScript API, and an executable CLI. *(More detail about the structure of the
interpreter can be found in [SPELUNKING.markdown][].)*

The individual specifics of the *Paws-side API*, however, are implemented in the
separate primitives project. The actual code there is kept to a minimum, to
reduce the liklihood of changes; but any change to the parameterization of
primitive procedures will be made there.

   [primitives]: <https://github.com/Paws/primitives.js>
   [Rulebook]: <https://github.com/Paws/Rulebook>
   [`Current`]: <https://github.com/ELLIOTTCABLE/Paws.js/tree/Current>
   [SPELUNKING.markdown]: <./Docs/SPELUNKING.markdown>

### Improving the code
Around these parts, we adhere strongly to [test-first development][TDD]. Once
you've ascertained which moving parts of the codebase play a part in the changes
you wish to make, you need to write a new integration-level test to describe the
functionality you wish to add or change, and unit-level tests for any changes
you make to the codebase in the process. Once you've written the tests you wish,
you can run my entire test-suite with the following:

    npm -s test            # See Scripts/test.sh for documentation of options
    WATCH=yes npm -s test  # (An example, to re-execute the suite on file-save)

If you're making any changes to the language semantics (that is, if your changes
are not completely confined to the executable, utilities and debugging system,
or interactive-mode), then you'll also need to be running the Rulebook, our
language-conformance suite. Changes to the Rulebook are much more tightly
controlled; and you probably shouldn't be making changes to the reactor or other
parts of the language that affect the semantics without *prior* addition of
failing Rulebook tests.

    RULEBOOK=yes npm -s test
    paws.js check a_book.rules.paws # To evaluate a particular book of your own

In leiu of a formal style-guide, I simply ask that you do your best to maintain
the appearance and approaches of the code nearby that which you are changing (or
adding.) For instance: do you see a single hard-tab character in the entire
codebase? No? Then maybe don't use them. ;)

As well as caring deeply about the thorough testing and Q.A. of my software, I
consider thorough *documentation* to be absolutely indespensible. There is
definitely such a thing as self-documenting code, and that's always a great
goal; but if you don't think a 5-year-old could follow what a block of code that
you've added does, then please add some comments describing it. (If you've added
or changed any public APIs, though, then a documentation block is, of course,
non-optional.)

   [TDD]: <http://www.agiledata.org/essays/tdd.html>

### Committing the code
Final code to be accepted into the Paws mainline obviously must be, as described
above, thoroughly tested, thoroughly documented, and so-on so-forth; but that
doesn't mean every step along the way has to be perfectly-placed! I encourage
constant and [granular committing][] of your changes as you work (if I were an
elementary-school teacher, I'd be the one always saying “Show your work!”), even
if you make lots of mistakes. To do such work, create a new Git branch with a
name ending in `+`:

    git checkout --track Current -b my-cool-new-feature+

Once you have completed your work and are ready to submit it for inclusion, you
should rebase those changes on top of the `Current` mainline of active work, and
then squash those progress-commits into a single (or possibly a few) ‘primary’
changesets, consisting of the final state of your improvements:

    git rebase Current my-cool-new-feature+
    git checkout Current
    git merge --squash my-cool-new-feature+

When committing, use [.gitlabels][] to categorize and describe the changes being
made (this repository will automatically suggest some of the more common labels
to you when you're writing a commit message.) Your first-line summary, after the
labels, should be [short, to the point, and written in the imperative
mood.][good-messages] As described in that link, your final commit message
should *also* almost always include an in-depth description of the ‘why’ of your
work: provide rationale for any decisions made during development. (I,
personally, find it helps to keep a log of development notes while working.)

    (- re doc) Document commits with clear messages

    This is an example of a good commit message. The labels are accurate,
    the summary is short and written as an instruction ‘to the code’, and
    there is a more in-depth description of the work being committed in the
    ‘body’ below.

   [granular committing]: <http://blog.elliottcable.name/posts/granular_committing.xhtml>
   [.gitlabels]: <https://github.com/elliottcable/.gitlabels#readme>
   [good-messages]: <http://chris.beams.io/posts/git-commit/>

### Submitting the code
*Surprise:* you don't have to do *any* of the above to open a pull-request
against the project! Your work problem won't be *merged* until that process has
been followed; but that's okay! I'm here to help you out with any part of it.

[Fork the project on GitHub][fork], dive right in, commit some changes, and hit
that [‘create a new pull request’ button.][pureq] Show me what you've got! Once
it's reached a point that I'm happy with, I'll merge it into the `Current` work-
branch, from which changes are later promoted to `Master` as releases are cut.

   [fork]:  <https://github.com/ELLIOTTCABLE/Paws.js/fork>
   [pureq]: <https://github.com/ELLIOTTCABLE/Paws.js/compare>


 > ---- ---- ---- ----
 > 1. I know open-source software is a collaborative process; and I don't want
 >    to come across as claiming ownership of this project for some sort of
 >    skeevy, self-edifying reason: I say ‘my project’ simply because I've been
 >    working nearly alone on it for *many* years. By all means, come by, say
 >    hi, and help me change that to ‘our project.’ (=
 >
 > 2. You have no idea *how* glad. In a similar vein to 1. ... if you show up
 >    and say you have interest in my project, you should definitely imagine me
 >    jumping out of my chair in real life, running in circles, and shouting
 >    ‘yippee!’ before falling to the floor to roll around with my dogs.
 >
 >    So, yeah. Super, super-glad.
 >
 > 3. Time, after time, in my programming career, I've seen it demonstrated that
 >    the *flavour of a language's community* informs and influences the flavour
 >    of every single community that uses or depends on that language.
 >    Programming languages aren't just important tools; their communities are
 >    ground-zero for the *experience* of participating in that particular
 >    sector of software-development.
 >
 >    So, yes, I think people with experience with healthy, inclusive, and safe
 >    *communities* are probably the single most important resource of a
 >    fledging language; beyond any other participant, from the average user to
 >    the academic programming-language theorist.
