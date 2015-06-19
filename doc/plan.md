
# Project Plan

Readers unfamiliar with this project may wish to first read what's already
been accomplished, on the [Project Progress](progress.md) page.  This page
is a complement to that one, stating what remains to be done.

This document aims to be a complete plan for what needs to be done on this
project, readable by developers.  It can therefore be viewed as a to-do list
in chronological order, the first items being those that should be done
next, and the later items those that must come after.  Necessarily, the
later items are more vague than the earlier ones.

Note also that there are some [known bugs and planned enhancements](
bugs-and-enhancements.md) not listed in this file, because they are not part
of the linear progression of the project.  They can be addressed whenever it
becomes convenient or useful; this document lists things in a more-or-less
required order of completion.

## OpenMath

This work is in progress.  Here are the remaining tasks:
 * Add the following methods to the OpenMath object class
   * reparent(newPar), remove(), and replaceWith(newTree), and then begin
     using these in the existing factory functions to ensure correct
     parentage
   * insertChild(), removeChild(), appendChild()
   * copy(), which should be as efficient as possible
   * equals()
   * isFree(), replaceFree(from,to), occursFreeIn()
   * applySubstitution() and applyAllSubstitutions() (which work with
     expressions of the form `x[y=z]`, meaning x with all occurrences of y
     replaced by z, and `x[y~z]`, meaning the same but "some" isntead of
     "all")
   * childrenSatisfying() and descendantsSatisfying()
 * Add a constructor that takes a type as the first argument (being flexible
   enough to handle things like 'i', 'int', 'integer', etc.) and all other
   data as the remaining arguments, in a sensible order.
 * Create extensive unit tests for the above class and its algorithms.

## Matching Module

This is a re-implementation (and improvement) of the matching module from
the desktop version of Lurch.
 * Create a file `src/matching.duo.litcoffee`.
 * Create a function for marking a variable as a metavariable with an
   attribute, and another for testing whether a variable is a metavariable.

First, a supporting class, Match.
 * Create a Match class, representing an evolving match state throughout a
   matching process.
 * Give it members for using it as a variable-to-expression dictionary,
   `get`, `set`, and `has`.
 * Give it a member for marking that a substitution of A to B is in force,
   for any two expressions A and B.  A third parameter will specify whether
   the subsitution is required (=) or optional (~), and should also be
   stored.  Give it another method for removing a substitution.
 * Give it a member for marking which subtrees it has visited, and storing
   them in an internal list.  It only does anything if a substitution is in
   force; otherwise it does nothing.
 * When setting a substitution, do all possible metavariable replacements on
   both halves of it.  Also augment `set` so that all future metavariable
   instantiations are immediately applied to both halves of the
   substitution.  For both of those functions, if the two halves of the
   substitution become fully instantiated (no metavariables) then ensure
   that the substitution is either optional or alters no previously-visited
   subtrees; return true/false accordingly.
 * Make getters for all of the substitution data, including one for just
   whether a substitution has been stored.
 * Give it a member for checking whether a required substitution would alter
   any of the already-visited subtrees.
 * Give it a method for cloning itself.
 * Give it a method for applying itself to an expression, replacing all
   metavariables with their current instantiations.
 * Give it a method for finding in its first-visited subtree (the whole
   pattern) all metavariables, and then creating instantiations for all
   those that don't yet have them, to names like "unused_1", "unused_2", ...
 * Create extensive unit tests for the above class and its algorithms.

Now, the main routine.
 * Implement the matching algorithm after the following psuedocode.

    matches = ( pattern, expression, soFar ) ->

Determine whether we're the outermost call in the recursion, for use below.

        outermost = not soFar?
        soFar ?= new Match

Mark that we've visited this subtree of the pattern.

        soFar.visited pattern

Handle patterns of the form x[y=z] and x[y~z].

        if pattern is of the form x[y=z] or x[y~z]
            if soFar has a substitution already then throw an error
                saying that there's only supposed to be one per pattern
            check = soFar.setSubstitution y, z, ( = or ~ )
            if not check return [ ] # doesn't fit with a visited subtree
            results = matches x, expression, soFar
            for result in results
                result.removeSubstitutionRecord()
            results

