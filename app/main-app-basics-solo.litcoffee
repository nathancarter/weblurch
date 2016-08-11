
# Main webLurch Application

## Modular organization

This file is the first of several files that make up the main webLurch
Application.  All files whose names are of the form
`main-app-*-solo.litcoffee` in [this same folder](.) are part of the app.
You can see them imported into the app at the end of
[the HTML file defining the app](app.html).

Other files refer back to this one for overall documentation of the app,
which appears here:

## Overview

webLurch is first a word processor whose UI lets users group/bubble sections
of their document, with the intent that those sections can be handled
semantically.  Second, it is also a particular use of that foundation, for
checking students' proofs.  [Read more about that dichotomy
here.](../README.md)

This file is the beginning of that main webLurch application, but it is not
yet complete.  The only complete implementation at present is [the desktop
version](http://lurchmath.org).

This file is loaded by [app.html](app.html), which is almost entirely
boilerplate code (as commented in its source), plus one line that imports
the compiled version of this file.

You can [see a live version of the resulting application online now](
http://nathancarter.github.io/weblurch/app/app.html).

## App Configuration

For details of what each line of code below does, see the documentation for
[demo apps and a developer tutorial](../doc/tutorial.md).

Set the application name, to appear in page title.

    setAppName 'Lurch'

Set the "About" text on the Help menu.

    window.helpAboutText =
        '<center>
            <p>Pre-alpha</p>
            <p>Not yet intended for general consumption</p>
        </center>'

Install the icon that appears to the left of the File menu.

    window.menuBarIcon =
        src : 'icons/apple-touch-icon-76x76.png'
        width : '26px'
        height : '26px'
        padding : '2px'

Later files in this set will populate the following object.  Here we
initialize it with just bare bones content, and later files can extend it.

    window.groupMenuItems =
        file_order : 'sharelink wikiimport wikiexport
                    | appsettings docsettings'

Install the arrows UI for any group types the app will define (which happen
in one of the other `main-app-*-solo.litcoffee` files in the same folder as
this source file).

    window.useGroupConnectionsUI = yes

Use the MediaWiki, Settings, and Dropbox plugins.

    window.pluginsToLoad = [ 'mediawiki', 'settings', 'dropbox' ]

Later files in this sequence may want to add event handlers to be run after
the editor is ready.  We currently have only one function that is run then,
so we create an array to which you can append entries, all of which will be
run by that function.

    window.afterEditorReadyArray = [ ]
    window.afterEditorReady = ( editor ) ->
        func editor for func in window.afterEditorReadyArray

See the other `main-app-*-solo.litcoffee` files in
[the same folder as this source code file](.) for the rest of the app's
configuration and supporting code.
