
# Add an editor to the app

First, specify that the app's name is "Lurch," so that will be used when
creating the title for this page (e.g., to show up in the tab in Chrome).

    setAppName 'Lurch'

This file initializes a [TinyMCE](http://www.tinymce.com/) editor inside the
[main app page](index.html).  It is designed to be used inside that page,
where [jQuery](http://jquery.com/) has already been loaded, thus defining
the `$` symbol used below.  It use in this context causes the function to be
run only after the DOM has been fully loaded.

    $ ->

Create a `<textarea>` to be used as the editor.

        editor = document.createElement 'textarea'
        editor.setAttribute 'id', 'editor'
        document.body.appendChild editor

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

Not all of the following plugins are working yet, but most are.  A plugin
that begins with a hyphen is a local plugin written as part of this project.

            plugins : 'advlist table charmap colorpicker contextmenu image
                link importcss paste print save searchreplace textcolor
                fullscreen -loadsave -overlay -groups'

We then install two toolbars, with separators indicated by pipes (`|`).

            toolbar : [
                'newfile openfile savefile managefiles | print
                    | undo redo | cut copy paste
                    | alignleft aligncenter alignright alignjustify
                    | bullist numlist outdent indent blockquote | table'
                'fontselect styleselect | bold italic underline
                    textcolor subscript superscript removeformat
                    | link unlink | charmap image
                    | spellchecker searchreplace'
            ]

We then customize the menus' contents as follows.

            menu :
                file :
                    title : 'File'
                    items : 'newfile openfile | savefile saveas
                           | managefiles | print'
                edit :
                    title : 'Edit'
                    items : 'undo redo
                           | cut copy paste pastetext
                           | selectall'
                insert :
                    title : 'Insert'
                    items : 'link media
                           | template hr'
                view :
                    title : 'View'
                    items : 'visualaid'
                format :
                    title : 'Format'
                    items : 'bold italic underline
                             strikethrough superscript subscript
                           | formats | removeformat'
                table :
                    title : 'Table'
                    items : 'inserttable tableprops deletetable
                           | cell row column'
                help :
                    title : 'Help'
                    items : 'about website'

And, finally, we customize the context menu.

            contextmenu : 'link image inserttable
                | cell row column deletetable'

Each editor created will have the following `setup` function called on it.
In our case, there will be only one, but this is how TinyMCE installs setup
functions, regardless.

            setup : ( editor ) ->

Add a Help menu.

                editor.addMenuItem 'about',
                    text : 'About...'
                    context : 'help'
                    onclick : -> alert 'webLurch\n\npre-alpha,
                        not intended for general consumption!'
                editor.addMenuItem 'website',
                    text : 'Lurch website'
                    context : 'help'
                    onclick : -> window.open 'http://www.lurchmath.org',
                        '_blank'

Increase the default font size and maximize the editor to fill the page.

                editor.on 'init', ->
                    editor.getBody().style.fontSize = '16px'
                    setTimeout ( -> editor.execCommand 'mceFullScreen' ), 0

Add Lurch icon to the left of the File menu.

                    filemenu = ( editor.getContainer()
                        .getElementsByClassName 'mce-menubtn' )[0]
                    icon = document.createElement 'img'
                    icon.setAttribute 'src',
                        'icons/apple-touch-icon-76x76.png'
                    icon.style.width = icon.style.height = '26px'
                    icon.style.padding = '2px'
                    filemenu.insertBefore icon, filemenu.childNodes[0]

Workaround for [this bug](http://www.tinymce.com/develop/bugtracker_view.php?id=3162):

                    editor.getBody().addEventListener 'focus', ->
                        if editor.windowManager.getWindows().length isnt 0
                            editor.windowManager.close()