Handle patterns that are single metavariables.

        if the pattern is just a metavariable
            if soFar.get variableName
                if it's equal to expression return [ soFar ] else return [ ]
            check = soFar.set variableName, expression
            if not check return [ ] # doesn't fit with a visited subtree
            return [ soFar ]

Define a function for handling when the match would fail without the
substitution expression.

        pair = ( a, b ) -> OM.app OM.sym('pair','Lurch'), a.copy(), b.copy()
        trySubs = ->
            if soFar doesn't have a substitution in it
            s = pair soFar.substLHS, soFar.substRHS
            [ walk1, walk2, result ] = [ pattern, expression, [ ] ]
            while walk1?
                result = result.concat matches pair(walk1,walk2), s, soFar
                [ walk1, walk2 ] = [ walk1.parent, walk2.parent ]
            result

Now we enter the meat of structural matching.  If the types don't even
match, then the only thing that might save us is a substitution, if there
is one.

        if pattern.type isnt expression.type then return trySubs()

Handle atomic patterns.

        if the pattern is an atomic type
            return if pat.equals expr then [ soFar ] else trySubs()

Non-atomic patterns must have the same size as their expressions.

        if pattern.children.length isnt expression.children.length
            return trySubs()

Prepare to recur.

        children1 = compute ordered list of all children of pattern
        children2 = same, but for expression
        results = [ soFar ]

Recur on children.

        for child1, index in children1
            child2 = children2[index]
            newResults = [ ]
            for sf in results
                copy = sf.copy()
                newResults = newResults.concat matches child1, child2, copy
            results = newResults

Before returning the results, if we are the outermost call, instantiate all
unused metavariables to things like "unused_1", etc.

        if outermost
            for result in results
                result.instantiateUnusedMetavariables()
        results

 * Create extremely extensive unit tests for the above matching algorithm.
   I list an extensive test suite here, using capital letters for
   metavariables and lower case letters for regular variables, and otherwise
   easily human-readable/suggestive notation.  The one exception is that @
   means the universal quantifier and # means the existential quantifier.
   Note that these unit tests do not require a PhantomJS environment.
