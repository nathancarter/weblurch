
# Main webLurch Application

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

Install the icon that appears to the left of the File menu.

    window.menuBarIcon =
        src : 'icons/apple-touch-icon-76x76.png'
        width : '26px'
        height : '26px'
        padding : '2px'

This application needs just one group type for now, but it will need more
later as this application becomes mature.

    window.groupTypes = [
        name : 'me'
        text : 'Meaningful expression'
        imageHTML : '<font color="#996666">[ ]</font>'
        openImageHTML : '<font color="#996666">[</font>'
        closeImageHTML : '<font color="#996666">]</font>'
        tooltip : 'Make text a meaningful expression'
        color : '#996666'
        connectionRequest : ( from, to ) ->
            existingTags = ( "#{c[2]}" for c in from.connectionsOut() \
                when c[1] is to.id() )
            i = 0
            while "#{i}" in existingTags then i++
            from.connect to, "#{i}"
    ]

Install the arrows UI for that group.

    window.useGroupConnectionsUI = yes

Use the MediaWiki, Settings, and Dialogs plugins.

    window.pluginsToLoad = [ 'mediawiki', 'settings', 'dialogs' ]

Add initial functionality for importing from a wiki on the same server, and
exporting to it as well.  This is still in development.

    embedMetadata = ( documentHTML, metadataObject = { } ) ->
        encoding = encodeURIComponent JSON.stringify metadataObject
        "<span id='metadata' style='display: none;'
         >#{encoding}</span>#{documentHTML}"
    extractMetadata = ( html ) ->
        re = /^<span[^>]+id=.metadata.[^>]*>([^<]*)<\/span>/
        if match = re.exec html
            metadata : JSON.parse decodeURIComponent match[1]
            document : html[match[0].length..]
        else
            metadata : null
            document : html
    window.groupMenuItems =
        file_order : 'sharelink wikiimport wikiexport
                    | appsettings docsettings'
        sharelink :
            text : 'Share document...'
            context : 'file'
            onclick : ->
                page = window.location.href.split( '?' )[0]
                url = page + '?document=' + \
                    encodeURIComponent tinymce.activeEditor.getContent()
                showURL = ( url ) ->
                    embed = "<iframe src='#{url}' width=800
                        height=600></iframe>"
                        .replace /&/g, '&amp;'
                        .replace /'/g, '&apos;'
                        .replace /"/g, '&quot;'
                        .replace /</g, '&lt;'
                        .replace />/g, '&gt;'
                    console.log embed
                    tinymce.activeEditor.Dialogs.alert
                        title : 'Permanent Sharing Links'
                        message : "
                            <h3>Sharing URL</h3>
                            <p>Copy this URL to your clipboard, and
                            paste wherever you like, such as email.</p>
                            <input type='text' size=50 id='firstURL'
                             value='#{url}'/>
                            <h3>Embedding HTML</h3>
                            <p>Copy this HTML to your clipboard, and paste
                            into any webpage or blog to embed a Lurch
                            instance with this document in it.</p>
                            <input type='text' size=50 value='#{embed}'/>
                            <script>
                            var all = document.getElementsByTagName(
                                'input' );
                            for ( var i = 0 ; i < all.length ; i++ ) {
                                all[i].addEventListener( 'focus',
                                    function ( event ) {
                                        var t = event.target;
                                        if ( t.select ) t.select();
                                        else t.setSelectionRange(
                                            0, t.value.length );
                                    } );
                            }
                            document.getElementById( 'firstURL' ).focus();
                            </script>"
                request = gapi?.client?.urlshortener?.url?.insert? \
                    resource : longUrl : url
                if not request? then return showURL url
                request.execute ( response ) ->
                    if response.id?
                        showURL response.id
                    else
                        showURL url
        wikiimport :
            text : 'Import from wiki...'
            context : 'file'
            onclick : ->
                if appIsRunningOnGitHub() then return
                pageName = prompt 'Give the name of the page to import (case
                    sensitive)', 'Main Page'
                if pageName is null then return
                tinymce.activeEditor.MediaWiki.getPageContent pageName,
                    ( content, error ) ->
                        if error
                            tinymce.activeEditor.Dialogs.alert
                                title : 'Wiki Error'
                                message : "<p>Error loading content from
                                    wiki:</p>
                                    <p>#{error.split( '\n' )[0]}</p>"
                            console.log error
                            return
                        { metadata, document } = extractMetadata content
                        if not metadata?
                            tinymce.activeEditor.Dialogs.alert
                                title : 'Not a Lurch document'
                                message : '<p><b>The wiki page that you
                                    attempted to import is not a Lurch
                                    document.</b></p>
                                    <p>Although it is possible to import any
                                    wiki page into Lurch, it does not work
                                    well to edit and re-post such pages to
                                    the wiki.</p>
                                    <p>To edit a non-Lurch wiki page, visit
                                    the page on the wiki and edit it
                                    there.</p>'
                            return
                        tinymce.activeEditor.setContent document
                        tinymce.activeEditor.Settings.document \
                            .metadata = metadata
        wikiexport :
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
                            which this document should be published on the
                            wiki.  See the document settings on the File
                            menu.</p>'
                    return
                username = tinymce.activeEditor.Settings.application.get \
                    'wiki_username'
                password = tinymce.activeEditor.Settings.application.get \
                    'wiki_password'
                if not username? or not password?
                    tinymce.activeEditor.Dialogs.alert
                        title : 'No Wiki Credentials'
                        message : '<p>You have not given your wiki username
                            and password to the application settings.  See
                            the application settings on the File menu.</p>'
                    return
                postCallback = ( result, error ) ->
                    if error
                        tinymce.activeEditor.Dialogs.alert
                            title : 'Posting Error'
                            message : "<p>Error when posting to the
                                wiki:</p>
                                <p>#{error}</p>"
                        return
                    match = /^[^/]+\/\/[^/]+\//.exec window.location.href
                    url = window.location.href[...match[0].length] + \
                        'wiki/index.php?title=' + \
                        encodeURIComponent pageName
                    tinymce.activeEditor.Dialogs.alert
                        title : 'Document Posted'
                        message : "<p>Posting succeeded.</p>
                            <p><a href='#{url}' target='_blank'>Visit posted
                            page.</a></p>"
                loginCallback = ( result, error ) ->
                    if error
                        tinymce.activeEditor.Dialogs.alert
                            title : 'Wiki Login Error'
                            message : "<p>Error when logging into the
                                wiki:</p>
                                <p>#{error}</p>"
                        return
                    content = tinymce.activeEditor.getContent()
                    content = embedMetadata content,
                        tinymce.activeEditor.Settings.document.metadata
                    tinymce.activeEditor.MediaWiki.exportPage pageName,
                        content, postCallback
                tinymce.activeEditor.MediaWiki.login username, password,
                    loginCallback
        appsettings :
            text : 'Application settings...'
            context : 'file'
            onclick : -> tinymce.activeEditor.Settings.application.showUI()
        docsettings :
            text : 'Document settings...'
            context : 'file'
            onclick : -> tinymce.activeEditor.Settings.document.showUI()

