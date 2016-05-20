
# MediaWiki Integration

[MediaWiki](https://www.mediawiki.org/wiki/MediaWiki) is the software that
powers [Wikipedia](wikipedia.org).  We plan to integrate webLurch with a
MediaWiki instance by adding features that let the software load pages from
the wiki into webLurch for editing, and easily post changes back to the
wiki as well.  This plugin implements that two-way communication.

This first version is a start, and does not yet implement full
functionality.

## Global variable

We store the editor into which we're installed in this global variable, so
that we can access it easily later.  We initialize it to null here.

    editor = null

## Setup

Before you do anything else with this plugin, you must specify the URLs for
the wiki's main page (usually index.php) and API page (usually api.php).
Do so with the following functions.

    setIndexPage = ( URL ) -> editor.indexURL = URL
    getIndexPage = -> editor.indexURL
    setAPIPage = ( URL ) -> editor.APIURL = URL
    getAPIPage = -> editor.APIURL

## Embedding metadata

Here are two functions for embedding metadata into/extracting metadata from
the HTML content of a document.  These are useful before export to/after
import from the wiki.

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

## Extracting wiki pages

The following (necessarily asynchronous) function accesses the wiki, fetches
the content for the page with the given name, and sends it to the given
callback.  The callback takes two parameters, the content and an error.
Only one will be non-null, depending on the success or failure of the
process.

This internal function therefore does the grunt work.  It can fetch any data
about a wiki page using the `rvprop` parameter of [the MediaWiki Revisions
API](https://www.mediawiki.org/wiki/API:Revisions).  Two convenience
functions for common use cases follow.

    getPageData = ( pageName, rvprop, callback ) ->
        xhr = new XMLHttpRequest()
        xhr.addEventListener 'load', ->
            json = @responseText
            try
                object = JSON.parse json
            catch e
                callback null,
                    'Invalid response format.\nShould be JSON:\n' + json
                return
            try
                content = object.query.pages[0].revisions[0][rvprop]
            catch e
                callback null, 'No such page on wiki.\nRaw reply:\n' + json
                return
            callback content, null
        xhr.open 'GET',
            editor.MediaWiki.getAPIPage() + '?action=query&titles=' + \
            encodeURIComponent( pageName ) + \
            '&prop=revisions' + \
            '&rvprop=' + rvprop + '&rvparse' + \
            '&format=json&formatversion=2'
        xhr.setRequestHeader 'Api-User-Agent', 'webLurch application'
        xhr.send()

Inserting the response data from this function into the editor happens in
the function after this one.

    getPageContent = ( pageName, callback ) ->
        getPageData pageName, 'content', callback

This function is very similar to `getPageContent`, but gets the last
modified date of the page instead of its content.

    getPageTimestamp = ( pageName, callback ) ->
        getPageData pageName, 'timestamp', callback

The following function wraps `getPageContent` in a simple UI, which either
inserts the fetched content into the editor on success, or pops up an error
information dialog on failure.  An optional callback will be called with
true or false, indicating success or failure.

    importPage = ( pageName, callback ) ->
        editor.MediaWiki.getPageContent pageName, ( content, error ) ->
            if error
                editor.Dialogs.alert
                    title : 'Wiki Error'
                    message : "<p>Error loading content from wiki:</p>
                        <p>#{error.split( '\n' )[0]}</p>"
                console.log error
                callback? false # failure
            { metadata, document } = extractMetadata content
            if not metadata?
                editor.Dialogs.alert
                    title : 'Not a Lurch document'
                    message : '<p><b>The wiki page that you attempted to
                        import is not a Lurch document.</b></p>
                        <p>Although it is possible to import any wiki page
                        into Lurch, it does not work well to edit and
                        re-post such pages to the wiki.</p>
                        <p>To edit a non-Lurch wiki page, visit the page on
                        the wiki and edit it there.</p>'
                callback? false # failure
            editor.setContent document
            callback? document, metadata # success

A variant of the previous function silently attempts to fetch just the
metadata from a document stored in the wiki.  It calls the callback with
null on any failure, and the metadata as JSON on success.

    getPageMetadata = ( pageName, callback ) ->
        editor.MediaWiki.getPageContent pageName, ( content, error ) ->
            callback? if error then null else \
                extractMetadata( content ).metadata

The following function accesses the wiki, logs in using the given username
and password, and sends the results to the given callback.  The "token"
parameter is for recursive calls only, and should not be provided by
clients.  The callback accepts result and error parameters.  The result will
either be true, in which case login succeeded, or null, in which case the
error parameter will contain the error message as a string.

    login = ( username, password, callback, token ) ->
        xhr = new XMLHttpRequest()
        xhr.addEventListener 'load', ->
            json = @responseText
            try
                object = JSON.parse json
            catch e
                callback null, 'Invalid JSON response: ' + json
                return
            if object?.login?.result is 'Success'
                callback true, null
            else if object?.login?.result is 'NeedToken'
                editor.MediaWiki.login username, password, callback,
                    object.login.token
            else
                callback null, 'Login error of type ' + \
                    object?.login?.result
        URL = editor.MediaWiki.getAPIPage() + '?action=login' + \
            '&lgname=' + encodeURIComponent( username ) + \
            '&lgpassword=' + encodeURIComponent( password ) + \
            '&format=json&formatversion=2'
        if token then URL += '&lgtoken=' + token
        xhr.open 'POST', URL
        xhr.setRequestHeader 'Api-User-Agent', 'webLurch application'
        xhr.send()

The following function accesses the wiki, attempts to overwrite the page
with the given name, using the given content (in wikitext form), and then
calls the given callback with the results.  That callback should take two
parameters, result and error.  If result is `'Success'` then error will be
null, and the edit succeeded.  If result is null, then the error will be a
string explaining the problem.

Note that if the posting you attempt to do with the following function would
need a certain user's access rights to complete it, you should call the
`login()` function, above, first, to establish that access.  Call this one
from its callback (or any time thereafter).

    exportPage = ( pageName, content, callback ) ->
        xhr = new XMLHttpRequest()
        xhr.addEventListener 'load', ->
            json = @responseText
            try
                object = JSON.parse json
            catch e
                callback null, 'Invalid JSON response: ' + json
                return
            if not object?.query?.tokens?.csrftoken
                callback null, 'No token provided: ' + json
                return
            xhr2 = new XMLHttpRequest()
            xhr2.addEventListener 'load', ->
                json = @responseText
                try
                    object = JSON.parse json
                catch e
                    callback null, 'Invalid JSON response: ' + json
                    return
                # callback JSON.stringify object, null, 4
                if object?.edit?.result isnt 'Success'
                    callback null, 'Edit failed: ' + json
                    return
                callback 'Success', null
            content = formatContentForWiki content
            xhr2.open 'POST',
                editor.MediaWiki.getAPIPage() + '?action=edit' + \
                '&title=' + encodeURIComponent( pageName ) + \
                '&text=' + encodeURIComponent( content ) + \
                '&summary=' + encodeURIComponent( 'posted from Lurch' ) + \
                '&contentformat=' + encodeURIComponent( 'text/x-wiki' ) + \
                '&contentmodel=' + encodeURIComponent( 'wikitext' ) + \
                '&format=json&formatversion=2', true
            token = 'token=' + \
                encodeURIComponent object.query.tokens.csrftoken
            xhr2.setRequestHeader 'Content-type',
                'application/x-www-form-urlencoded'
            xhr2.setRequestHeader 'Api-User-Agent', 'webLurch application'
            xhr2.send token
        xhr.open 'GET',
            editor.MediaWiki.getAPIPage() + '?action=query&meta=tokens' + \
            '&format=json&formatversion=2'
        xhr.setRequestHeader 'Api-User-Agent', 'webLurch application'
        xhr.send()

The previous function makes use of the following one.  This depends upon the
[HTMLTags](https://www.mediawiki.org/wiki/Extension:HTML_Tags) extension to
MediaWiki, which permits arbitrary HTML, as long as it is encoded using tags
of a certain form, and the MediaWiki configuration permits the tags.  See
the documentation for the extension for details.

    formatContentForWiki = ( editorHTML ) ->
        result = ''
        depth = 0
        openRE = /^<([^ >]+)\s*([^>]+)?>/i
        closeRE = /^<\/([^ >]+)\s*>/i
        charRE = /^&([a-z0-9]+|#[0-9]+);/i
        toReplace = [ 'img', 'span', 'var', 'sup' ]
        decoder = document.createElement 'div'
        while editorHTML.length > 0
            if match = closeRE.exec editorHTML
                tagName = match[1].toLowerCase()
                if tagName in toReplace
                    depth--
                    result += "</htmltag#{depth}>"
                else
                    result += match[0]
                editorHTML = editorHTML[match[0].length..]
            else if match = openRE.exec editorHTML
                tagName = match[1].toLowerCase()
                if tagName in toReplace
                    result += "<htmltag#{depth}
                        tagname='#{tagName}' #{match[2]}>"
                    if not /\/\s*$/.test match[2] then depth++
                else
                    result += match[0]
                editorHTML = editorHTML[match[0].length..]
            else if match = charRE.exec editorHTML
                decoder.innerHTML = match[0]
                result += decoder.textContent
                editorHTML = editorHTML[match[0].length..]
            else
                result += editorHTML[0]
                editorHTML = editorHTML[1..]
        result

# Installing the plugin

The plugin, when initialized on an editor, installs all the functions above
into the editor, in a namespace called `MediaWiki`.

    tinymce.PluginManager.add 'mediawiki', ( ed, url ) ->
        ( editor = ed ).MediaWiki =
            setIndexPage : setIndexPage
            getIndexPage : getIndexPage
            setAPIPage : setAPIPage
            getAPIPage : getAPIPage
            login : login
            getPageContent : getPageContent
            importPage : importPage
            exportPage : exportPage
            embedMetadata : embedMetadata
            extractMetadata : extractMetadata
            getPageMetadata : getPageMetadata
