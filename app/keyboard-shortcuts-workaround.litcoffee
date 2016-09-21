
# Workaround for Browser Keyboard Shortcut Conflicts

Assigning keyboard shortcuts to menu items in TinyMCE will not override the
shortcuts in the browser (such as Ctrl/Cmd+S for Save).  This is problematic
for a word processing app like Lurch, in which users expect certain natural
keyboard shortcuts like Ctrl/Cmd+S to have their usual semantics.

The following function takes a TinyMCE editor instance as parameter and
modifies it so that any menu item or toolbar button added to the editor with
an associated keyboard shortcut will have a new handler installed that does
override the browser shortcuts when possible.

There are some browser shortcuts that cannot be overridden.  For instance,
on Chrome, the Ctrl/Cmd+N and Ctrl/Cmd+Shift+N shortcuts for new window and
new incognito window (respectively) cannot be overridden.  This limitation
cannot be solved from within scripts, as far as I know.

    keyboardShortcutsWorkaround = ( editor ) ->

The array of shortcuts we will watch for on each keystroke.

        shortcuts = [ ]

Next, a function to turn TinyMCE keyboard shortcut descriptions like
"Meta+S" or "Ctrl+Shift+K" into a more usable form.  The result is an object
with modifier keys separated out as booleans, and a single non-modifier key
stored separately.

        createShortcutData = ( text ) ->
            [ modifiers..., key ] =
                text.toLowerCase().replace( /\s+/g, '' ).split '+'
            altKey : 'alt' in modifiers
            ctrlKey : 'ctrl' in modifiers
            metaKey : 'meta' in modifiers
            key : key

The following function takes the name and settings object of a menu item or
toolbar button from the editor and, if a keyboard shortcut is specified in
the settings object, stores the relevant shortcut data in the aforementioned
array, for later lookup.

        maybeInstall = ( name, settings ) ->
            if settings?.shortcut?
                shortcuts.push
                    keys : createShortcutData settings.shortcut
                    action : settings.onclick ? -> editor.execCommand name

We now override the editor's built-in `addMenuItem` and `addButton`
functions to first install any necessary shortcuts, and then proceed with
their original implementations.

        editor.__addMenuItem = editor.addMenuItem
        editor.addMenuItem = ( name, settings ) ->
            maybeInstall name, settings
            editor.__addMenuItem name, settings
        editor.__addButton = editor.addButton
        editor.addButton = ( name, settings ) ->
            maybeInstall name, settings
            editor.__addButton name, settings

Now install an event listener on every keydown event in the editor.  If any
of our stored shortcuts comes up, trigger its stored handler, then prevent
any other handling of the event.

        editor.on 'keydown', ( event ) ->
            for shortcut in shortcuts
                matches = yes
                for own key, value of shortcut.keys
                    if event[key] isnt value
                        matches = no
                        break
                if matches
                    event.preventDefault()
                    shortcut.action()
                    return
