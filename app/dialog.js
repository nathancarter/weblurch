
/*
 * This file is loaded by dialog.html, which lives in an iframe and
 * functions as a popup dialog for File > Open/Save operations.  The code in
 * this file provides the interactivity for the UI of that dialog, as well
 * as the message passing to/from the parent window, to receive instructions
 * about what files/folders to display, and return results about what the
 * user chooses in the dialog.  To that end, we have the following
 * convenience function for sending messages to the parent.
 */
function tellParent ( message ) {
    parent.postMessage( message, '*' );
}
/*
 * It comes with the following event handler for receiving messages from the
 * parent.  We expect them to be an array embodying a LISP-style
 * expression, that is, of the form [command,arg1,arg2,...,argN].  So we
 * interpret all arrays that way, and support two commands only:
 * "setDialogType" and "showList" -- these call functions of the same name
 * in this module, which are documented below.
 */
window.addEventListener( 'message', function ( event ) {
    if ( !( event.data instanceof Array ) ) return;
    var command = event.data.shift();
    var args = event.data;
    if ( command == 'setDialogType' ) {
        setDialogType( args[0] );
    } else if ( command == 'showList' ) {
        showList( args );
    }
}, false );

/*
 * Two convenience functions for adding/removing classes from HTMLElements.
 * Normally this is done with jQuery, but this library is small and does not
 * need to import all of jQuery for this one, small task.
 */
function addClass ( element, className ) {
    var classes = element.getAttribute( 'class' ).split( ' ' );
    classes.push( className );
    element.setAttribute( 'class', classes.join( ' ' ) );
}
function removeClass ( element, className ) {
    var classes = element.getAttribute( 'class' ).split( ' ' );
    for ( var i = classes.length - 1 ; i >= 0 ; i-- )
        if ( classes[i] == className )
            classes.splice( i, 1 );
    element.setAttribute( 'class', classes.join( ' ' ) );
}

/*
 * Set up the UI.  This includes declaring some convenient global variables
 * to point to various UI elements, and attaching simple event handlers to
 * each of the buttons in the UI.
 */
window.onload = function () {
    var ids = [ 'filesList', 'buttonsFooter', 'cancelButton', 'openButton',
        'saveButton', 'fileNameInput' ];
    for ( var i = 0 ; i < ids.length ; i++ )
        window[ids[i]] = document.getElementById( ids[i] );
    window.cancelButton.addEventListener( 'click', function () {
        tellParent( [ 'dialogCancel' ] );
    } );
    window.saveButton.addEventListener( 'click', function () {
        tellParent( [ 'dialogSave', fileNameInput.value ] );
    } );
    window.openButton.addEventListener( 'click', function () {
        tellParent( [ 'dialogOpen', fileNameInput.value ] );
    } );
    setDialogType( 'open' );
    tellParent( 'loaded' );
};

/*
 * This subroutine is used by both of the main workhorse functions, below.
 *
 * Clear the "selectedItem" class from all items shown in the dialog, then
 * set it back on just one element, the one passed as parameter.  This also
 * places that element's filename in the filename input text box, the
 * standard behavior for Save dialogs.  If no element is given, this simply
 * clears the selection and empties that text input box.
 */
function select ( element ) {
    var others = document.getElementsByClassName( 'selectedItem' );
    for ( var i = others.length - 1 ; i >= 0 ; i-- )
        removeClass( others[i], 'selectedItem' );
    if ( element ) {
        addClass( element, 'selectedItem' );
        fileNameInput.value = element.textContent;
    } else {
        fileNameInput.value = '';
    }
}

/*
 * We store in a global variable what type of dialog we're displaying.  This
 * script (and dialog.html) support two types, "open" and "save" -- each
 * represented by one of those two lower case strings stored in this
 * variable.
 *
 * Do not write to this variable directly.  Instead, call the setter defined
 * below.
 */
var dialogType;
/*
 * The first of two main workhorse functions provided by this module.  It
 * sets which type of dialog we will show.  In addition to setting the above
 * global variable, it also resets the state of the UI (deselecting any
 * formerly selected file and showing/hiding the appropriate controls).
 *
 * Note that the client does not call this routine.  Rather, the parent
 * window (running the cloud-storage.js code) will post a message to the
 * iframe containing this file, which the above message handler will then
 * interpret and call this function in the dialog.  Such code in
 * cloud-storage.js is called indirectly from the client, through the
 * openFile() and saveFile() API.
 */
function setDialogType ( type ) {
    dialogType = type;
    select( null );
    if ( type == 'open' ) {
        window.openButton.style.display = 'inline';
        window.saveButton.style.display = 'none';
        window.fileNameInput.style.display = 'none';
    } else {
        window.openButton.style.display = 'none';
        window.saveButton.style.display = 'inline';
        window.fileNameInput.style.display = 'inline';
    }
}

/*
 * The second of the two main workhorse functions in this module, called
 * when the parent window passes a "showList" message to this dialog (as
 * described in the message handler documented above).
 *
 * The one parameter must be a list of objects, each of which has at least a
 * `type` member (either "file" or "folder") and a `name` member (a string
 * containing the file or folder's name).  Other metadata may be included in
 * the objects, but is not (yet) used for anything by this function.
 *
 * This clears the contents of the file/folder list currently shown in the
 * dialog and replaces them with this list, in the order given.
 *
 * It also installs event handlers that do the following:  When the user
 * double-clicks a folder-type item, the dialog will tell the parent that
 * the user "browsed" into that item.  When the user double-clicks a
 * file-type item, the dialog will tell the parent that the user chose to
 * open/save a file at that location.
 *
 * Note that the client does not call this routine.  Rather, the parent
 * window (running the cloud-storage.js code) will post a message to the
 * iframe containing this file, which the above message handler will then
 * interpret and call this function in the dialog.  Such code in
 * cloud-storage.js is called indirectly from the client, through the
 * openFile() and saveFile() API.
 */
function showList ( list )
{
    filesList.innerHTML = '';
    for ( var i = 0 ; i < list.length ; i++ ) {
        filesList.innerHTML +=
            '<div class="filesListItem" data-type="' + list[i].type + '">'
          + list[i].name + '</div>';
    }
    var items = filesList.getElementsByClassName( 'filesListItem' );
    for ( var i = 0 ; i < items.length ; i++ ) {
        items[i].addEventListener( 'click', function ( event ) {
            event.preventDefault();
            select( event.target );
        } );
        items[i].addEventListener( 'dblclick', function ( event ) {
            event.preventDefault();
            var type = event.target.getAttribute( 'data-type' );
            if ( type == 'folder' )
                parent.postMessage( [ 'dialogBrowse',
                                      event.target.textContent ], '*' );
            else if ( dialogType == 'open' )
                window.openButton.click();
            else
                window.saveButton.click();
        } );
    }
}