```
    pattern             expression      results
    -------             ----------      -------

    ATOMICS

    a                   a               [{}]
    a                   b               []
    a                   2               []
    a                   f(x)            []
    A                   anything        [{A:expression}] for various exprs
        repeat these tests for other atomic types besides variable a

    COMPOUNDS

    A(x)                f(x)            [{A:f}]
    A(B)                f(x)            [{A:f,B:x}]
    A(B)                f(x,y)          []
    A(B)                f()             []
    A(B)                atomic          []
        repeat these tests for binding and error types, in addition to appls

    ATTRIBUTES

    repeat a selection of the above tests with attributes added to either
    the pattern or the expression or both, and verify that attributes make
    no change whatsoever to the results

    SIMPLE SUBSTITUTIONS

    f(x)                f(x)[x=y]       []
    f(x)                f(x)[z=y]       [{}]
    f(x)                f(y)[z=y]       [{}]
    @x,f(x)             @x,(f(x)[x=y])  []
    @x,f(x)             (@x,f(x))[x=y]  [{}]
        then repeat all with the pattern and expression swapped

    COMPOUNDS WITH METAVARIABLES

    f(A,B)              f(c,d)          [{A:c,B:d}]
    f(A,A)              f(c,d)          []
    f(A,B)              g(c,d)          []
    f(B,A)              f(c,d)          [{A:d,B:c}]
    f(A,A)              f(c,c)          [{A:c}]
    f(g(A),k(A))        f(g(a),k(a))    [{A:a}]
    f(g(A),B)           f(g(a),k(a))    [{A:a,B:k(a)}]
    f(A(c),A(B))        f(g(c),k(c))    []
    f(A(c),A(B))        f(g(c),c(k))    [{A:c,B:k}]
        repeat a selection of the above tests using bindings and errors
        instead of applications

    UNIVERSAL ELIMINATION RULE

    Let R = list( @X,A , A[X=T] ), a representation of the rule.  In each
    test below, R is the pattern, and we list only the expression.
    When a capital letter is followed by a prime, as in A', that means that
    it is going directly against the naming convention, and intending to be
    a capital A that is NOT a metavariable.  This will test to ensure that
    naming conflicts between metavariables and their instantiations do not
    mess up the results.

    list( @x,f(x)=f(y) , f(6)=f(y) )    [{X:x, A:f(x)=f(y), T:6}]
    list( @x,P(x,x) , P(7.1,7.1) )      [{X:x, A:P(x,x), T:7.1}]
    list( @x,P(x,x) , P(3,4) )          []
    list( @x,(x>7 & @y,P(x,y)) ,
          9>7 & @y,P(9,y) )             [{X:x, A:x>7&@y,P(x,y), T:9}]
    list( @x,(x>7 & @y,P(x,y)) ,
          9>7 & @y,P(x,y) )             []
    list( @A',f(X',A') , f(X',X') )     [{X:A', A:f(X',A'), T:X'}]

    EXISTENTIAL ELIMINATION RULE

    Let R = list( #X,A , const(C) , A[X=C] ).  Same story as above.

    list( #t,t^2<0 , const(r), r^2<0 )  [{X:t, A:t^2<0, C:r}]
    list( #t,t^2<0 , const(r), t^2<0 )  []
    list( #t,t^2<0 , const(t), r^2<0 )  []
    list( #t,t^2<0 , const(t), t^2<0 )  [{X:t, A:t^2<0, C:t}]
    list( #t,t^2<0 , const(phi^2+9) ,
          (phi^2+9)^2<0 )               [{X:t, A:t^2<0, C:phi^2+9}]
    list( #t,r^2<0 , const(r), r^2<0 )  [{X:t, A:r^2<0, C:r}]
    list( #r,r^2<0 , const(r), r^2<0 )  [{X:r, A:r^2<0, C:r}]
    list( #C',A'<C' , const(X'), A'<X' )[{X:C', A:A'<C', C:X'}]

    UNIVERSAL INTRODUCTION RULE

    Let R = list( var(V) , A , @X,A[V=X] ).  Same story as above.

    list( var(x), x^2>=0, @t,t^2>=0 )   [{V:x, A:x^2>=0, X:t}]
    list( var(x), x^2>=0, @x,x^2>=0 )   [{V:x, A:x^2>=0, X:x}]
    list( var(x), x^2>=0, @x,t^2>=0 )   []
    list( var(x), t^2>=0, @x,x^2>=0 )   []
    list( var(x), t^2>=0, @x,t^2>=0 )   [{V:x, A:t^2>=0, X:x}]
    list( var(V') , hi(A',V') ,
          @X',hi(A',X') )               [{V:V', A:hi(A',V'), X:X'}]

    EXISTENTIAL INTRODUCTION RULE

    Let R = list( A[X=T], #X,A ).  Same story as above.

    in(5,nat)&notin(5,evens) ,
        #t,in(t,nat)&notin(t,evens)     [{A:in(t,nat)&notin(t,evens), X:t,
                                          T:5}]
    uncble(minus(reals,rats)) ,
        #S',uncble(S')                  [{A:uncble(S'), X:S',
                                          T:minus(reals,rats)}]
    uncble(k) , #k,uncble(k)            [{A:uncble(k), X:k, T:k}]
    in(4,nat)&notin(5,evens) ,
        #t,in(t,nat)&notin(t,evens)     []
    in(4,nat)&notin(4,evens) ,
        #t,in(t,nat)&notin(t,evens)     []
    in(5,nat)&notin(5,evens) ,
        #x,in(t,nat)&notin(t,evens)     []
    in(5,nat)&notin(5,evens) ,
        #x,in(5,nat)&notin(5,evens)     [{A:in(5,nat)&notin(5,evens), X:x,
                                          T:unused_1}]
    L' , #M',L'                         [{A:L', X:M', T:unused_1}]
    L'(M') , #N',L'(N')                 [{A:L'(N'), X:N', T:M'}]

    EQUALITY ELIMINATION RULE

    Let R = list( A=B , S , S[A~B] ).  Same story as above.

    x=7 , f(x)=y , f(7)=7               [{A:x, B:7, S:f(x)=y}]
    x=7 , f(x)=y , f(x)=7               []
    x=7 , f(x)=y , f(7)=7               []
    f(x)=y , x=7 , f(7)=7               []
    a=b , b=b , b=a                     [{A:a, B:b, S:b=b}]
    sum(i,0,n-1,2^i)=2^n-1 ,
        (2^n-1)+1=2^n ,
        sum(i,0,n-1,2^i)+1=2^n          []
    2^n-1=sum(i,0,n-1,2^i) ,
        (2^n-1)+1=2^n ,
        sum(i,0,n-1,2^i)+1=2^n          [{A:sum(i,0,n-1,2^i), B:2^n-1,
                                          S:(2^n-1)+1=2^n}]

    HARDER SUBSTITUTIONS

    Now we list pattern, expresion, and results, as at first.

    a=b[X=Y]            a=b             [{X:unused_1,Y:unused_2}]
    a=b[X=a]            a=b             [{X:unused_1}]
    a=b[a=Y]            a=b             [{Y:a}]
    a=b[a=b]            a=b             []
    a=b[a~b]            a=b             [{}]
    a=b[a=c]            a=b             []
    a=b[a~c]            a=b             [{}]
    a=b[a=a]            a=b             [{}]
    A[a=b]              a=b             []
    A[a~b]              a=b             [{A:a=b}]
    A[c=b]              a=b             [{A:a=b}]
    A[c~b]              a=b             [{A:a=b}]
    A[B=b]              a=b             [{A:a=b,B:unused_1}]
    A[B~b]              a=b             [{A:a=b,B:unused_1}]
    f(f[A=g])           f(g)            [{A:f}]
    f(f)[A=g]           g(g)            [{A:f}]
    f(f[A=g])           g(g)            []
    f(g(a))[A=B]        f(g(b))         [{A:a,B:b}]
    f(g(a),a)[A=B]      f(g(b),a)       []
    f(g(a),a)[A~B]      f(g(b),a)       [{A:a,B:b}]
    f(g(a),a)[A=B]      f(g(b),c)       []
    f(g(a),a)[A~B]      f(g(b),c)       []
        previous four cases repeated, but with first and second arguments
        in both the pattern and the expression interchanged should give same
        results

    UNDERSPECIFIED

    A[B=C]              any(thing)      [{A:any(thing),B:unused_1,
                                          C:unused_2}]
    A[B~C]              any(thing)      [{A:any(thing),B:unused_1,
                                          C:unused_2}]

    Also verify that if there are metavariables in the expression, that an
    error is thrown.
```

