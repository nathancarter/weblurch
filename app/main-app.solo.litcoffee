
# Main webLurch Application

## Overview

webLurch is first a word processor whose UI lets users group/bubble sections
of their document, with the intent that those sections can be handled
semantically.  Second, it is also a particular use of that foundation, for
checking students' proofs.

This file is the beginning of that main webLurch application, but it is not
yet complete.  The only complete implementation at present is [the desktop
version](http://lurchmath.org).

This file is loaded by [index.html](index.html), which is almost entirely
boilerplate code (as commented in its source), plus one line that imports
the compiled version of this file.

You can [see a live version of the resulting application online now](
http://nathancarter.github.io/weblurch/app/index.html).

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
        imageHTML : '<font color="#996666">[]</font>'
        openImageHTML : '<font color="#996666">[</font>'
        closeImageHTML : '<font color="#996666">]</font>'
        tooltip : 'Make text a meaningful expression'
        color : '#996666'
    ]

Use the MediaWiki and Settings plugins.

    window.pluginsToLoad = [ 'mediawiki', 'settings' ]

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
            metadata : { }
            document : html
    window.groupMenuItems =
        wikiimport :
            text : 'Import from wiki...'
            context : 'file'
            onclick : ->
                pageName = prompt 'Give the name of the page to import (case
                    sensitive)', 'Main Page'
                if pageName is null then return
                tinymce.activeEditor.MediaWiki.getPageContent pageName,
                    ( content, error ) ->
                        if error
                            alert 'Error loading content from wiki:' + \
                                error.split( '\n' )[0]
                            console.log error
                        else
                            { metadata, document } = extractMetadata content
                            tinymce.activeEditor.setContent document
                            tinymce.activeEditor.Settings.document \
                                .metadata = metadata
        wikiexport :
            text : 'Export to wiki'
            context : 'file'
            onclick : ->
                pageName = tinymce.activeEditor.Settings.document.get \
                    'wiki_title'
                if not pageName? then return alert 'You have not yet set the
                    title under which this document should be published on
                    the wiki.  See the document settings on the File menu.'
                username = tinymce.activeEditor.Settings.application.get \
                    'wiki_username'
                password = tinymce.activeEditor.Settings.application.get \
                    'wiki_password'
                if not username? or not password? then return alert 'You
                    have not yet set up a wiki username and password.  See
                    the application settings on the File menu.'
                postCallback = ( result, error ) ->
                    if error then return alert 'Posting error:\n' + error
                    if confirm 'Posting succeeded.  Visit new page?'
                        window.open '/wiki/index.php?title=' + \
                            encodeURIComponent( pageName ), '_blank'
                loginCallback = ( result, error ) ->
                    if error then return alert 'Login error:\n' + error
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
            text : 'Document properties...'
            context : 'file'
            onclick : -> tinymce.activeEditor.Settings.document.showUI()

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
                    'wiki_username', A.get 'wiki_username'
                editor.Settings.UI.password 'Password',
                    'wiki_password', A.get 'wiki_password'
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
                    'wiki_title', D.get 'wiki_title'
            ].join '\n'
        D.teardown = ( div ) ->
            elt = ( id ) -> div.ownerDocument.getElementById id
            D.set 'wiki_title', elt( 'wiki_title' ).value

Set up the load/save plugin with the functions needed for loading and saving
document metadata.

        editor.LoadSave.saveMetaData = -> D.metadata
        editor.LoadSave.loadMetaData = ( object ) -> D.metadata = object

If the query string told us to load a page from the wiki, do so.

        editor.MediaWiki.setIndexPage '/wiki/index.php'
        editor.MediaWiki.setAPIPage '/wiki/api.php'
        if match = /\?wikipage=(.*)/.exec window.location.search
            editor.MediaWiki.importPage decodeURIComponent match[1]
