
# Sidebar Example webLurch Application

## Overview

To know what's going on here, you should first have read the documenation
for [the simple example application](simple-example-solo.litcoffee) and then
for [the complex example application](complex-example-solo.litcoffee).
This application is more useful than either of those.

[A live version of this app is online here.](
http://nathancarter.github.io/weblurch/app/sidebar-example.html)

Set the app name with the same function we used in the simple example app.

    setAppName 'SidebarApp'

Add a source code link to the help menu, as in the simple example app.

    addHelpMenuSourceCodeLink 'app/sidebar-example-solo.litcoffee'

We also change the Help/About menu item to be specific to this demo app.

    window.helpAboutText =
        '<p>See the fully documented <a target="top"
        href="https://github.com/nathancarter/weblurch/blob/master/app/sidebar-example-solo.litcoffee"
        >source code for this demo app</a>.</p>'

## Sidebar

Now we set up the sidebar using a jQuery Splitter.

    window.fullScreenEditor = no
    window.editorContainer = -> document.getElementById 'editorContainer'
    window.afterEditorReady = ( editor ) ->
        mainContainer = window.editorContainer.parentNode
        splitter = ( $ mainContainer ).split
            orientation : 'vertical'
            limit : 100
            position : '75%'
            # onDrag : ( event ) -> console.log splitter.position()
        for i in [1..100]
            document.getElementById( 'sidebar' ).innerHTML += 'lorem ipsum '
        do handleResize = ->
            editorContainer = editor.getContainer()
            iframe = editor.getContentAreaContainer().firstChild
            vp = tinymce.DOM.getViewPort()
            iframe.style.width = iframe.style.height =
                mainContainer.style.height = '100%'
            editorContainer.style.width = editorContainer.style.height = ''
            iframe.style.height = mainContainer.clientHeight \
                - ( editorContainer.clientHeight - iframe.clientHeight )
            window.scrollTo vp.x, vp.y
        ( $ window ).resize handleResize

## Other

Other code will later be put here to define group types.  For now, we're
experimenting with something else.
