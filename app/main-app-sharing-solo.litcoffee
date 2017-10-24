
# Main webLurch Application

## Modular organization

This file is one of several files that make up the main webLurch
Application.  For more information on the app and the other files, see
[the first source code file in this set](main-app-basics-solo.litcoffee).

## Sharing files with permalinks

Add a menu item for sharing documents via permalinks or embedding.
Permalinks will be shortened via the goo.gl service.

First, set up the Google API key for URL shortening.

    window.addEventListener 'load', ->
        gapi?.client?.setApiKey 'AIzaSyAf7F0I39DdI2jtD7zrPUa4eQvUXZ-K6W8'
        gapi?.client?.load 'urlshortener', 'v1', ->
    , no

Second, add the menu item.

    window.groupMenuItems.sharelink =
        text : 'Share document...'
        context : 'file'
        onclick : ->
            page = window.location.href.split( '?' )[0]
            editor = tinymce.activeEditor
            content = editor.Storage.embedMetadata editor.getContent(),
                editor.Storage.saveMetaData()
            url = page + '?document=' + encodeURIComponent content
            showURL = ( url ) ->
                embed = "<iframe src='#{url}' width=800
                    height=600></iframe>"
                    .replace /&/g, '&amp;'
                    .replace /'/g, '&apos;'
                    .replace /"/g, '&quot;'
                    .replace /</g, '&lt;'
                    .replace />/g, '&gt;'
                editor.Dialogs.alert
                    title : 'Permanent Sharing Links'
                    message : "
                        <h3>Sharing URL</h3>
                        <p>Copy this URL to your clipboard, and paste
                        wherever you like, such as email.</p>
                        <input type='text' size=50 id='firstURL'
                         value='#{url.replace /'/g, '&apos;'}'/>
                        <h3>Embedding HTML</h3>
                        <p>Copy this HTML to your clipboard, and paste into
                        any webpage or blog to embed a Lurch instance with
                        this document in it.</p>
                        <input type='text' size=50 value='#{embed}'/>
                        <script>
                        var all = document.getElementsByTagName( 'input' );
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
                if response.id? then showURL response.id else showURL url
