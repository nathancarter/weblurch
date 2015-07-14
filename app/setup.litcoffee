
# App Setup Script

## Specify app settings

First, specify that the app's name is "Lurch," so that will be used when
creating the title for this page (e.g., to show up in the tab in Chrome).

    setAppName 'Lurch'

Second, we initialize a very simple default configuration for the Groups
plugin.  It can be overridden by having any script assign to the global
variable `groupTypes`, overwriting this data.  Such a change must be done
before the page is fully loaded, when the `tinymce.init` call, below, takes
place.

    window.groupTypes ?= [
        name : 'me'
        text : 'Meaningful expression'
        image : './images/red-bracket-icon.png'
        tooltip : 'Make text a meaningful expression'
        color : '#996666'
    ]

Clients who define their own group types may also define their own toolbar
buttons and menu items to go with them.  But these lists default to empty.

    window.groupToolbarButtons ?= { }
    window.groupMenuItems ?= { }

We also specify an icon to appear on the menu bar, at the very left.  This
can be overridden, in the same way as `window.groupTypes`, above.

    window.menuBarIcon ?=
        src : 'icons/apple-touch-icon-76x76.png'
        width : '26px'
        height : '26px'
        padding : '2px'

We also provide a set of styles to be added to the editor by default.
Clients can also override this object if they wish different styles.

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
        document.body.appendChild editor

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

These enable the use of the browser's built-in spell-checking facilities, so
that no server-side callback needs to be done for spellchecking.

            browser_spellcheck : yes
            gecko_spellcheck : yes
            statusbar : no
            paste_data_images : true

Not all of the following plugins are working yet, but most are.  A plugin
that begins with a hyphen is a local plugin written as part of this project.

            plugins : 'advlist table charmap colorpicker image link
                importcss paste print save searchreplace textcolor
                fullscreen -loadsave -overlay -groups -equationeditor'

The groups plugin requires that we add the following, to prevent resizing of
group boundary images.

            object_resizing : ':not(img.grouper)'

We then install two toolbars, with separators indicated by pipes (`|`).

            toolbar : [
                'newfile openfile savefile managefiles | print
                    | undo redo | cut copy paste
                    | alignleft aligncenter alignright alignjustify
                    | bullist numlist outdent indent blockquote | table'
                'fontselect styleselect | bold italic underline
                    textcolor subscript superscript removeformat
                    | link unlink | charmap image
                    | spellchecker searchreplace | equationeditor | ' + \
                    groupTypeNames.join( ' ' ) + ' | ' + \
                    Object.keys( window.groupToolbarButtons ).join ' '
            ]

We then customize the menus' contents as follows.

            menu :
                file :
                    title : 'File'
                    items : 'newfile openfile | savefile saveas
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
                    items : 'about website' + moreMenuItems 'help'

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

Add a Help menu.

                editor.addMenuItem 'about',
                    text : 'About...'
                    context : 'help'
                    onclick : -> alert 'webLurch\n\npre-alpha,
                        not yet intended for general consumption!'
                editor.addMenuItem 'website',
                    text : 'Lurch website'
                    context : 'help'
                    onclick : -> window.open 'http://www.lurchmath.org',
                        '_blank'

Add actions and toolbar buttons for all other menu items the client may have
defined.

                for own name, data of window.groupMenuItems
                    editor.addMenuItem name, data
                for own name, data of window.groupToolbarButtons
                    editor.addButton name, data

Install our DOM utilities in the TinyMCE's iframe's window instance.
Increase the default font size and maximize the editor to fill the page.
This requires not only invoking the "mceFullScreen" command, but also then
setting the height properties of many pieces of the DOM hierarchy (in a way
that seems like it ought to be handled for us by the fullScreen plugin).

                editor.on 'init', ->
                    installDOMUtilitiesIn editor.getWin()
                    for own key, value of window.defaultEditorStyles
                        editor.getBody().style[key] = value
                    setTimeout ->
                        editor.execCommand 'mceFullScreen'
                        walk = editor.iframeElement
                        while walk and walk isnt editor.container
                            if walk is editor.iframeElement.parentNode
                                walk.style.height = 'auto'
                            else
                                walk.style.height = '100%'
                            walk = walk.parentNode
                        for h in editor.getDoc().getElementsByTagName 'html'
                            h.style.height = 'auto'
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

The following utility function was used to help build lists of menu items
in the setup data above.

    moreMenuItems = ( menuName ) ->
        names = ( k for k in Object.keys window.groupMenuItems \
            when window.groupMenuItems[k].context is menuName ).join ' '
        if names.length then "| #{names}" else ''

The third-party plugin for math equations can have its rough meaning
extracted by the following function, which can be applied to any DOM element
that has the style "mathquill-rendered-math."  For instance, the expression
$x^2+5$ in MathQuill would become `["x","sup","2","+","5"]` as returned by
this function, similar to the result of a tokenizer, ready for a parser.

    window.mathQuillToMeaning = ( node ) ->
        if node instanceof Text then return node.textContent
        result = [ ]
        for child in node.childNodes
            if ( $ child ).hasClass( 'selectable' ) or \
               ( $ child ).hasClass( 'cursor' ) or \
               /width:0/.test child.getAttribute? 'style'
                continue
            result = result.concat mathQuillToMeaning child
        if node.tagName in [ 'SUP', 'SUB' ]
            name = node.tagName.toLowerCase()
            if ( $ node ).hasClass 'nthroot' then name = 'nthroot'
            if result.length > 1
                result.unshift '('
                result.push ')'
            result.unshift name
        for marker in [ 'fraction', 'overline', 'overarc' ]
            if ( $ node ).hasClass marker
                if result.length > 1
                    result.unshift '('
                    result.push ')'
                result.unshift marker
        for marker in [ 'numerator', 'denominator' ]
            if ( $ node ).hasClass marker
                if result.length > 1
                    result.unshift '('
                    result.push ')'
        if result.length is 1 then result[0] else result
