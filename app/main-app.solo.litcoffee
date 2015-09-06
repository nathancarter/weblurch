
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

Application name, to appear in page title:

    setAppName 'Lurch'

Icon that appears to the left of the File menu:

    window.menuBarIcon =
        src : 'icons/apple-touch-icon-76x76.png'
        width : '26px'
        height : '26px'
        padding : '2px'

Group types needed by this application (just one for now, more later as this
application becomes mature):

    window.groupTypes = [
        name : 'me'
        text : 'Meaningful expression'
        imageHTML : '<font color="#996666">[]</font>'
        openImageHTML : '<font color="#996666">[</font>'
        closeImageHTML : '<font color="#996666">]</font>'
        tooltip : 'Make text a meaningful expression'
        color : '#996666'
    ]

Use the MediaWiki plugin:

    window.pluginsToLoad = [ 'mediawiki' ]

Add initial functionality for importing from a wiki on the same server, and
exporting to it as well.  This is still in development.

    formatContentForWiki = ( editorHTML ) ->
        imgRE = /<img(\s+[^>]*)>/i;
        while match = imgRE.exec editorHTML
            editorHTML = editorHTML[...match.index] + \
                "<htmltag tagname='img' #{match[1]}>" + \
                editorHTML[match.index+match[0].length..]
        editorHTML
    formatContentFromWiki = ( wikiHTML ) ->
        tagRE = /<htmltag\s+tagname='([^']+)'\s+([^>]*)>/i;
        while match = tagRE.exec wikiHTML
            wikiHTML = wikiHTML[...match.index] + \
                "<#{match[1]} #{match[2]}>" + \
                wikiHTML[match.index+match[0].length..]
        wikiHTML
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
                        if content
                            tinymce.activeEditor.setContent \
                                formatContentFromWiki content
                        if error
                            alert 'Error loading content from wiki:' + \
                                error.split( '\n' )[0]
                            console.log error
        wikiexport :
            text : 'Export to wiki...'
            context : 'file'
            onclick : ->
                content = formatContentForWiki \
                    tinymce.activeEditor.getContent()
                pageName = prompt 'Give the name of the wiki page into which
                    you want this document exported (case sensitive)',
                    'My New Page'
                if pageName is null then return
                username = prompt 'Enter your wiki username', 'username'
                if username is null then return
                password = prompt 'Enter your wiki password.\n(Note that
                    this *test* implementation will show your password on
                    screen.  Sorry!)', 'password'
                if password is null then return
                postCallback = ( result, error ) ->
                    if error then return alert 'Posting error:\n' + error
                    if confirm 'Posting succeeded.  Visit new page?'
                        window.open '/wiki/index.php?title=' + \
                            encodeURIComponent( pageName ), '_blank'
                loginCallback = ( result, error ) ->
                    if error then return alert 'Login error:\n' + error
                    tinymce.activeEditor.MediaWiki.exportPage pageName,
                        content, postCallback
                tinymce.activeEditor.MediaWiki.login username, password,
                    loginCallback

If the query string told us to load a page from the wiki, do so now.

    window.afterEditorReady = ( editor ) ->
        editor.MediaWiki.setIndexPage '/wiki/index.php'
        editor.MediaWiki.setAPIPage '/wiki/api.php'
        if match = /\?wikipage=(.*)/.exec window.location.search
            editor.MediaWiki.importPage decodeURIComponent match[1]
