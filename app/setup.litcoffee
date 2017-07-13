
# App Setup Script

## Specify app settings

First, applications should specify their app's name using a call like the
following.  In this generic setup script, we fill in a placeholder value.
This will be used when creating the title for this page (e.g., to show up in
the tab in Chrome).

    setAppName 'Untitled'

Second, we initialize a very simple default configuration for the Groups
plugin.  It can be overridden by having any script assign to the global
variable `groupTypes`, overwriting this data.  Such a change must be done
before the page is fully loaded, when the `tinymce.init` call, below, takes
place.

    window.groupTypes ?= [
        name : 'example'
        text : 'Example group'
        imageHTML : '['
        openImageHTML : ']'
        closeImageHTML : '[]'
        tooltip : 'Wrap text in a group'
        color : '#666666'
    ]

Clients who define their own group types may also define their own toolbar
buttons and menu items to go with them.  But these lists default to empty.

    window.groupToolbarButtons ?= { }
    window.groupMenuItems ?= { }

Similarly, a client can provide a list of plugins to load when initializing
TinyMCE, and they will be added to the list loaded by default.

    window.pluginsToLoad ?= [ ]

By default, we always make the editor full screen, and a child of the
document body.  But the client can change that by changing the following
values.  The `editorContainer` can be an `HTMLElement` or a function that
evaluates to one.  We can't access the document body yet, so we set it to
null, which will be replaced by the body below, once it exists.

    window.fullScreenEditor = yes
    window.editorContainer = null

We also provide a variable in which apps can specify an icon to appear on
the menu bar, at the very left.  It defaults to an empty object, but can be
overridden, in the same way as `window.groupTypes`, above.  If you override
it, specify its file as the `src` attribute, and its `width`, `height`, and
`padding` attributes as CSS strings (e.g., `'2px'`).

    window.menuBarIcon ?= { }

We also provide a set of styles to be added to the editor by default.
Clients can also override this object if they prefer different styles.

    window.defaultEditorStyles ?=
        fontSize : '16px'
        fontFamily : 'Verdana, Arial, Helvetica, sans-serif'

## Add an editor to the app

