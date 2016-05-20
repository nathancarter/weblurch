
# Project Plan

This document aims to be a complete plan for what needs to be done on this
project, readable by developers.  It can therefore be viewed as a to-do list
in chronological order, the first items being those that should be done
next, and the later items those that must come after.  Necessarily, the
later items are more vague than the earlier ones.

Note also that there are some [known bugs and planned enhancements](
bugs-and-enhancements.md) not listed in this file, because they are not part
of the linear progression of the project.  They can be addressed whenever it
becomes convenient or useful; this document lists things in a more-or-less
required order of completion.

## Dependencies

Plugin

 * Write a member that looks at a file in `jsfs` and gets its `exports`
   metadata, returning it.
 * Temporarily alter the `saveMetadata` function in the main Lurch app so
   that it writes some unimportant metadata (such as the text content of
   each top-level group) to prepare to test this functionality.
 * Test it by saving a file with some top-level groups, then calling this
   new function from the console to ensure that it extracts the metadata
   correctly.
 * Write a member that fetches a URL, extracts its `exports` metadata,
   and sends that metadata to a callback, or an error object if this fails.
 * Test it by saving a file to the wiki with some top-level groups, then
   calling this new function from the console to ensure that it extracts the
   metadata correctly.
 * Write a wrapper function that does the same thing iff the last-modified
   date for the resource is later than the given date.  [See here fore more
   information.](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/Using_XMLHttpRequest#Get_last_modified_date)
 * Create a member in the plugin for storing the list of dependencies of the
   current document.  Initialize it to an empty array.
 * Create a `import` member that takes an array of the following form.  It
   should store the data in the plugin object itself, giving it a `length`
   attribute, and attributes 0, 1, 2, ..., allowing it to act as an array
   with the same structure.  (Clear out old values before adding new ones.)
```javascript
    [
        {
            address : 'dependency URL here',
            data : /* exported data, as JSON */,
            date : /* time of last data update */,
        },
        /* ...one of these objects for each direct dependency... */
    ]
```
 * Document how applications should access dependency information.  They
   can write `tinymce.activeEditor.Dependencies[0].URL`, for example.  Note
   that it will be very common for the `data` member to also have a
   `dependencies` member, for access to indirect dependencies' data.  But
   this is not required, and must be handled by each application developer.
 * Create an `export` member that produces an array of the above form from
   the data stored in the plugin.
 * Create an `update` member that fetches the latest metadata for each
   dependency stored in the plugin iff its date is newer than the stored
   date.  When it does so, update the date to now.  Call this function at
   the end of `import`.
 * Create a `remove` member that takes an index into the dependencies array
   and does the following:
    * Remove that dependency.
    * Move the later ones down to earlier indices.
    * Fire a `dependenciesChanged` event in the editor.
 * Create an `add` member that takes a URL or filename of a dependency and
   does the following:
    * Attempt to fetch the latest data for that dependency.
    * If that fails, return the reason why as a string.
    * If it succeeds, append the dependency (with its data and the current
      timestamp) to the internal array of stored dependencies, as the new
      last entry.
    * Fire a `dependenciesChanged` event in the editor.
    * Return null.
 * Document the fact that the change event will be fired iff dependencies
   have changed, and that most applications will want to listen to that
   event.

UI

 * At line 280 of `main-app-solo.litcoffee`, add a section heading for
   dependencies.
 * Extend the UI functions in `settingsplugin.litcoffee` so that each takes
   an optional ID argument and uses it as the ID of the element created.
 * Extend the UI functions in `settingsplugin.litcoffee` with a function for
   creating buttons with a given text on them (and any ID).
 * Create a DIV beneath that heading and in it place two buttons, one for
   "Add file dependency" and one for "Add URL dependency".
 * When setting up that window, for every dependency in the
   `D.metadata.dependencies` array, create a table row above the buttons DIV
   showing the dependency URL, with a "Remove" button.
 * Test that by running code in the console (or elsewhere) to inject
   dependencies into a test document, and ensure that they show up.
 * Implement the "Remove" buttons to modify that dependency array, as well
   as its visual representation in the table.
 * Implement the "Add file dependency" feature to prompt the user to choose
   a file with the same dialog used for opening files.  If the user chooses
   a file, call the `add` member of the plugin.  If it returns a string,
   show the user that string as an explanation of failure.
 * Implement the "Add URL dependency" feature to prompt the user to paste in
   an URL.  Call the `add` member of the plugin.  If it returns a string,
   show the user that string as an explanation of failure.
 * Extend the "Add URL dependency" function with a "please wait" indicator
   while the document is being fetched.
 * Update the documentation in the Dependencies Plugin file, immediately
   before the class definition section, which promises to link to an example
   of how to show the dependency-editing UI.  Link to the example you just
   built.

Keeping up-to-date

 * Use the plugin's `import` function from within `loadMetadata` in the
   main app.
 * Use the plugin's `export` function from within `saveMetadata` in the
   main app.

## Parsing test

Create a Lurch Application that tests the following particular design for a
customizable parser.

 * Create a group type called "category name" that can hold any text.  Its
   tag will always contain the phrase "category name."
 * Create a group type called "category definition."
   * It has an attribute called "definition type" that can be selected with
     the bubble tag context menu, and is one of the following.
     * Built-in types
       * integers base 10
       * real numbers base 10
       * one letter a-z/A-Z
       * (more can be added to this list later)
     * Regular expression
     * Symbol
     * Pattern
   * Whichever of the above is chosen will be used as the bubble tag
     contents.
   * Choosing any of the options, if the bubble is empty, fills the bubble
     with example content for that definition type.  For built-in types, it
     fills the bubble with a human-readable description of the built-in.
 * Make "category name" groups able to connect by arrows to "category
   definition" groups or "category name" groups, but only up to one target.
 * Create a group type called "name" that can hold any text.
   * Permit it to connect to a "category definition" group, but only up to
     one target.
   * Permit "category type" groups to connect to "name" type groups also,
     but still at most one target.
   * Its tag will behave as follows.
     * If it is not connected to a target, the tag says "name."
     * If it has no category name connected to it, the tag says "operator
       name."
     * If it contains any commas or spaces, the tag says "variable names."
     * Otherwise, it says "variable name."
 * Create a group type called "test" that can hold any text.  Its tag always
   contains the phrase "test."
 * Create a method that computes, for any given "category definition" group,
   a simple representation of what function should be called in a parser
   object to extend it by adding that definition; the result should be JSON.
 * The `contentsChanged` handler for any given group in the document should
   call that function in itself (if it's a category definition group) or (if
   it's not) in any category definition group to which it's connected,
   storing the result as an attribute of the group on which it was called.
 * Create a function that applies any such JSON record of a command to a
   parser object, thus modifying that parser appropriately.
 * Whenever any definition type group in the document has its JSON meaning
   recomputed, loop through all category definition top-level groups in the
   document, doing the following.
   * Before the loop, create a parser P.
   * Upon encountering a category definition group *after* the one that
     changed, apply to it the function that extends P with the meaning of
     that group.
   * Upon encountering a test type group, run P on its contents and place
     the resulting structure within the test type group.
 * Whenever any test type group in the document changes, do the same loop as
   above, but the only test that should be recomputed is the one that
   changed.
 * Create a context menu item in test type groups that allows you to see, in
   a popup window, the parsed structure stored in that group.
 * Add a context menu item in test type groups that allows you to mark a
   test as currently passing.  This takes the currently parsed meaning of
   that group and stores it under a second key, the meaning that *ought* to
   be parsed by that group.  (For later comparison purposes, if input data
   changes, to prevent regression.)
 * Add a context menu item for removing such marks.
 * When writing to a test type group's meaning attribute (or to the
   attribute storing the meaning it ought to have), also mark it with a
   suffix that looks like one of the following.
   * If it has no data stored for what structure it ought to have, mark it
     with a gray question mark.  Hovering the question mark should explain
     this.
   * If the "what ought to be parsed" data matches the data we just parsed
     and are now storing, mark it with a green check box.  Hovering should,
     again, explain this.
   * Mark it with a red check box, and a corresponding hover explanation.

## Dropbox support

Add support for Dropbox open and save using their simple
[Chooser](https://www.dropbox.com/developers/chooser) and
[Saver](https://www.dropbox.com/developers/saver) interfaces.  I didn't used
to think this was possible because they could not accept uploads from Blob
URLs, but it's possible to [convert those to a data
URI](https://github.com/dropbox/dropbox-js/issues/144#issuecomment-32080661)
and Dropbox Saver will accept those.  Once you've done this, mark an answer
as accepted or not [here](http://stackoverflow.com/questions/26457316/can-dropbox-saver-accept-data-from-createobjecturl?noredirect=1#comment53719255_26457316).

## Google Drive support

Google Drive also provides a very nice [real time collaboration API](
https://developers.google.com/google-apps/realtime/overview) that makes any
document you like into a Google-Docs-like collaborative model where changes
are auto-synced across collaborators.  This was an idea that Dana Ernst
asked for long ago when he first heard about the webLurch project. Integrate
that into webLurch, imitating the UX Ken describes from typical online
collaboration apps such as Google Docs and Overleaf, as follows.
 * Just a note that none of the changes below impact the wiki import and
   export functionality; that stays as it is now.
 * Provide a section in the File > Application settings... dialog that will
   be for Google Drive authentication, but you don't have to put the Google
   login functionality there yet.  Include full explanatory text about how
   cloud saving works with webLurch (as described below).
 * File > Save and File > Save as... actions should be removed entirely.
 * Before adding Google Drive integration, change the items on the File menu
   to behave as follows.
   * Whenever the document is dirty, it has a warning message on the toolbar
     that says something like "Not saved" followed by a button that says
     "Enable cloud storage."
   * The "Go online" button will open the document preferences dialog and
     scroll down to/highlight the section about logging into Google Drive.
   * File > Document properties... will let you change the name of the
     document which will simply be stored as document metadata; it will have
     no impact on filename, since there is no filename (yet).
   * Corresponding changes take place in the toolbar.
   * Add File > Download, which starts a download of the file as HTML.
   * Add File > Upload, which lets the user choose an HTML file to upload,
     accepts the upload, strips any dangerous tags from it, then does the
     same thing as File > New, above, before pasting the HTML content
     directly into the new, blank document.
 * Add to the application settings section about Google Drive the actual
   login/auth button.  Once a user has logged in, the button becomes a
   disconnect-from-my-Drive button (de-auth).  See the tutorial on how to
   do so [here](
   https://developers.google.com/google-apps/realtime/realtime-quickstart),
   and especially the JavaScript tools they've developed for your use
   [here](https://github.com/googledrive/realtime-utils/blob/master/realtime-client-utils.js).
 * When a user gives such authorization, the following changes take place:
   * The currently-open file in the app should then be moved into Google
     Drive as a new document.  Attempt to preserve document title, if one
     was set in document properties.  If Drive requires unique titles, you
     may need to append a number.
   * Change File > New so that it does this same procedure of moving the
     (newly created) document into Drive, with a default title such as
     "Untitled Document."
   * The toolbar will no longer say "Not saved," but will say either
     "Saved to Drive" or "Syncing..." (if in progress).
   * File > Open looks in your Google Drive for Lurch files to open, and
     presents you a flat list.  If possible, sort it by most recently used.
   * File > Manage files... gets replaced by File > Open my Google Drive.
     All file management will take place through Google's UI, not mine.
 * If a user de-authorizes webLurch from their Google Drive, then all
   entries on the File menu should revert to their original behavior.
 * Get this to work across multiple instances of the Lurch app in different
   tabs as follows.
   * Store in Local Storage the fact that the user has given a Drive login
     and succeeded, when that login takes place.
   * Have the app poll that setting every second or two, and if it sees that
     it has changed from no to yes (due to the user's logging into Drive in
     another tab of the app), then re-run the silent Google login attempt
     routine to complete the login in that tab as well.  (I think?)

## Tutorials

 * Create a way for users to navigate the pages of a tutorial.  Probably the
   easiest and most flexible way to do this is to make it so that one of a
   document's settings is whether clicking links in it navigates to them.
   (Right now it just puts the cursor in them.)  Enabling such a setting
   then allows the document author full freedom to format the tutorial
   pages however they like, with next/previous/other links wherever they
   want them, looking however they want them to look.
 * Make it so that following such links first prompts you with an "Are you
   sure?" dialog, so that you can save first or optionally open the link in
   a new tab.
 * Make links with protocol "load://" fetch their results from the wiki
   using AJAX and load them in the current editor, again after prompting
   with an "Are you sure?" dialog.
 * Now you can create an number of tutorials by simply publishing all the
   pages to the wiki, and having them link to one another in whatever
   configuration you want (linear or otherwise).
 * Create an initial Lurch tutorial and post it to the wiki.
 * Create a Help menu item that loads that tutorial.
 * When Lurch launches, pop up a dialog saying that there is a tutorial on
   the Help menu, and they can check the "Don't show again" box if they so
   desire.

## Offline support

To make an HTML5 app available offline, I believe the appropriate step is
simply to provide an app manifest.  I'm verifying that with [this
StackOverflow
question](http://stackoverflow.com/questions/27136144/how-can-online-offline-versions-of-an-html5-app-access-the-same-localstorage).
That question links to a tutorial on app manifests, if the answer turns out
to be "yes" to that question.

## Ideas from various sources

### All images consistently base64

[This GitHub comment](
https://github.com/buddyexpress/bdesk_photo/issues/2#issuecomment-166245603)
might be useful for ensuring that even images pasted into a document get
converted to base64, as all the other images in the document are.

### LMS integration

Suggestion from Dana Ernst: Perhaps this is not necessary or feasible, but
if you go with a web app, could you make it easy for teachers to "plug into"
the common LMS's (e.g. Blackboard, Canvas, etc.)?  I'm envisioning students
being able to submit assignments with ease to an LMS and then teachers can
grade and enter grades easily without have to go back and forth between web
pages.

### Further wiki integration?

Is it possible for the entire Lurch app to exist inside MediaWiki, so that
editing a wiki page was done using Lurch as the editor?  That would be
excellent for many use cases.  Offline use would still necessitate the
normal app, and this would be tricky to accomplish, because wiki integration
of something that complex will be touchy, but it would be impressive and
intuitive.

### Desktop app

Convert webLurch into a desktop app using
[electron](https://github.com/atom/electron).
This gives the user an app that always works offline, has an icon in their
Applications folder/Start menu, etc., and feels like an official app that
they can alt-tab to, etc., but it’s the exact same web app, just wrapped in
a thin desktop-app shell.  You can then add features to that as time
permits.
 * When the user clicks "save," you can have the web app first query to see
   if it’s sitting in a desktop-app wrapper, and if so, don’t save to
   webstorage, but pop up the usual save box.
 * Same for File > Open.
 * Same for accessing the system clipboard
Similar apps could be created for iOS, Android, etc., but would need to use
tools other than Electron.  These are orthogonal tasks, and need not all be
done by the same developer.

## Repository organization

 * The `app/` folder is getting cluttered.  Create an `app/examples/`
   subfolder and move every `*-example.html` and `*-example-solo.litcoffee`
   into it.  Update any relative links to other resources, and any links to
   those pages.
    * This requires also updating the `cake.litcoffee` to compile files in
      that subfolder as well.
    * It also requires taking care with the `gh-pages` merge, so that
      compiled files get deleted/recreated correctly in that branch (once).

## Improving documentation

Documentation at the top of most unit test spec files is incomplete. Add
documentation so that someone who does not know how to read a test spec file
could learn it from that documentation.  Probably the best way to do this is
to add general documentation to the simplest/main test spec, and then
reference that general documentation from all other test specs.