## Parsing

 * Import the Earley parser from the desktop version of Lurch, into the file
   `src/parsing.duo.litcoffee`.
 * Document it, while creating unit tests for its features.
 * Create a routine that translates MathQuill DOM trees into unambiguous
   string representations of their content (using parentheses to group
   things like exponents, etc.).
 * Use the web app to create and save many example DOM trees using the
   MathQuill TinyMCE plugin, for use in unit tests.
 * Manually convert each of those into unambiguous strings, and use those to
   generate unit tests for the translation routine created above.
 * Create a parser that can convert such strings into OpenMath trees.
 * Convert all the previous tests into unit tests for that parser.

## Example Application

Create a tutorial page in the repository (as a `.md` file) on how the reader
can create their own webLurch-based applications.  Link to it from [the main
README file](../README.md).

It might be nice to have another example application, this one that lets you
write math formulas in ordinary mathematical notation, and then does simple
computations based on them, using MathJS.  You would need a method for
converting OpenMath trees into MathJS calls.

That is the last work that can be done without there being additional design
work completed.  The section on [Dependencies](#dependencies), below,
requires us to design how background computation is paused/restarted when
things are saved/loaded, including when they are dependencies.  The section
thereafter is about building the symbolic manipulation core of Lurch itself,
which is currently being redesigned by
[Ken](http://mathweb.scranton.edu/ken/), and that design is not yet
complete.

## Logical Foundation

### Dependencies

This section connects tightly with [Extending load and
save](#extending-load-and-save), below.  Be sure to read both together.
Also, this will need to be extended later when enhancing Lurch to be usable
offline; see [Offline support](#offline-support), below.

 * Reference dependencies by URLs; these can be file:/// URLs, which is a
   reference to LocalStorage, or http:// URLs, which is a reference to
   `lurchmath.org`.
 * Provide a UI for editing the dependency list for a document.  Store this
   data outside the document.
 * Load/save that metadata using the `loadMetaData` and `saveMetaData`
   members of the LoadSave plugin.
 * Design what you will do when files are opened/closed, re: computation of
   the meaning in them and their dependencies.  Issues to consider:
   * If background computations are pending on a document, should the user
     be permitted to save it?  What if it's used as a dependency elsewhere?
     Will that cause it to be loaded in a permanently-paused-as-incomplete
     state in the other document?
   * Or does that imply that we should recompute lots of stuff about each
     dependency as it's loaded, in invisible DOM elements somewhere?  That
     sounds expensive and error-prone.
   * Knowing whether recomputation is needed could be determined by
     inspecting an MD5 hash of the document to see if it has changed since
     the last computation.  This is what [SCons
     does](http://www.scons.org/doc/0.98.4/HTML/scons-user/c779.html).

## Real Lurch!

Build the 3 foundational Group types, according to Ken's new spec!

## For later

### Extending load and save

We may later want to add more load-and-save features, such as Dropbox
integration.  See the following web links for details on how such extensions
could be implemented.

Dropbox:

 * [You can use ready-made open and save dialogs.](
   https://www.dropbox.com/developers/dropins)
   This is minimally invasive, but does not allow you to upload files from
   the browser's LocalStorage (at the time of this writing).  Rather, it
   only permits uploading files from the user's hard drive.
 * [You can store tables that are a JSON-SQL hybrid.](
   https://www.dropbox.com/developers/datastore)
   This is quite general, but also comes with increased complexity over
   the previous option.  It is not, however, really that complex.
 * A bonus on top of the previous bullet point is that
   [recent, bleeding-edge changes in the API](
   https://www.dropbox.com/developers/blog/99/using-the-new-local-datastores-feature)
   make it possible to use one codebase for both local storage and Dropbox
   storage, a very attractive option.

Local filesystem:

 * If Dropbox is not used, and thus the user's files are not present on
   their own local machine, provide a way to transfer files from their
   local filesystem to/from the browser's LocalStorage?

Sharing:

Add the ability to share documents with the world.  I considered
[Firebase](https://www.firebase.com/), but it seemed like too much work, and
requires integrating a whole new technology.  If using Dropbox, we might be
able to make files shared, if the API supports that.  But that, too,
introduces new sources of complexity, and requires users to get Dropbox.  So
I have the following recommended solution.
 * Create a wiki on `lurchmath.org` into which entire Lurch HTML files
   can be pasted as new pages, but only editable by the original author.
   This way instructors can post on that wiki core dependencies that
   anyone can use, and the integrity of a course (or the whole Lurch
   project!) is not dependent on the state of any individual's Dropbox
   folder.
 * Note that external websites are not an option, since `XMLHttpRequest`
   restricts cross-domain access, unless you run a proxy on `lurchmath.org`
   or set up CORS rules in the web server running there.  Thus we must host
   the webLurch application and the wiki on the same domain,
   `lurchmath.org`.  This is even more true since many of the improvements
   suggested below require wiki extensions to access the same `LocalStorage`
   object that the webLurch app itself is accessing, which requires them to
   come from the same domain.
 * This could be even better as follows:
   * Write a plugin for the wiki that can access the same LocalStorage
     filesystem that Lurch does, and can pop up dialogs with all your
     Lurch documents.  Just choose one and the wiki will paste its
     content cleanly into the page you're editing, or a new page, your
     choice.
   * Similarly, that same wiki plugin could be useful for extracting a
     copy of a document in a wiki page into your Lurch filesystem, for
     opening in the Lurch app itself thereafter.
   * Make the transfer from Lurch to the wiki even easier by providing a
     single button in Lurch that exports to the wiki in one click, using
     some page naming convention based on your wiki username and the
     local path and/or name of the file.  Or perhaps, even better, you
     have a public subfolder of your Lurch filesystem that's synced, on
     every document save or Manage Files event, to the wiki, through
     `XMLHttpRequest` calls.
   * Make the transfer from the wiki to Lurch even easier by providing a
     single "Open in Lurch" button in the wiki that stores the document
     content in a temporary file in your Lurch filesystem, then opens
     Lurch in a new tab.  The Lurch app will then be smart enough to
     open any such temporary file on launch, and then delete it (but the
     user can choose to save it thereafter, of course).

### Making things more elegant

 * Eventually, pull the LoadSave plugin out into its own repository on
   GitHub, so that anyone can easily get and use that TinyMCE plugin, and
   improve on its code.

### Offline support

To make an HTML5 app available offline, I believe the appropriate step is
simply to provide an app manifest.  I'm verifying that with [this
StackOverflow
question](http://stackoverflow.com/questions/27136144/how-can-online-offline-versions-of-an-html5-app-access-the-same-localstorage).
That question links to a tutorial on app manifests, if the answer turns out
to be "yes" to that question.

Once the app is usable offline, it will also be helpful to cache in
LocalStorage the meaning computed from all dependencies, so that Lurch is
usable offline even when dependencies of the current document are online.

### Ideas from various sources

Suggestion from Dana Ernst: Perhaps this is not necessary or feasible, but
if you go with a web app, could you make it easy for teachers to "plug into"
the common LMS's (e.g. Blackboard, Canvas, etc.)?  I'm envisioning students
being able to submit assignments with ease to an LMS and then teachers can
grade and enter grades easily without have to go back and forth between web
pages.  

Suggestion from Dana Ernst: I’ve been having my students type up their
homework using writeLaTeX.  One huge advantage of this is that students can
share their project with me.  This allows me to simultaneously edit their
document, which is a great way for me to help students debug.  I give them a
ton of help for a week or two and then they are off and running on their
own.  It might be advantageous to allow multiple users to edit the same
Lurch document.  No idea if this is feasible or not, nor if it is even an
idea worth pursuing.

If we have the wiki integration as [described
above](#extending-load-and-save), is it possible for the entire Lurch app to
exist inside the wiki, so that editing a wiki page was done using Lurch as
the editor?  That would be excellent for many use cases.  Offline use would
still necessitate the normal app, and this would be tricky to accomplish,
because wiki integration of something that complex will be touchy, but it
would be impressive and intuitive.

A web Lurch is trivially also a desktop Lurch, as follows.  You can, of
course, write a stupid shell app that’s just a single web view that loads
the Lurch web app into it.  This gives the user an app that always works
offline, has an icon in their Applications folder/Start menu, etc., and
feels like an official app that they can alt-tab to, etc., but it’s the
exact same web app, just wrapped in a thin desktop-app shell.  You can then
add features to that as time permits.  When the user clicks “save,” you can
have the web app first query to see if it’s sitting in a desktop-app
wrapper, and if so, don’t save to webstorage, but pop up the usual save box.
same for accessing the system clipboard, opening files, etc., etc.  And
those things are so modular that a different person can be in charge of the
app on different platforms, even!  E.g., someone does the iOS app, someone
does the Android app, and someone does the cross-platform-Qt-based-desktop
app.  Also, there are toolkits that do this for you.  Here are some links.
 * [Node-WebKit](https://github.com/rogerwang/node-webkit)
 * [PHP Desktop](https://code.google.com/p/phpdesktop/)
 * [Webapp XUL Wrapper](https://github.com/neam/webapp-xul-wrapper)
 * [Atom Shell](https://github.com/atom/atom-shell/) which seems to be like
   Node-WebKit, except it's Node-Chromium
 * See more information in [this blog post](http://blog.neamlabs.com/post/36584972328/2012-11-26-web-app-cross-platform-desktop-distribution).

### Improving documentation

Documentation at the top of most unit test spec files is incomplete. Add
documentation so that someone who does not know how to read a test spec file
could learn it from that documentation.  Probably the best way to do this is
to add general documentation to the simplest/main test spec, and then
reference that general documentation from all other test specs.
