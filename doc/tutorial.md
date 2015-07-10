
# Demo Apps and App Developer Tutorial

Jump to a section:
 * [Introduction](#introduction)
 * [Demo apps](#demo-apps)
 * [Tutorial](#tutorial)

## Introduction

### What can I build with this platform?

The [architecture](../README.md#architecture) of webLurch is applications
built on the *Lurch Web Platform*, which in turn is built on the WYSIWYG
editor [TinyMCE](http://www.tinymce.com).  Here are the details:
 * TinyMCE provides:
   * WYSIWYG editing of HTML content
     <br><img src='doc/tinymce-screenshot.png' width='50%' height='50%'>
   * Extendability through custom toolbars, menus, dialogs, etc.
 * The *Lurch Web Platform* builds on that foundation, and provides:
   * [Load/Save functionality into the browser's
     LocalStorage](../app/loadsaveplugin.litcoffee)
     <br><img src='doc/save-commands.png'>
   * A WYSIWYG math editing widget, [imported from
     here](https://github.com/foraker/tinymce_equation_editor)
     <br><img src='doc/equation-editor.png'>
   * __*Groups*__, the most important contribution of the *Lurch Web
     Platform*, [explained below](#what-are-groups).
   * Facilities for computing with groups, such as
     [a background computation/parallelization toolkit](../src/background.litcoffee)

### What are groups?

The crux of the user interface for the desktop version of Lurch is the
ability for the user to mark portions of a document as *meaningful* with
groups, sometimes calld "bubbles" because of how they are drawn on screen.

Examples:
 * Wrap a bubble around a mathematical expression to tell Lurch to pay
   attention to its meaning.  Lurch puts a tag above the bubble to let the
   user see what the content means to Lurch.
   <br><img src='doc/bubble-typeset-math.png'>
 * Wrap a bubble around some text to give it some application-specific
   meaning.  The following screenshot is from an application for authoring
   OpenMath Content Dictionaries.
   <br><img src='doc/bubble-OM-CDReviewDate.png'>
 * Complex nested group hierarchies are possible and very useful.  Desktop
   Lurch uses them constantly:
   <br><img src='doc/bubble-many.png'>

[Read about about the importance of this user interface
paradigm.](http://lurchmath.org/2013/04/12/what-have-we-built-so-far-part-1-of-2/)

## Demo Apps

Enough preliminaries -- let's dive in!  Here are some examples of what you
can do with the *Lurch Web Platform*.  Visit as many as you like and try
them out.

### Apps to play with online

(Warning:  These apps are interesting to try out online, but if you're
trying to learn to code Lurch Web Applications, read the code for the sample
apps in the next section first.)

 * __Math Evaluator__ - Wrap any typeset mathematical expression in a bubble
   and you can ask the app to evaluate it or show you its internal
   structure.
   * [Live demo online](http://nathancarter.github.io/weblurch/app/math-example.html)
   * [Documented source code](../app/math-example.solo.litcoffee)
 * __OpenMath Content Dictionary Creator__ - An app that lets you write an
   [OpenMath Content Dictionary](http://www.openmath.org/cd/) in a
   user-friendly word processor, then export its raw XML for use elsewhere.
   This is a specific example of an entire category of apps for editing
   hierarchically structured meanings.
   * [Live demo online](http://nathancarter.github.io/weblurch/app/openmath-example.html)
   * [Documented source code](../app/openmath-example.solo.litcoffee)

### Apps to learn from when developing

 * Simple Example - Developers start here because it's highly documented and
   extremely simple.
   * [Live demo online](http://nathancarter.github.io/weblurch/app/simple-example.html)
   * [Documented source code](../app/simple-example.solo.litcoffee)
 * Complex Example - After you understand the Simple Example, go here.  It
   defines two group types rather than one, and shows how to add context
   menus and do lengthy background computations, among other things.
   * [Live demo online](http://nathancarter.github.io/weblurch/app/complex-example.html)
   * [Documented source code](../app/complex-example.solo.litcoffee)

## Tutorial

You can build a *Lurch Web Application* in three phases.
 * Phase 1: Create a web page that imports the *Lurch Web Platform*.
 * Phase 2: Write code that defines a set of group (i.e., bubble) types.
 * Phase 3: Optionally add new and custom behaviors to those types.

This section gives step-by-step instructions for creating your own *Lurch
Web Application.*  By the end of this section, you will have completed
Phases 1 and 2 on the list, and will know where to go to learn about Phase
3.

### Phase 1: A first app (and a very simple one)

 1. Get a copy of this repository set up on your local machine.
    [See instructions here.](getting-started.md)  You may be able to forge
    ahead even if you've never tried to learn [literate
    CoffeeScript](www.coffeescript.org#literate), because the language is
    extremely readable.  But you can learn its basics at that link before
    proceeding if you prefer.
 1. Ensure that you can build and run the Simple Example app, as follows:
    * I assume you have built the app and started the web server as the
      instructions in the previous bullet point said.
    * Visit `http://localhost:8000/app/simple-example.html` to see the
      simple example app in action.
 1. Make a copy of that app to use as the basis for yours.
    * In the `app/` subfolder, make copies of the files
      `simple-example.html` and `simple-example.solo.litcoffee`, naming them
      something like `myapp.html` and `myapp.solo.litcoffee`.
    * Re-run `cake app` from the terminal to compile your new `.litcoffee`
      file.  (You will need to do this after each change to the source.)
      This should create several files that start with `app/myapp.solo`.
    * Change the last `<script>` tag in the `.html` file you just created so
      that it imports `myapp.solo.min.js` file rather than
      `simple-example.solo.min.js`.
    * Visit `http://localhost:8000/app/myapp.html` to ensure that this
      worked.  It should look exactly like the simple app you already saw.
 1. Edit `myapp.solo.min.js`.
    * The file begins with a lot of documentation, and then the first line
      of code is `setAppName 'ExampleApp'`.  Change the contents of the
      string to your app's name.
    * Rebuild using `cake app` and revisit the page to ensure that the app
      name in the browser's tab has changed to your app's name.

You've created a (very simple) app!  And you know how to change your app's
code, rebuild, and visit your updated app.  So what kinds of code changes
are possible?  Let's see.

### Phase 2: Changing or adding group types

The individual bubbles you see in the document are the visual representation
of what, under the hood, are called "groups."  Each app has a different set
of group types that the user may insert in the document, depending on the
needs of the application.  Examples:
 * In the simple app you have, there is only one group type, and it does
   almost nothing.  (It does write to the browser console, but that's
   hardly exciting.)
 * [The complex demo app](../app/complex-example.solo.litcoffee) defines two
   group types, one for wrapping and evaluating expressions of arithmetic
   and another for wrapping and doing simple computations on words.
 * In the math demo app there is only one group type, for parsing and
   evaluating mathematical expressions.
 * In the OpenMath Content Dictionary demo app there is only one group
   type, but it can have any of over a dozen different purposes, editable
   using the context menu on each individual group.

If we look at the code in your app that defines group types, stripping away
all the documentation, it looks like the following.

```coffeescript
window.groupTypes = [
    name : 'reporter'
    text : 'Simple Event Reporter'
    imageHTML : '[ ]'
    openImageHTML : '['
    closeImageHTML : ']'
    tagContents : ( group ) ->
        "#{group.contentAsText()?.length} characters"
    contentsChanged : ( group, firstTime ) ->
        console.log 'This group just changed:', group.contentAsText()
]
```

All of this is fully documented [in the original
file](../app/simple-example.solo.litcoffee#define-one-group-type), so I do
not repeat here what any of it means.  But note that this is simply the
assignment to a global variable of an array of group type data.  You could
extend it to add another group type as follows.

```coffeescript
window.groupTypes = [
    name : 'reporter'
    text : 'Simple Event Reporter'
    imageHTML : '[ ]'
    openImageHTML : '['
    closeImageHTML : ']'
    tagContents : ( group ) ->
        "#{group.contentAsText()?.length} characters"
    contentsChanged : ( group, firstTime ) ->
        console.log 'This group just changed:', group.contentAsText()
,
    name : 'myNewGroupType'
    text : 'My New Group Type'
    imageHTML : '{}'
    openImageHTML : '{'
    closeImageHTML : '}'
    tagContents : ( group ) -> 'every tag has this content'
    # no event handler for changes to group contents
]
```

Rebuilding your app and reloading it in the browser should then let you
insert either kind of group.  Note the two different buttons on the toolbar,
one for each group type.

By simply extending the list above, you can define any set of group types
you see fit in your application.

The only question that remains is how to make them do something useful.

### Phase 3: Adding interactivity to your groups

What else can your app do?  Lots of things!  I don't teach each one in
detail here, but I give many exmples, each with a link to where you can read
more information and see example code.

 * Report on the bubble's tag information about the group
   * Every example app you've seen so far does this.  Simply search the
     source code repository for the `tagContents` function and look at the
     variety of implementations.
   * You will want to be able to query information about your group, such as
     what its contents are as text, or whether it has any groups inside of
     it, and so on.  You can learn all about the API for a Group object by
     reading [the documented source code for the Groups
     Plugin](../app/groupsplugin.litcoffee).
 * Store and retrieve custom data in a Group object
   * In the API linked to immediately above, see the `set`, `get`, and
     `clear` functions in the `Group` class.  These store arbitrary JSON
     data by string keys in a group.
   * It is very common to do a computation and store its result in an
     attribute of the group, the read that later when computing the contents
     of the group's tag, thus giving the user feedback on the results of
     some background process.
 * Find what groups are in the document
   * The short answer to how to do this is to examine the API for the
     `Groups` class (different from the `Group` class!) in
     [the Groups Plugin](../app/groupsplugin.litcoffee).  However, since
     that file (and API) are large, I will summarize some details here.
   * Access the one, global `Groups` object using the code
     `tinymce.activeEditor.Groups`.  I call this object `Groups` hereafter.
   * Get a list of all group IDs in your document (in the order their open
     boundaries appear in the document) with `Groups.ids()`.
   * Look up an actual group object using its ID by simply indexing
     `Groups` as if it were an array, `Groups[putIdHere]`.
   * For any group `G`, get the group containing it with `G.parent`, which
     may be null if there is none.
   * For any group `G`, get an ordered array of the groups it (immediately)
     contains with `G.children`.
 * Pushing complex computations into the background
   * The *Lurch Web Platform* provides functionality for moving arbitrary
     computations into one or more background threads, with parallelization
     managed efficiently for you.
   * This topic requires a lot of discussion, so I will instead send you to
     two files:
   * [The "complex example" demo app](../app/complex-example.solo.litcoffee)
     pushes some computations into the background, and you can follow its
     example code.
   * [The background module](../src/background.litcoffee) documents the full
     API that's being leveraged by that demo app.
 * Extending the menus that appear when users right-click a group or click
   its bubble tag
   * Extending a group's context menu is done by providing a
     `contextMenuItems` function in the group type definition.  Search the
     repository for that phrase to see examples.  One appears in [the
     source code for the complex example demo
     app](../app/complex-example.solo.litcoffee).
   * Extending a group's tag menu is done by providing a `tagMenuItems`
     function that behaves exactly the same way, but may choose to return a
     different list of menu items.
 * Adding new buttons to the editor toolbar
   * This is done by assigning to the global object
     `window.groupToolbarButtons`.
   * [See an example
     here.](../src/xml-groups.solo.litcoffee#define-one-toolbar-button)
 * Adding new menu items to the editor's menus
   * This is done by assigning to the global object
     `window.groupMenuItems`.
   * There is not an example of this at the moment, but it functions very
     similar to the previous bullet point, about toolbar buttons.  The
     implementation appears in
     [the main setup code](../app/setup.litcoffee).
 * Showing dialog boxes
   * TinyMCE provides [a few ways to show dialog boxes containing plain
     text](http://www.tinymce.com/wiki.php/api4:class.tinymce.WindowManager).
   * If your dialog box must contain more than just plain text, inspect the
     `showHTMLPopup` function defined in
     [the XML Groups module](../src/xml-groups.solo.litcoffee).
 * Adding decorations to group boundaries
   * It is common to give feedback to the user about the content of a group
     in a more obvious way than the bubble tag (which is only visible when
     the user's cursor is in a document).  For instance, if there is an
     error in something a user has entered in a group, you might want to
     flag it in an obvious way, as in the following example from
     [the OpenMath Content Dictionary Editor demo
     app](../app/openmath-example.solo.litcoffee).
     <br><img src='bubble-with-error.png'><br>
     This is a special case of "decorating" a group.  To add decorations to
     a group `G`, you have the following API.
   * `G.set 'openDecoration', 'any valid HTML here'` - sets the decoration
     that will appear to the left of its open boundary marker (not used in
     the image above)
   * `G.set 'closeDecoration', 'any valid HTML here'` - same as the previous
     but for after the close boundary marker (as in the image above)
   * `G.clear 'openDecoration'` and `G.clear 'closeDecoration'` behave as
     expected
   * Note that there are many useful Unicode characters for visually giving
     understandable feedback concisely.  Consider the following, each of
     which can be made more informative by wrapping it in
     `<font color="red">...</font>`, as in the image above,
     or some other color suiting your application.
     * X's
       * &amp;#10006; is &#10006;
       * &amp;#10007; is &#10007;
       * &amp;#10007; is &#10008;
     * Checks
       * &amp;#10003; is &#10003;
       * &amp;#10004; is &#10004;
     * Stars
       * &amp;#10029; is &#10029;
       * &amp;#10038; is &#10038;
       * &amp;#10039; is &#10039;
       * &amp;#10040; is &#10040;
       * &amp;#10041; is &#10041;
     * Numbers
       * &amp;#10122; is &#10122;
       * ... in order through ...
       * &amp;#10131; is &#10131;

This tutorial was written by [Nathan Carter](mailto:ncarter@bentley.edu).
Feel free to contact me with questions.  I would love to know how we can
help get you started coding on the *Lurch Web Platform*.