Set up Google API key for URL shortening.

    window.addEventListener 'load', ->
        gapi?.client?.setApiKey 'AIzaSyAf7F0I39DdI2jtD7zrPUa4eQvUXZ-K6W8'
        gapi?.client?.load 'urlshortener', 'v1', ->
    , no

Lastly, a few actions to take after the editor has been initialized.

    window.afterEditorReady = ( editor ) ->

Initialize the settings plugin for global app settings.

        A = editor.Settings.addCategory 'application'
        A.setup = ( div ) ->
            div.innerHTML = [
                editor.Settings.UI.heading 'Wiki Login'
                editor.Settings.UI.info 'Entering a username and password
                    here does NOT create an account on the wiki.  You must
                    already have one.  If you do not, first visit
                    <a href="/wiki/index.php" target="_blank"
                       style="color: blue;">the wiki</a>,
                    create an account, then return here.'
                editor.Settings.UI.text 'Username',
                    'wiki_username', A.get( 'wiki_username' ) ? ''
                editor.Settings.UI.password 'Password',
                    'wiki_password', A.get( 'wiki_password' ) ? ''
            ].join '\n'
        A.teardown = ( div ) ->
            elt = ( id ) -> div.ownerDocument.getElementById id
            A.set 'wiki_username', elt( 'wiki_username' ).value
            A.set 'wiki_password', elt( 'wiki_password' ).value

Initialize the settings plugin for per-document settings, stored in that
same metadata object.

        D = editor.Settings.addCategory 'document'
        D.metadata = { }
        D.get = ( key ) -> D.metadata[key]
        D.set = ( key, value ) -> D.metadata[key] = value
        D.setup = ( div ) ->
            div.innerHTML = [
                editor.Settings.UI.heading 'Wiki Publishing'
                editor.Settings.UI.text 'Publish to wiki under this title',
                    'wiki_title', D.get( 'wiki_title' ) ? ''
            ].join '\n'
        D.teardown = ( div ) ->
            elt = ( id ) -> div.ownerDocument.getElementById id
            D.set 'wiki_title', elt( 'wiki_title' ).value

Set up the load/save plugin with the functions needed for loading and saving
document metadata.

        editor.LoadSave.saveMetaData = -> D.metadata
        editor.LoadSave.loadMetaData = ( object ) -> D.metadata = object

If the query string told us to load a page from the wiki, or a page fully
embedded in a (possibly enormous) URL, do so.  Note that the way we handle
the enormous URLs is by storing them in the browser's `localStorage`, then
reloading the page without the query string, and then pulling the data from
`localStorage`.

        editor.MediaWiki.setIndexPage '/wiki/index.php'
        editor.MediaWiki.setAPIPage '/wiki/api.php'
        if match = /\?wikipage=(.*)/.exec window.location.search
            editor.MediaWiki.importPage decodeURIComponent match[1]
        if toAutoLoad = localStorage.getItem 'auto-load'
            setTimeout ->
                localStorage.removeItem 'auto-load'
                tinymce.activeEditor.setContent toAutoLoad
            , 100
        if match = /\?document=(.*)/.exec window.location.search
            localStorage.setItem 'auto-load', decodeURIComponent match[1]
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
