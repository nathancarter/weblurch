
/*
 * This file defines the main interface for this module.  It allows the
 * client to specify what storage method will be used (e.g., Dropbox).
 * The user can then make calls to `openFile()` or `saveFile()` from the
 * standard event handlers in their editor.
 */

( function () {

/*
 * Global variable to store the filesystem object that will permit reading
 * of folders, and reading and writing of files.  It must be an object
 * with four methods:
 *     getAccess ( successCB, failureCB ) -- to log in to the service, if
 *         needed (or just call the success callback immediately if not)
 *     readFolder ( fullPath, successCB, failureCB ) -- pass the contents
 *         of the given folder, as an array of objects with attributes
 *         `type` (one of "file"/"folder") and `name` (the usual on-disk
 *         name as a string) and any other metadata, or call the failure
 *         callback with error details
 *     readFile ( fullPath, successCB, failureCB ) -- reads a file and
 *         calls the success callback with its contents as text on success,
 *         or the failure callback with error details on failure.
 *     writeFile ( fullPath, content, successCB, failureCB ) -- writes a
 *         file and calls one of the callbacks, optionally passing details.
 *
 * An example of an object providing these four methods in a simple context
 * is the `JSONFileSystem` defined at the end of this file.
 *
 * Do not change this variable directly.  Call `setFileSystem()`, defined
 * below.
 */
var fileSystemBackEnd;
/*
 * Stores the iframe element that will be used to represent the popup dialog
 * containing a file open/save UI.
 */
var popupDialog;
/*
 * Convenience functions for hiding or showing the dialog.
 */
function showDialog () { popupDialog.style.display = 'block'; }
function hideDialog () { popupDialog.style.display = 'none'; }
/*
 * Convenience functions for passing a message to an iframe
 */
function tellPopupDialog ()
{
    var args = Array.prototype.slice.apply( arguments );
    popupDialog.contentWindow.postMessage( args, '*' );
}
function tellIFrame ()
{
    var args = Array.prototype.slice.apply( arguments );
    var target = args.shift();
    target.contentWindow.postMessage( args, '*' );
}
/*
 * This function populates the popupDialog variable if and only if it has
 * not already been populated, returning the (potentially newly created, or
 * potentially cached) result.
 */
function getPopupDialog ()
{
    if ( !popupDialog ) {
        popupDialog = document.createElement( 'iframe' );
        popupDialog.style.position = 'absolute';
        popupDialog.style.top = '50%';
        popupDialog.style.left = '50%';
        popupDialog.style.width = '600px';
        popupDialog.style.height = '400px';
        popupDialog.style.marginTop = '-200px';
        popupDialog.style.marginLeft = '-300px';
        popupDialog.style.border = '2px solid black';
        popupDialog.style.zIndex = '100';
        hideDialog();
        document.body.appendChild( popupDialog );
    }
    return popupDialog;
}
/*
 * This function can be used to fill any iframe with the HTML required to be
 * used as a File > Open/Save dialog.
 */
function fillIFrame ( iframe, callback )
{
    iframe.setAttribute( 'src', './dialog.html' );
    function once () {
        iframe.removeEventListener( 'load', once, false );
        callback();
    }
    iframe.addEventListener( 'load', once, false );
}

/*
 * Function to specify the filesystem object, whose format is defined above.
 * The client must call this function before attempting to use any of the
 * functions below that require a filesytem, such as openFile() or
 * saveFile().
 */
setFileSystem = window.setFileSystem = function ( fileSystem )
{
    fileSystemBackEnd = fileSystem;
}

/*
 * The last path the user visited using the file open/save dialog window.
 * This will be an array of strings rather than a single string separated
 * by some kind of slashes.
 */
var lastVisitedPath = [ ];
/*
 * If the user browses into a folder, update the `lastVisitedPath` to
 * reflect it.  Handle `..` specially by going up one level.
 */
function updatePath ( browseIntoThis ) {
    if ( browseIntoThis == '..' )
        lastVisitedPath.pop();
    else
        lastVisitedPath.push( browseIntoThis );
}

/*
 * This will be initialized later to an event handler for messages from the
 * file open/save dialog iframe.  Each of the two workhorse functions in
 * this module (`openFile()` and `saveFile()`) installs a different handler
 * in this global variable to respond differently to messages from the
 * dialog.  This handler is referenced in the event listener installed
 * next.
 */
var messageHandler;
/*
 * Receive messages from related windows (most notably the `popupDialog`)
 * and if they are an array, treat it as a LISP-style expression, that is,
 * of the form [command,arg1,arg2,...,argN], and pass it that way to the
 * message handler, if there is one.
 */
window.addEventListener( 'message', function ( event ) {
    if ( !( event.data instanceof Array ) ) return;
    var command = event.data.shift();
    var args = event.data;
    if ( messageHandler ) messageHandler( command, args );
} );

/*
 * We define two placeholder functions that are useful when testing and
 * debugging.  These are used as the default success/failure callbacks in
 * many of the functions below.  This way, if you wish to call `openFile()`
 * or `saveFile()` from the browser console, for example, you do not need
 * to specify callbacks; these debugging callbacks will be used by default,
 * and are useful in such testing/debugging contexts.
 */
function successDebug () {
    console.log( 'Success callback:',
                 Array.prototype.slice.apply( arguments ) );
}
function failureDebug () {
    console.log( 'Failure callback:',
                 Array.prototype.slice.apply( arguments ) );
}

/*
 * Show a "File > Open" dialog box.
 *
 * If the user chooses a file to open, call the success callback with an
 * object containing some file metadata including its full `path`, and a
 * `get ( successCB, failureCB )` method the user can call thereafter.  That
 * method will either call the success callback with the file contents as
 * text, or will call the failure callback with error details.
 *
 * If the user doesn't log in to the service or cancels the dialog, the
 * failure callback will be called.
 *
 * The object passed to the success callback also contains an `update`
 * member, which can be used to save new content over top of the content of
 * the file opened using this method.  See details in the `saveFile`
 * function implemented, after the `openFile` function, further below.
 *
 * By default, this routine displays an iframe to contain the File > Open
 * dialog it shows to the user.  If the client already has an iframe to use
 * as the dialog, it can be passed as the third parameter, and will be used.
 * That parameter is optional; if not provided, an iframe created by this
 * module is used.  When providing an iframe, the client will need to be
 * sure to hide/close it when either the success/failure callback is called.
 *
 * Example use:
 *
 * // prompt the user with a File > Open dialog
 * openFile ( function ( chosenFile ) {
 *     console.log( 'The user chose this file:', chosenFile.path );
 *     // now try to get the file contents from the storage provider
 *     chosenFile.get( function ( contents ) {
 *         // success!
 *         console.log( 'File contents:', contents );
 *     }, function ( error ) { console.log( 'Fetch error:', error ); } );
 * }, function ( error ) { console.log( 'No file chosen:', error ); } );
 */
openFile = window.openFile = function ( successCB, failureCB, iframe )
{
    if ( !successCB ) successCB = successDebug;
    if ( !failureCB ) failureCB = failureDebug;
    var dialog = iframe || getPopupDialog();
    fillIFrame( dialog, function () {
        fileSystemBackEnd.getAccess( function () {
            tellIFrame( dialog, 'setDialogType', 'open' );
            messageHandler = function ( command, args ) {
                if ( command == 'dialogBrowse' ) {
                    updatePath( args[0] );
                    openFile( successCB, failureCB );
                } else if ( command == 'dialogOpen' ) {
                    if ( dialog != iframe ) hideDialog();
                    var path = lastVisitedPath.concat( [ args[0] ] );
                    successCB( {
                        path : path,
                        get : function ( succ, fail ) {
                            if ( !succ ) succ = successDebug;
                            if ( !fail ) fail = failureDebug;
                            fileSystemBackEnd.readFile( path, succ, fail );
                        },
                        update : function ( content, succ, fail ) {
                            if ( !succ ) succ = successDebug;
                            if ( !fail ) fail = failureDebug;
                            fileSystemBackEnd.writeFile( path, content,
                                succ, fail );
                        }
                    } );
                } else {
                    if ( dialog != iframe ) hideDialog();
                    failureCB( 'User canceled dialog.' );
                }
            };
            fileSystemBackEnd.readFolder( lastVisitedPath,
                function ( list ) {
                    list.unshift( 'showList' );
                    tellIFrame.apply( null, [ dialog ].concat( list ) );
                }, failureCB );
            if ( dialog != iframe ) showDialog();
        }, failureCB );
    } );
}

/*
 * Show a "File > Save" dialog box.
 *
 * If the user chooses a destination to save, call the success callback
 * with an object containing some file metadata including its full `path`,
 * and an `update ( content, successCB, failureCB )` method the user can
 * call thereafter to write content to the storage provider at the user's
 * chosen location.  That method will either call the success callback with
 * storage-provider-specific details about the successful write operation,
 * or will call the failure callback with error details.  The content to
 * write must be text data.  Arbitrary JSON data can be saved by first
 * applying `JSON.stringify()` to it, and saving the results as text.
 *
 * The application may retain the object given to the first success callback
 * for longer than is needed to call `update()` once.  Thus, for instance,
 * if the user later chooses to "Save" (rather than "Save as...") the same
 * `update()` function can be called again with new file contents, to save
 * new data at the same chosen location.
 *
 * If the user doesn't log in to the service or cancels the dialog, the
 * failure callback will be called.
 *
 * By default, this routine displays an iframe to contain the File > Open
 * dialog it shows to the user.  If the client already has an iframe to use
 * as the dialog, it can be passed as the third parameter, and will be used.
 * That parameter is optional; if not provided, an iframe created by this
 * module is used.  When providing an iframe, the client will need to be
 * sure to hide/close it when either the success/failure callback is called.
 *
 * Example use:
 *
 * // prompt the user with a File > Save dialog
 * saveFile ( function ( saveHere ) {
 *     console.log( 'The user chose to save here:', saveHere.path );
 *     // now try to write the file contents to the storage provider
 *     saveHere.update( stringToSave, function ( optionalData ) {
 *         // success!
 *         console.log( 'File saved.', optionalData );
 *     }, function ( error ) { console.log( 'Write error:', error ); } );
 * }, function ( error ) { console.log( 'No destination chosen:', error ); } );
 */
saveFile = window.saveFile = function ( successCB, failureCB, iframe )
{
    if ( !successCB ) successCB = successDebug;
    if ( !failureCB ) failureCB = failureDebug;
    var dialog = iframe || getPopupDialog();
    fillIFrame( dialog, function () {
        fileSystemBackEnd.getAccess( function () {
            tellIFrame( dialog, 'setDialogType', 'save' );
            messageHandler = function ( command, args ) {
                if ( command == 'dialogBrowse' ) {
                    updatePath( args[0] );
                    saveFile( successCB, failureCB );
                } else if ( command == 'dialogSave' ) {
                    if ( dialog != iframe ) hideDialog();
                    var path = lastVisitedPath.concat( [ args[0] ] );
                    successCB( {
                        path : path,
                        update : function ( content, succ, fail ) {
                            if ( !succ ) succ = successDebug;
                            if ( !fail ) fail = failureDebug;
                            fileSystemBackEnd.writeFile( path, content,
                                succ, fail );
                        }
                    } );
                } else {
                    if ( dialog != iframe ) hideDialog();
                    failureCB( 'User canceled dialog.' );
                }
            }
            fileSystemBackEnd.readFolder( lastVisitedPath,
                function ( list ) {
                    list.unshift( 'showList' );
                    tellIFrame.apply( null, [ dialog ].concat( list ) );
                }, failureCB );
            if ( dialog != iframe ) showDialog();
        }, failureCB );
    } );
}

/*
 * We provide here an example implementation of a filesystem object, as
 * defined at the top of this file.  It is a read-only filesystem
 * represented by a JSON hierarchy of files and folders.
 *
 * In a JSON filesystem, a file is an object with `type:'file'` and
 * `contents:'some text'` and any other metadata you wish to add.
 * A folder is an object with `type:'folder'` and `contents` mapping to an
 * object whose keys are names and whose values are files or folders.
 * A JSON filesystem is a folder object serving as the root.
 *
 * Example:
 *
 * setFileSystem( new JSONFileSystem( {
 *     type : 'folder', // filesystem root
 *     contents : {
 *         'example.txt' : {
 *             type : 'file',
 *             contents : 'This is an example text file.\nThat\'s all.'
 *         },
 *         'My Pictures' : {
 *             type : 'folder',
 *             contents : {
 *                  'README.md' : {
 *                      type : 'file',
 *                      contents : 'No photos yet.\n\n# SO SAD'
 *                  }
 *             }
 *         }
 *     }
 * } ) );
 */
JSONFileSystem = window.JSONFileSystem = function ( jsonObject )
{
    /*
     * Utility function for walking paths from the root into the filesystem
     */
    function find ( fullPath, type ) {
        var walk = jsonObject;
        for ( var i = 0 ; i < fullPath.length ; i++ ) {
            if ( !walk.hasOwnProperty( 'contents' ) )
                throw( 'Invalid JSON filesystem structure in ' + fullPath );
            if ( !walk.contents.hasOwnProperty( fullPath[i] ) )
                throw( 'Could not find the folder specified: ' + fullPath );
            walk = walk.contents[fullPath[i]];
        }
        if ( walk.type != type )
            throw( 'Path does not point to a ' + type + ': ' + fullPath );
        return walk;
    }
    return {
        contents : jsonObject,
        /*
         * No login required; just call success.
         */
        getAccess : function ( successCB, failureCB ) { successCB(); },
        /*
         * Convert JSONFileSystem format into format expected by
         * `readFolder()`
         */
        readFolder : function ( fullPath, successCB, failureCB ) {
            try {
                var folder = find( fullPath, 'folder' );
                var contents = [ ];
                for ( var key in folder.contents ) {
                    if ( folder.contents.hasOwnProperty( key ) ) {
                        contents.push( {
                            name : key,
                            type : folder.contents[key].type
                        } );
                    }
                }
                if ( folder != jsonObject )
                    contents.unshift( { name : '..', type : 'folder' } );
                successCB( contents );
            } catch ( error ) { failureCB( error ); }
        },
        /*
         * Find file and return contents if it exists
         */
        readFile : function ( fullPath, successCB, failureCB ) {
            try { successCB( find( fullPath, 'file' ).contents ); }
            catch ( error ) { failureCB( error ); }
        },
        /*
         * There are several cases, each handled with comments inline below.
         */
        writeFile : function ( fullPath, content, successCB, failureCB ) {
            try {
                var existingFile = find( fullPath, 'file' );
                // The file exists, great!  Just change its contents:
                existingFile.contents = content;
                successCB( 'File updated successfully.' );
            } catch ( error ) {
                if ( /Could not find/.test( error ) ) {
                    // The file does not exist.
                    // Does its parent folder exist?  Let's check.
                    try {
                        fullPath = fullPath.slice();
                        var fileName = fullPath.pop();
                        var parentFolder = find( fullPath, 'folder' );
                        // Yes, it exists!  Create a new file there.
                        parentFolder.contents[fileName] = {
                            type : 'file',
                            contents : content
                        };
                        successCB( 'File written successfully.' );
                    } catch ( error ) {
                        // Parent folder doesn't exist.  Signal an error.
                        failureCB( error );
                    }
                } else {
                    // Some other error we can't solve.  Propagate it.
                    failureCB( error );
                }
            }
        }
    }
}

/*
 * End of module IIFE.
 */

} )();
