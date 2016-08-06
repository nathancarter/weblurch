
# Main webLurch Application

## Modular organization

This file is one of several files that make up the main webLurch
Application.  For more information on the app and the other files, see
[the first source code file in this set](main-app-basics-solo.litcoffee).

## Importing and exporting documents

Add menu items for importing from a wiki on the same server, and exporting
to it as well:

    window.groupMenuItems.wikiimport =
        text : 'Import from wiki...'
        context : 'file'
        onclick : ->
            if appIsRunningOnGitHub() then return
            pageName = prompt 'Give the name of the page to import (case
                sensitive)', 'Main Page'
            if pageName is null then return
            tinymce.activeEditor.MediaWiki.importPage pageName,
                ( document, metadata ) ->
                    if metadata?
                        tinymce.activeEditor.Settings.document.metadata =
                            metadata
    window.groupMenuItems.wikiexport =
        text : 'Export to wiki'
        context : 'file'
        onclick : ->
            if appIsRunningOnGitHub() then return
            pageName = tinymce.activeEditor.Settings.document.get \
                'wiki_title'
            if not pageName?
                tinymce.activeEditor.Dialogs.alert
                    title : 'Page Title not set'
                    message : '<p>You have not yet set the title under
                        which this document should be published on the wiki.
                        See the document settings on the File menu.</p>'
                return
            username = tinymce.activeEditor.Settings.application.get \
                'wiki_username'
            password = tinymce.activeEditor.Settings.application.get \
                'wiki_password'
            if not username? or not password?
                tinymce.activeEditor.Dialogs.alert
                    title : 'No Wiki Credentials'
                    message : '<p>You have not given your wiki username
                        and password to the application settings.  See the
                        application settings on the File menu.</p>'
                return
            postCallback = ( result, error ) ->
                if error
                    tinymce.activeEditor.Dialogs.alert
                        title : 'Posting Error'
                        message : "<p>Error when posting to the wiki:</p>
                            <p>#{error}</p>"
                    return
                match = /^[^/]+\/\/[^/]+\//.exec window.location.href
                url = window.location.href[...match[0].length] + \
                    'wiki/index.php?title=' + encodeURIComponent pageName
                tinymce.activeEditor.Dialogs.alert
                    title : 'Document Posted'
                    message : "<p>Posting succeeded.</p>
                        <p><a href='#{url}' target='_blank'>Visit posted
                        page.</a></p>"
            loginCallback = ( result, error ) ->
                if error
                    tinymce.activeEditor.Dialogs.alert
                        title : 'Wiki Login Error'
                        message : "<p>Error when logging into the wiki:</p>
                            <p>#{error}</p>"
                    return
                content = tinymce.activeEditor.MediaWiki.embedMetadata \
                    tinymce.activeEditor.getContent(),
                    tinymce.activeEditor.Settings.document.metadata
                tinymce.activeEditor.MediaWiki.exportPage pageName,
                    content, postCallback
            tinymce.activeEditor.MediaWiki.login username, password,
                loginCallback

Now, a few actions to take after the editor has been initialized.

If the query string told us to load a page from the wiki, or a page fully
embedded in a (possibly enormous) URL, do so.  Note that the way we handle
the enormous URLs is by storing them in the browser's `localStorage`, then
reloading the page without the query string, and then pulling the data from
`localStorage`.

    window.afterEditorReadyArray.push ( editor ) ->
        editor.MediaWiki.setIndexPage '/wiki/index.php'
        editor.MediaWiki.setAPIPage '/wiki/api.php'
        if match = /\?wikipage=(.*)/.exec window.location.search
            editor.MediaWiki.importPage decodeURIComponent match[1],
                ( document, metadata ) ->
                    if metadata? then editor.LoadSave.loadMetaData metadata
        if toAutoLoad = localStorage.getItem 'auto-load'
            try
                [ metadata, document ] = JSON.parse toAutoLoad
                setTimeout ->
                    localStorage.removeItem 'auto-load'
                    tinymce.activeEditor.setContent document
                    editor.LoadSave.loadMetaData metadata
                , 100
        if match = /\?document=(.*)/.exec window.location.search
            html = decodeURIComponent match[1]
            { metadata, document } = extractMetadata html
            localStorage.setItem 'auto-load',
                JSON.stringify [ metadata, document ]
            window.location.href = window.location.href.split( '?' )[0]

The following function is just to ensure that functionality that depends on
a wiki installation doesn't break when the app is served from GitHub.
Instead of breaking, the app will clearly state that...well, you can read
the message below for yourself.

    appIsRunningOnGitHub = ->
        result = /nathancarter\.github\.io/.test window.location.href
        if result
            tinymce.activeEditor.Dialogs.alert
                title : 'Not Available Here'
                message : '<p>That functionality requires MediaWiki to be
                    running on the server from which you\'re accessing this
                    web app.</p>
                    <p>On GitHub, we cannot run a MediaWiki server, so the
                    functionality is disabled.</p>
                    <p>The menu items remain for use in developer testing,
                    as we prepare for a dedicated server that will have
                    MediaWiki and the ability to publish documents to that
                    wiki with a single click, or edit them in Lurch with a
                    single click.</p>
                    <p>Try back soon!</p>'
        result
