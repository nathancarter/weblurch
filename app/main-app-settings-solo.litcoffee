
# Main webLurch Application

## Modular organization

This file is one of several files that make up the main webLurch
Application.  For more information on the app and the other files, see
[the first source code file in this set](main-app-basics-solo.litcoffee).

## Application and document settings

Add menu items for the application-level and document-level settings
dialogs.

    window.groupMenuItems.appsettings =
        text : 'Application settings...'
        context : 'file'
        onclick : -> tinymce.activeEditor.Settings.application.showUI()
    window.groupMenuItems.docsettings =
        text : 'Document settings...'
        context : 'file'
        onclick : -> tinymce.activeEditor.Settings.document.showUI()

Now add a few actions to take after the editor has been initialized.

    window.afterEditorReadyArray.push ( editor ) ->

Initialize the settings plugin for global app settings.

        A = editor.Settings.addCategory 'application'
        if not A.get 'filesystem' then A.set 'filesystem', 'dropbox'
        A.setup = ( div ) ->
            fs = A.get 'filesystem'
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
                editor.Settings.UI.heading 'Open/Save Filesystem'
                editor.Settings.UI.radioButton \
                    'Dropbox (cloud storage, requires account)',
                    'filesystem', fs is 'dropbox', 'filesystem_dropbox'
                editor.Settings.UI.radioButton \
                    'Local Storage (kept permanently, in browser only)',
                    'filesystem', fs is 'local storage',
                    'filesystem_local_storage'
            ].join '\n'
        A.teardown = ( div ) ->
            elt = ( id ) -> div.ownerDocument.getElementById id
            A.set 'wiki_username', elt( 'wiki_username' ).value
            A.set 'wiki_password', elt( 'wiki_password' ).value
            A.setFilesystem if elt( 'filesystem_dropbox' ).checked then \
                'dropbox' else 'local storage'

Install in `A` a special handler for setting the filesytem, which updates UI
controls to respect that setting.

        A.setFilesystem = ( name ) ->
            A.set 'filesystem', name
            if name is 'dropbox'
                editor.LoadSave.installOpenHandler \
                    editor.Dropbox.openHandler
                editor.LoadSave.installSaveHandler \
                    editor.Dropbox.saveHandler
                editor.LoadSave.installManageFilesHandler \
                    editor.Dropbox.manageFilesHandler
            else
                editor.LoadSave.installOpenHandler()
                editor.LoadSave.installSaveHandler()
                editor.LoadSave.installManageFilesHandler()

Initialize the UI to whatever the user's current filesystem setting is.

        A.setFilesystem A.get 'filesystem'

Initialize the settings plugin for per-document settings.  Here we override
the default set/get methods (which use the browser's `LocalStorage`) and use
a metadata object that gets embedded in the document itself.

        D = editor.Settings.addCategory 'document'
        D.metadata = { }
        D.get = ( key ) -> D.metadata[key]
        D.set = ( key, value ) -> D.metadata[key] = value
        D.setup = ( div ) ->
            div.innerHTML = [
                editor.Settings.UI.heading 'Dependencies'
                "<div id='dependenciesSection'></div>"
                editor.Settings.UI.heading 'Wiki Publishing'
                editor.Settings.UI.text 'Publish to wiki under this title',
                    'wiki_title', D.get( 'wiki_title' ) ? ''
            ].join '\n'
            editor.Dependencies.installUI \
                div.ownerDocument.getElementById 'dependenciesSection'
        D.teardown = ( div ) ->
            elt = ( id ) -> div.ownerDocument.getElementById id
            D.set 'wiki_title', elt( 'wiki_title' ).value

Set up the load/save plugin with the functions needed for loading and saving
document metadata.  We export to dependencies all labeled, top-level
expressions, a function defined in [the code dealing with
labels](main-app-group-labels-solo.litcoffee#label-lookup).

        editor.LoadSave.saveMetaData = ->
            n = Object.keys( editor.LoadSave.validationsPending ? { } )
                .length
            if n > 0
                D.metadata.exports =
                    error : "This document cannot export its dependencies,
                        because at the time it was saved, #{n}
                        #{if n > 1 then 'groups were' else 'group was'}
                        still waiting for validation to finish running."
                editor.Dialogs.alert
                    title : 'Dependency information not saved'
                    message : 'Because validation was not complete, the
                        saved version of this document will not be usable by
                        any dependency.  To fix this problem, allow
                        validation to finish running, then save.'
            else
                D.metadata.exports = ( group.completeForm().encode() \
                    for group in window.labeledTopLevelExpressions() )
            D.metadata.dependencies = editor.Dependencies.export()
            D.metadata
        editor.LoadSave.loadMetaData = ( object ) ->
            D.metadata = object
            editor.Dependencies.import D.metadata?.dependencies ? [ ]