This file initializes a [TinyMCE](http://www.tinymce.com/) editor inside the
[main app page](index.html).  It is designed to be used inside that page,
where [jQuery](http://jquery.com/) has already been loaded, thus defining
the `$` symbol used below.  Its use in this context causes the function to
be run only after the DOM has been fully loaded.

    $ ->

Create a `<textarea>` to be used as the editor.

        editor = document.createElement 'textarea'
        editor.setAttribute 'id', 'editor'
        window.editorContainer ?= document.body
        if typeof window.editorContainer is 'function'
            window.editorContainer = window.editorContainer()
        window.editorContainer.appendChild editor

If the query string is telling us to switch the app into test-recording
mode, then do so.  This uses the main function defined in
[testrecorder.litcoffee](./testrecorder.litcoffee), which does nothing
unless the query string contains the code that invokes test-recording mode.

        maybeSetupTestRecorder()

We need the list of group types names so that we can include them in the
toolbar and menu initializations below.

        groupTypeNames = ( type.name for type in groupTypes )

Install a TinyMCE instance in that text area, with specific plugins, toolbar
buttons, and context menu items as given below.

        tinymce.init
            selector : '#editor'
            auto_focus : 'editor'
            branding : no

These enable the use of the browser's built-in spell-checking facilities, so
that no server-side callback needs to be done for spellchecking.

            browser_spellcheck : yes
            gecko_spellcheck : yes
            statusbar : no
            paste_data_images : true

Not all of the following plugins are working yet, but most are.  A plugin
that begins with a hyphen is a local plugin written as part of this project.

            plugins :
                'advlist table charmap colorpicker image link
                paste print searchreplace textcolor
                -loadsave -overlay -groups -equationeditor -dependencies
                -dialogs -downloadupload ' \
                + ( "-#{p}" for p in window.pluginsToLoad ).join( ' ' ) \
                + ( if window.fullScreenEditor then ' fullscreen' else '' )

The groups plugin requires that we add the following, to prevent resizing of
group boundary images.

            object_resizing : ':not(img.grouper)'

We then install two toolbars, with separators indicated by pipes (`|`).

            toolbar : [
                'newfile openfile savefile managefiles | print
                    | undo redo | cut copy paste
                    | alignleft aligncenter alignright alignjustify
                    | bullist numlist outdent indent blockquote | table'
                'fontselect fontsizeselect styleselect
                    | bold italic underline
                      textcolor subscript superscript removeformat
                    | link unlink | charmap image
                    | spellchecker searchreplace | equationeditor | ' + \
                    groupTypeNames.join( ' ' ) + ' connect' + \
                    moreToolbarItems()
            ]

The following settings support some of the buttons on the toolbar just
defined.  See
[here](https://www.tinymce.com/docs/configure/content-formatting/) for
documentation on how to edit this style data.

            fontsize_formats : '8pt 10pt 12pt 14pt 18pt 24pt 36pt'
            style_formats_merge : yes
            style_formats : [
                title: 'Grading'
                items: [
                    title : 'Red highlighter'
                    inline  : 'span'
                    styles :
                        'border-radius' : '5px'
                        padding : '2px 5px'
                        margin : '0 2px'
                        color : '#770000'
                        'background-color' : '#ffaaaa'
                ,
                    title : 'Yellow highlighter'
                    inline  : 'span'
                    styles :
                        'border-radius' : '5px'
                        padding : '2px 5px'
                        margin : '0 2px'
                        color : '#777700'
                        'background-color' : '#ffffaa'
                ,
                    title : 'Green highlighter'
                    inline  : 'span'
                    styles :
                        'border-radius' : '5px'
                        padding : '2px 5px'
                        margin : '0 2px'
                        color : '#007700'
                        'background-color' : '#aaffaa'
                ,
                    title : 'No highlighting'
                    inline : 'span'
                    exact : yes
                ]
            ]

We then customize the menus' contents as follows.

            menu :
                file :
                    title : 'File'
                    items : 'newfile openfile
                           | savefile saveas download upload
                           | managefiles | print' + moreMenuItems 'file'
                edit :
                    title : 'Edit'
                    items : 'undo redo
                           | cut copy paste pastetext
                           | selectall' + moreMenuItems 'edit'
                insert :
                    title : 'Insert'
                    items : 'link media
                           | template hr
                           | me' + moreMenuItems 'insert'
                view :
                    title : 'View'
                    items : 'visualaid hideshowgroups' \
                          + moreMenuItems 'view'
                format :
                    title : 'Format'
                    items : 'bold italic underline
                             strikethrough superscript subscript
                           | formats | removeformat' \
                           + moreMenuItems 'format'
                table :
                    title : 'Table'
                    items : 'inserttable tableprops deletetable
                           | cell row column' + moreMenuItems 'table'
                help :
                    title : 'Help'
                    items : 'about tour website' + moreMenuItems 'help'

Then we customize the context menu.

            contextmenu : 'link image inserttable
                | cell row column deletetable' + moreMenuItems 'contextmenu'

And finally, we include in the editor's initialization the data needed by
the Groups plugin, so that it can find it when that plugin is initialized.

            groupTypes : groupTypes

Each editor created will have the following `setup` function called on it.
In our case, there will be only one, but this is how TinyMCE installs setup
functions, regardless.

            setup : ( editor ) ->

See the [keyboard shortcuts workaround
file](keyboard-shortcuts-workaround.litcoffee) for an explanation of the
following line.

                keyboardShortcutsWorkaround editor

Add a Help menu.

                editor.addMenuItem 'about',
                    text : 'About...'
                    context : 'help'
                    onclick : -> editor.Dialogs.alert
                        title : 'webLurch'
                        message : helpAboutText ? ''
                editor.addMenuItem 'tour',
                    text : 'Take a tour'
                    context : 'help'
                    onclick : ->
                        findMenu = ( name ) ->
                            same = ( x, y ) ->
                                x.trim().toLowerCase() is \
                                y.trim().toLowerCase()
                            menuHeaders = document.getElementsByClassName \
                                'mce-menubtn'
                            for element in menuHeaders
                                if same element.textContent, name
                                    return element
                            null
                        findToolButton = ( name ) ->
                            document.getElementsByClassName(
                                "mce-i-#{name}" )[0]
                        tour = new Tour
                            storage : no
                            steps : [
                                element : findMenu 'edit'
                                title : 'Edit menu'
                                content : 'This tour is just an example for
                                     now.  Obviously you already knew where
                                     the edit menu was.'
                            ,
                                element : findToolButton 'table'
                                title : 'Table maker'
                                content : 'Yes, you can make tables, too!
                                    Okay, that\'s enough of a fake tour.
                                    We\'ll add a real tour to the
                                    application later.'
                            ]
                        tour.init()
                        tour.start()
                editor.addMenuItem 'website',
                    text : 'Documentation'
                    context : 'help'
                    onclick : -> window.open \
                        'http://nathancarter.github.io/weblurch', '_blank'

Add actions and toolbar buttons for all other menu items the client may have
defined.

                for own name, data of window.groupMenuItems
                    editor.addMenuItem name, data
                for own name, data of window.groupToolbarButtons
                    editor.addButton name, data

Install our DOM utilities in the TinyMCE's iframe's window instance.
Increase the default font size and maximize the editor to fill the page
by invoking the "mceFullScreen" command.

                editor.on 'init', ->
                    installDOMUtilitiesIn editor.getWin()
                    for own key, value of window.defaultEditorStyles
                        editor.getBody().style[key] = value
                    setTimeout ->
                        editor.execCommand 'mceFullScreen'
                    , 0

The third-party plugin for math equations requires the following stylesheet.

                    editor.dom.loadCSS './eqed/mathquill.css'

Add an icon to the left of the File menu, if one has been specified.

                    if window.menuBarIcon?.src?
                        filemenu = ( editor.getContainer()
                            .getElementsByClassName 'mce-menubtn' )[0]
                        icon = document.createElement 'img'
                        icon.setAttribute 'src', window.menuBarIcon.src
                        icon.style.width = window.menuBarIcon.width
                        icon.style.height = window.menuBarIcon.height
                        icon.style.padding = window.menuBarIcon.padding
                        filemenu.insertBefore icon, filemenu.childNodes[0]

Workaround for [this bug](http://www.tinymce.com/develop/bugtracker_view.php?id=3162):

                    editor.getBody().addEventListener 'focus', ->
                        if editor.windowManager.getWindows().length isnt 0
                            editor.windowManager.close()

Override the default handling of the tab key so that it does not leave the
editor, but instead inserts a large space ("em space").  In HTML, if we were
to insert a tab, it would be treated as any other whitespace, and look just
like a single, small space.  So we use this instead, the largest space in
HTML.

                    editor.on 'KeyDown', ( event ) ->
                        if event.keyCode is 9 # tab key
                            event.preventDefault()
                            editor.insertContent '&emsp;'

Ensure users do not accidentally navigate away from their unsaved changes.

                    window.addEventListener 'beforeunload', ( event ) ->
                        if editor.LoadSave.documentDirty
                            event.returnValue = 'You have unsaved changes.'
                            return event.returnValue

And if the app installed a global handler for editor post-setup, run that
function now.

                    window.afterEditorReady? editor

The following utility functions are used to help build lists of menu and
toolbar items in the setup data above.

    moreMenuItems = ( menuName ) ->
        names = if window.groupMenuItems.hasOwnProperty "#{menuName}_order"
            window.groupMenuItems["#{menuName}_order"]
        else
            ( k for k in Object.keys window.groupMenuItems \
                when window.groupMenuItems[k].context is menuName ).join ' '
        if names.length and names[...2] isnt '| ' then "| #{names}" else ''
    moreToolbarItems = ->
        names = ( window.groupToolbarButtons.order ? \
            Object.keys window.groupToolbarButtons ).join ' '
        if window.useGroupConnectionsUI then names = "connect #{names}"
        if names.length and names[...2] isnt '| ' then "| #{names}" else ''

## Support demo apps

We want to allow the demo applications in the webLurch source code
repository to place links on their Help menu to their documented source
code.  This will help people who want to learn Lurch coding find
resources to do so more easily.  We thus provide this function they can use
to do so as a one-line call.

Not only does it set up the link they request, but it also sets up a link to
the developer tutorial in general, and it flashes the Help menu briefly to
draw the viewer's attention there.

    window.addHelpMenuSourceCodeLink = ( path ) ->
        window.groupMenuItems ?= { }
        window.groupMenuItems.sourcecode =
            text : 'View documented source code'
            context : 'help'
            onclick : ->
                window.location.href = 'http://github.com/' + \
                    'nathancarter/weblurch/blob/master/' + path
        window.groupMenuItems.tutorial =
            text : 'View developer tutorial'
            context : 'help'
            onclick : ->
                window.location.href = 'http://github.com/' + \
                    'nathancarter/weblurch/blob/master/doc/tutorial.md'
        flash = ( count, delay, elts ) ->
            if count-- <= 0 then return
            elts.fadeOut( delay ).fadeIn delay, -> flash count, delay, elts
        setTimeout ->
            flash 3, 500, ( $ '.mce-menubtn' ).filter ( index, element ) ->
                element.textContent.trim() is 'Help'
        , 1000

The following tool is useful for debugging the undo/redo stack in a TinyMCE
editor instance.

    window.showUndoStack = ->
        manager = tinymce.activeEditor.undoManager
        console.log 'entry 0: document initial state'
        for index in [1...manager.data.length]
            previous = manager.data[index-1].content
            current = manager.data[index].content
            if previous is current
                console.log "entry #{index}: same as #{index-1}"
                continue
            initial = final = 0
            while previous[..initial] is current[..initial] then initial++
            while previous[previous.length-final..] is \
                  current[current.length-final..] then final++
            console.log "entry #{index}: at #{initial}:
                \n\torig: #{previous[initial..previous.length-final]}
                \n\tnow:  #{current[initial..current.length-final]}"
