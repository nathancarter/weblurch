
/*
 * This file provides a new "class" (okay, constructor and prototype) that
 * can be instantiated and used as the filesystem object the client gives to
 * the API in cloud-storage.js.
 *
 * Furthermore, the pattern shown herein can be imitated to define back ends
 * for other cloud storage providers as well, such as Google Drive.
 *
 * This file assumes that the Dropbox class has been defined in the global
 * scope.  To ensure this, import this script only after you have imported
 * the Dropbox SDK script located at the following CDN URL.
 *     https://unpkg.com/dropbox/dist/Dropbox-sdk.min.js
 *
 * The class defined hereing obeys the constraints set out in the
 * documentation at the top of the file cloud-storage.js in this folder.
 */

/*
 * The constructor, to which the client must provide only one thing, their
 * app's "client ID."  To find your app's client ID, visit the following
 * URL and click into your app (or create one if you haven't already).
 *     https://www.dropbox.com/developers/apps
 * The client ID appears on the app details page.
 *
 * This function stores the client ID in this object for use by a Dropbox
 * instance to be created later, once an access token is gained by the
 * login process in `getAccess()`.
 */
function DropboxFileSystem ( clientID )
{
    this.clientID = clientID;
}

/*
 * Opens a new tab/window in the browser showing the Dropbox login page for
 * the app whose client ID was provided at construction time.  If the user
 * logs in successfully, then the success callback will be called, and all
 * requisite data stored inside this object for use by the other functions
 * defined below to access the user's Dropbox.  Upon successful login, the
 * login window is also closed, bringing the user back to the page in which
 * this script was run (your app).
 *
 * Note that this requires the `dropbox-login.html` page to be present in
 * the same folder as the page calling this function.  If you are running
 * this code from a CDN, you will at least need to download that login page
 * and place it in your project's web space.
 */
DropboxFileSystem.prototype.getAccess = function ( successCB, failureCB )
{
    if ( this.dropbox ) return successCB();
    var loginWindow = window.open( './dropbox-login.html' );
    var that = this;
    if ( !this.installedEventHandler ) {
        window.addEventListener( 'message', function ( event ) {
            try {
                var message = JSON.parse( event.data );
                if ( !( message instanceof Array ) ) return;
                var command = message.shift();
                if ( command == 'dialogLogin' ) {
                    loginWindow.close();
                    that.accountData = message.shift();
                    if ( that.accountData.access_token ) {
                        that.dropbox = new Dropbox( {
                            accessToken : that.accountData.access_token
                        } );
                        successCB();
                    } else {
                        failureCB( that.accountData );
                    }
                }
            } catch ( e ) { }
        } );
        this.installedEventHandler = true;
    }
    loginWindow.onload = function () {
        loginWindow.postMessage( [ 'setClientID', that.clientID ], '*' );
    }
}

/*
 * Reads the contents of a folder in the user's Dropbox.  Fails if the user
 * has not yet logged in, or if the given path does not point to a folder.
 * The path should be provided as an array of steps in the path.  E.g.,
 * `/foo/bar` should be `['foo','bar']`.  The data sent to the success
 * callback is an array of objects with `type` and `name` attributes,
 * suitable for handing to the `showList()` method of the file dialog
 * defined in `dialog.js`.
 */
DropboxFileSystem.prototype.readFolder =
    function ( fullPath, successCB, failureCB )
{
    if ( !this.dropbox )
        failureCB( 'The user has not logged in to Dropbox.' );
    this.dropbox
    .filesListFolder( { path : fullPath.join( '/' ) } )
    .then( function ( response ) {
        var result = [ ];
        for ( var i = 0 ; i < response.entries.length ; i++ )
            result.push( {
                type : response.entries[i]['.tag'],
                name : response.entries[i].name
            } );
        successCB( result );
    } )
    .catch( failureCB );
}

/*
 * Reads the contents of a file in the user's Dropbox.  Fails if the user
 * has not yet logged in, or if the given path does not point to a file.
 * The path should be provided as an array, as in the previous function.
 * The data sent to the success callback is the contents of the file as
 * text.
 */
DropboxFileSystem.prototype.readFile =
    function ( fullPath, successCB, failureCB )
{
    if ( !this.dropbox )
        failureCB( 'The user has not logged in to Dropbox.' );
    this.dropbox.filesDownload( {
        path : '/' + fullPath.join( '/' )
    } )
    .then( function ( response ) {
        var savedFile = response.fileBlob;
        var reader = new FileReader();
        reader.onload = function () { successCB( reader.result ); };
        reader.onerror = function () { failureCB( reader.error ); };
        reader.readAsText( savedFile );
    } ).catch( function ( error ) {
        failureCB( error );
    } );
}

/*
 * Write the given text to a file in the user's Dropbox.  Fails if the user
 * has not yet logged in, or if the given path does not point to a file, or
 * if something goes wrong with the write operation on the server.  The
 * path should be provided as an array, as in the previous two functions.
 * The data sent to the success callback is the raw response from the
 * Dropbox API.  Files are silently overwritten, so only pass a path that
 * you know you actually want to overwrite.
 */
DropboxFileSystem.prototype.writeFile =
    function ( fullPath, content, successCB, failureCB )
{
    if ( !this.dropbox )
        failureCB( 'The user has not logged in to Dropbox.' );
    var mode = { };
    mode['.tag'] = 'overwrite';
    this.dropbox.filesUpload( {
        contents : content,
        path : '/' + fullPath.join( '/' ),
        mode : mode,
        autorename : false
    } )
    .then( function ( response ) {
        successCB( response );
    } ).catch( function ( error ) {
        failureCB( error );
    } );
}
