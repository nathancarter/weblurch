
/*
 * This file provides a new "class" (okay, constructor and prototype) that
 * can be instantiated and used as the filesystem object the client gives to
 * the API in cloud-storage.js.
 *
 * However, rather than cloud storage, this provides in-browser storage
 * using the browser's LocalStorage object.  Because it does not provide any
 * API for creating or renaming folders, it uses a flat filesystem.  All
 * files must exist inside a single root directory, and so the only valid
 * paths are those of the form "/some_filename".
 *
 * The class defined herein obeys the constraints set out in the
 * documentation at the top of the file cloud-storage.js in this folder.
 */

/*
 * The constructor, to which the client must provide the name of the key
 * under which the filesystem will be stored in LocalStorage.  The default
 * is "_fileSystem".
 */
function LocalStorageFileSystem ( key )
{
    this.key = key || '_fileSystem';
}

/*
 * Tests whether the browser supports LocalStorage, and immediately calls
 * the success or failure callback indicating the result.
 *
 * The test here is related to how this SO answer says to do it:
 *     https://stackoverflow.com/a/11214467/670492
 */
LocalStorageFileSystem.prototype.getAccess =
    function ( successCB, failureCB )
{
    try {
        var dummy = this.key + '_dummy_data';
        localStorage.setItem( dummy, dummy );
        localStorage.removeItem( dummy );
        successCB();
    } catch ( error ) {
        failureCB( error );
    }
}

/*
 * Because a LocalStorage filesystem is flat, this yields (to the success
 * callback) all the files in the filesystem if fullPath is [], and
 * calls the failure callback in all other cases.
 *
 * You should verify that the browser supports LocalStorage before calling
 * this function, by calling getAccess(), above.  If you do not, this may
 * throw an error.
 */
LocalStorageFileSystem.prototype.readFolder =
    function ( fullPath, successCB, failureCB )
{
    if ( fullPath.length != 0 )
        failureCB( 'LocalStorage is a flat file system.' );
    var result = [ ];
    for ( var i = 0 ; i < localStorage.length ; i++ ) {
        var key = localStorage.key( i );
        if ( key.substring( 0, this.key.length ) == this.key )
            result.push( {
                type : 'file',
                name : key.substring( this.key.length )
            } );
    }
    successCB( result );
}

/*
 * Verifies that (a) the fullPath is to a file in the root folder and (b)
 * that file exists in LocalStorage.  If so, it calls the success callback
 * with the file contents as text.  Otherwise, it calls the failure
 * callback.
 *
 * You should verify that the browser supports LocalStorage before calling
 * this function, by calling getAccess(), above.  If you do not, this may
 * throw an error.
 */
LocalStorageFileSystem.prototype.readFile =
    function ( fullPath, successCB, failureCB )
{
    if ( fullPath.length != 1 )
        failureCB( 'Invalid file path: /' + fullPath.join( '/' ) );
    var result = localStorage.getItem( this.key + fullPath[0] );
    if ( typeof( result ) != 'string' )
        failureCB( 'No such file: ' + fullPath[0] );
    successCB( result );
}

/*
 * Verifies that the fullPath is to a file in the root folder.  If so, it
 * attempts to write the given contents, as text, into LocalStorage under a
 * key that will be associated with that filename.  If it fails (e.g., if
 * LocalStorage is full) then the failure callback is called.  Otherwise,
 * the success callback is called.
 *
 * You should verify that the browser supports LocalStorage before calling
 * this function, by calling getAccess(), above.  If you do not, this may
 * throw an error.
 */
LocalStorageFileSystem.prototype.writeFile =
    function ( fullPath, content, successCB, failureCB )
{
    if ( fullPath.length != 1 )
        failureCB( 'Invalid file path: /' + fullPath.join( '/' ) );
    try {
        localStorage.setItem( this.key + fullPath[0], content );
    } catch ( error ) {
        failureCB( error );
    }
    successCB( 'File written successfully.' );
}
