
# Overlay Plugin for [TinyMCE](http://www.tinymce.com)

This plugin creates a canvas element that sits directly on top of the
editor.  It is transparent, and thus invisible, unless items are drawn on
it; hence it functions as an overlay.  It also passes all mouse and keyboard
events through to the elements beneath it, so it does not interefere with
the functionality of the rest of the page in that respect.

# `Overlay` class

We begin by defining a class that will contain all the information needed
about the overlay element and how to use it.  An instance of this class will
be stored as a member in the TinyMCE editor object.

This convention is adopted for all TinyMCE plugins in the Lurch project;
each will come with a class, and an instance of that class will be stored as
a member of the editor object when the plugin is installed in that editor.
The presence of that member indicates that the plugin has been installed,
and provides access to the full range of functionality that the plugin
grants to that editor.

    class Overlay

We construct new instances of the Overlay class as follows, and these are
inserted as members of the corresponding editor by means of the code [below,
under "Installing the Plugin."](#installing-the-plugin)

        constructor: ( @editor ) ->

The first task of the constructor is to create and style the canvas element,
inserting it at the appropriate place in the DOM.  The following code does
so.  Note the use of `rgba(0,0,0,0)` for transparency, the `pointer-events`
attribute for ignoring mouse clicks, and the fact that the canvas is a child
of the same container as the editor itself.

            @editor.on 'init', =>
                @container = @editor.getContentAreaContainer()
                @canvas = document.createElement 'canvas'
                ( $ @container ).after @canvas
                @canvas.style.position = 'absolute'
                @canvas.style['background-color'] = 'rgba(0,0,0,0)'
                @canvas.style['pointer-events'] = 'none'
                @canvas.style['z-index'] = '10'

We then allow any client to register drawing routines with this plugin, and
all registered routines will be called (in the order in which they were
registered) every time the canvas needs to be redrawn.  The following line
initializes the list of drawing handlers to empty.

            @drawHandlers = []
            @editor.on 'NodeChange', @redrawContents
            ( $ @editor.getContentAreaContainer() ).resize @redrawContent

This function installs an event handler that, each time something in the
document changes, repositions the canvas, clears it, and runs all drawing
handlers.

        redrawContents: ( event ) =>
            @positionCanvas()
            if not context = @canvas?.getContext '2d' then return
            @clearCanvas context
            context.translate 0, ( $ @container ).position().top
            for doDrawing in @drawHandlers
                try
                    doDrawing @canvas, context
                catch e
                    console.log "Error in overlay draw function: #{e.stack}"

The following function permits the installation of new drawing handlers.
Each will receive two parameters (as shown in the code immediately above),
the first being the canvas on which to draw, and the second being the
drawing context.

        addDrawHandler: ( drawFunction ) -> @drawHandlers.push drawFunction

This function is part of the private API, and is used only by
`positionCanvas`, below.  It fetches the `<iframe>` used by the editor in
which this plugin was installed.

        getEditorFrame: ->
            for frame in window.frames
                if frame.document is @editor.getDoc()
                    return frame
            null

This function repositions the canvas, so that if the window is moved or
resized, then before redrawing takes place, the canvas reacts accordingly.
This is called only by the handler installed in the constructor, above.

        positionCanvas: ->
            con = $ @container
            can = $ @canvas
            if not con.position()? then return
            can.css 'top', 0
            can.css 'left', con.position().left
            can.width con.width()
            can.height con.position().top + con.height()
            @canvas.width = can.width()
            @canvas.height = can.height()

This function clears the canvas before drawing.  It is called only by the
handler installed in the constructor, above.

        clearCanvas: ( context ) ->
            context.clearRect 0, 0, @canvas.width, @canvas.height

# Installing the plugin

The plugin, when initialized on an editor, places an instance of the
`Overlay` class inside the editor, and points the class at that editor.

    tinymce.PluginManager.add 'overlay', ( editor, url ) ->
        editor.Overlay = new Overlay editor

Whenever the user scrolls, redraw the contents of the overlay, since things
probably need to be repositioned.

        editor.on 'init', ( event ) ->
            ( $ editor.getWin() ).scroll -> editor.Overlay.redrawContents()
