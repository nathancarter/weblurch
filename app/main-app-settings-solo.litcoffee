
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
        if not A.get 'filesystem'
            A.set 'filesystem', editor.Storage.getBackend()
        A.setup = ( div ) ->
            fs = A.get 'filesystem'
            entries = [
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
            ]
            for storageOption in editor.Storage.availableBackends()
                id = "filesystem_#{storageOption.replace /\s/g, '_'}"
                entries.push editor.Settings.UI.radioButton \
                    storageOption, 'filesystem', fs is storageOption, id
            div.innerHTML = entries.join '\n'
        A.teardown = ( div ) ->
            elt = ( id ) -> div.ownerDocument.getElementById id
            A.set 'wiki_username', elt( 'wiki_username' ).value
            A.set 'wiki_password', elt( 'wiki_password' ).value
            for storageOption in editor.Storage.availableBackends()
                id = "filesystem_#{storageOption.replace /\s/g, '_'}"
                if elt( id ).checked then A.setFilesystem storageOption

Install in `A` a special handler for setting the filesytem, which updates UI
controls to respect that setting.

        A.setFilesystem = ( name ) ->
            A.set 'filesystem', name
            editor.Storage.setBackend name

Initialize the UI to whatever the user's current filesystem setting is.

        A.setFilesystem A.get 'filesystem'

Initialize the settings plugin for per-document settings.  Here we override
the default set/get methods (which use the browser's `LocalStorage`) and use
a metadata object that gets embedded in the document itself.

        D = editor.Settings.addCategory 'document'
        D.metadata = { }
        D.get = ( key ) -> D.metadata?[key]
        D.set = ( key, value ) -> ( D.metadata ?= { } )[key] = value
        D.setup = ( div ) ->
            div.innerHTML = [
                editor.Settings.UI.heading 'Dependencies'
                "<div id='dependenciesSection'></div>"
                editor.Settings.UI.heading 'Google Drive'
                editor.Settings.UI.info "(Google Drive integration not yet
                    complete.<br>Check back later for progress on this
                    feature.)"
                editor.Settings.UI.text 'Save to Drive with this title',
                    'doc_title', D.get( 'doc_title' ) ? 'Untitled'
                editor.Settings.UI.heading 'Wiki Publishing'
                editor.Settings.UI.text 'Publish to wiki under this title',
                    'wiki_title', D.get( 'wiki_title' ) ? ''
            ].join '\n'
            editor.Dependencies.installUI \
                div.ownerDocument.getElementById 'dependenciesSection'
        D.teardown = ( div ) ->
            elt = ( id ) -> div.ownerDocument.getElementById id
            D.set 'wiki_title', elt( 'wiki_title' ).value

Set up the Storage plugin with the functions needed for loading and saving
document metadata.  We export to dependencies all labeled, top-level
expressions, a function defined in [the code dealing with
labels](main-app-group-labels-solo.litcoffee#label-lookup).  The system
never passes a parameter, so `interactive` defaults to yes.  If you pass a
false value, then no alert dialog will be shown in the case when metadata
cannot yet be computed.

        editor.Storage.saveMetaData = ( interactive = yes ) ->
            D.metadata ?= { }
            n = Object.keys( editor.Storage.validationsPending ? { } )
                .length
            if n > 0
                D.metadata.exports =
                    error : "This document cannot export its dependencies,
                        because at the time it was saved, #{n}
                        #{if n > 1 then 'groups were' else 'group was'}
                        still waiting for validation to finish running."
                if interactive
                    editor.Dialogs.alert
                        title : 'Dependency information not saved'
                        message : 'Because validation was not complete, the
                            saved version of this document will not be
                            usable by any dependency.  To fix this problem,
                            allow validation to finish running, then save.'
            else
                D.metadata.exports = ( group.completeForm().encode() \
                    for group in window.labeledTopLevelExpressions() )
            D.metadata.dependencies = editor.Dependencies.export()
            D.metadata
        editor.Storage.loadMetaData = ( object ) ->
            D.metadata = object
            editor.Dependencies.import D.metadata?.dependencies ? [ ]

When a document loads, we will want to ask about the data it exports to its
dependencies.  This must be an asynchronous call, because sometimes
validation will be ongoing, and thus we will need to wait for it to complete
before there any data to export can be computed.  We therefore provide the
following function, where the maximum wait time defaults to infinity, and is
expressed in milliseconds.

        editor.Storage.waitForMetaData = ( callback, maxWaitTime = 0 ) ->
            startedWaiting = ( new Date ).getTime()
            setTimeout check = ->
                metadata = editor.Storage.saveMetaData no
                if metadata? and not metadata.exports?.error? or \
                   ( new Date ).getTime() - startedWaiting > maxWaitTime > 0
                    return callback metadata
                setTimeout check, 100
            , 100
