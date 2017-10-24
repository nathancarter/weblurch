
# Download/Upload Plugin for [TinyMCE](http://www.tinymce.com)

This plugin lets users download the contents of their current document as
HTML, or upload any HTML file as new contents to overwrite the current
document.  It assumes that TinyMCE has been loaded into the global
namespace, so that it can access it.

If you have the [Storage Plugin](storageplugin.litcoffee) also enabled in
the same TinyMCE editor instance, it will make use of that plugin in
several ways.

 * to ensure that editor contents are saved, if desired, before overwriting
   them with new, uploaded content
 * to determine the filename used for the download, when available
 * to embed metadata in the content before downloading, and extract metadata
   after uploading

# `DownloadUpload` class

We begin by defining a class that will contain all the information needed
regarding downloading and uploading HTML content.  An instance of this class
will be stored as a member in the TinyMCE editor object.

This convention is adopted for all TinyMCE plugins in the Lurch project;
each will come with a class, and an instance of that class will be stored as
a member of the editor object when the plugin is installed in that editor.
The presence of that member indicates that the plugin has been installed,
and provides access to the full range of functionality that the plugin
grants to that editor.

    class DownloadUpload

## Constructor

At construction time, we install in the editor the download and upload
actions that can be added to the File menu and/or toolbar.

        constructor: ( @editor ) ->
            control = ( name, data ) =>
                buttonData =
                    icon : data.icon
                    shortcut : data.shortcut
                    onclick : data.onclick
                    tooltip : data.tooltip
                key = if data.icon? then 'icon' else 'text'
                buttonData[key] = data[key]
                @editor.addButton name, buttonData
                @editor.addMenuItem name, data
            control 'download',
                text : 'Download'
                icon : 'arrowdown2'
                context : 'file'
                tooltip : 'Download this document'
                onclick : => @downloadDocument()
            control 'upload',
                text : 'Upload'
                icon : 'arrowup2'
                context : 'file'
                tooltip : 'Upload new document'
                onclick : => @uploadDocument()

## Event handlers

The following functions handle the two events that this class provides, the
download event and the upload event.

The download event constructs a blob, fills it with the contents of the
editor as HTML data, and starts a download.  The only unique step in this
process is that we attempt to get a filename from the
[Storage Plugin](storageplugin.litcoffee), if one is available.  If not,
we use "untitled.html."

        downloadDocument: ->
            html = @editor.Storage.embedMetadata @editor.getContent(),
                @editor.Settings.document.metadata
            blob = new Blob [ html ], type : 'text/html'
            link = document.createElement 'a'
            link.setAttribute 'href', URL.createObjectURL blob
            link.setAttribute 'download',
                editor.Storage.filename or 'untitled.html'
            link.click()
            URL.revokeObjectURL link.getAttribute 'href'

The upload event first checks to be sure that the contents of the editor are
saved, or the user does not mind overwriting them.  This code imitates the
File > New handler in the [Storage Plugin](storageplugin.litcoffee).
This function calls the `letUserUpload` function to do the actual uploading;
that function is defined further below in this file.

        uploadDocument: ->
            return @letUserUpload() unless editor.Storage.documentDirty
            @editor.windowManager.open {
                title : 'Save first?'
                buttons : [
                    text : 'Save'
                    onclick : =>
                        editor.Storage.tryToSave ( success ) =>
                            if success then @letUserUpload()
                        @editor.windowManager.close()
                ,
                    text : 'Discard'
                    onclick : =>
                        @editor.windowManager.close()
                        @letUserUpload()
                ,
                    text : 'Cancel'
                    onclick : => @editor.windowManager.close()
                ]
            }

The following function handles the case where the user has agreed to save or
discard the current contents of the editor, so they're ready to upload a new
file to overwrite it.  We present here the user interface for doing so, and
handle the upload process.

        letUserUpload: ->
            @editor.Dialogs.promptForFile
                title : 'Choose file'
                message : 'Choose an HTML file to upload into the editor.'
                okCallback : ( fileAsDataURL ) =>
                    html = atob fileAsDataURL.split( ',' )[1]
                    { metadata, document } =
                        @editor.Storage.extractMetadata html
                    @editor.setContent document
                    if metadata?
                        @editor.Settings.document.metadata = metadata
                    @editor.focus()

# Installing the plugin

    tinymce.PluginManager.add 'downloadupload', ( editor, url ) ->
        editor.DownloadUpload = new DownloadUpload editor
