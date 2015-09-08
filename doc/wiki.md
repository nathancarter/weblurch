
# Learning how to integrate a wiki into webLurch

Note that [plan.md](plan.md) has details on the goals, but this document is
a scratch pad in which I will dump immediate next steps, during the early
stages of experimenting with MediaWiki to learn its capabilities.

## To-dos

 * Make it so that when a user attempts to edit a page, if it is a Lurch
   document, they are alerted that they should probably not tamper with
   its source directly in the wiki, but edit it in Lurch instead.  (See
   Common.js information in notes at end of this file.)

## Updating the UI

 * Create a TinyMCE plugin for showing arbitrary dialogs, including things
   like a message box, an alert box, a prompt, a confirm, etc., all with
   callbacks, all that use the same TinyMCE dialog style.
 * Remove from the [XML Groups module](../app/xml-groups.solo.litcoffee) the
   `showHTMLPopup()` function, calling the plugin's version instead.
 * Make all the alert boxes in the main app use this new feature.  In
   particular, the alert that you can now visit your newly published wiki
   page should just have a link in it, so that the browser does not perceive
   the navigation as a popup, and therefore permits it.

## Additional notes

I like [Article Protection](
https://www.mediawiki.org/wiki/Extension:ArticleProtection), but if that
ever becomes insufficient, there's always [Improved Access Control](
https://www.mediawiki.org/wiki/Extension:Improved_Access_Control), which I
did not test, but also looked good.  It seems to allow each user to define
their own groups and then assign per-page permissions for reading and/or
editing based on those groups.  It therefore seems to be more flexible, but
also has some downsides, including requiring greater savvy on the part of
the user, and requiring changes to the code of the protected page (which
will not work so well with pages that contain fragile Lurch code).

The MediaWiki API is documented
[here](https://www.mediawiki.org/wiki/API:Main_page).
JavaScript XHRs are documented
[here](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest)
with examples
[here](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/Using_XMLHttpRequest).

MediaWiki's ArticleProtection extension had the limitation that it does not
protect against edits made through the MediaWiki API (which is the primary
means by which we'll be making edits, using Lurch).  Therefore I enhanced
the extension to support this, and submitted [a pull request on GitHub](
https://github.com/nischayn22/ArticleProtection/issues/1).  We will see if
the author chooses to merge it.  If not, I'll just have to for the
repository, make my changes there, and use that extension.  If I do that, I
should add a lot of comments to the PHP code, since there are virtually none
and the code is therefore confusing as is.

The webLurch application now examines the query string on launch, and if it
finds ?wikipage=<anything>, it loads the MediaWiki page in question into the
editor.  (Later we may want to first insert "Loading..." or some such text
into the editor, to inform the user what's going on in case there is a
delay.)  It also has a File > Import from wiki... menu item, which at the
moment does not check to see if your file is dirty; it just overwrites, so
that's obviously an alpha version.  (But it does load correctly from the
wiki.)

You can add JavaScript to all MediaWiki pages by editing the special page
entitled MediaWiki:Common.js.  Same for CSS, in MediaWiki:Common.css.

I had to make two changes to the HTMLTags extension of MediaWiki.  One is
documented [in this pull
request](https://github.com/wikimedia/mediawiki-extensions-HTMLTags/pull/1).
The other is the loop in lines 17-19 of the code on my computer at present,
which installs htmltag0...htmltag50 rather than just htmltag as the tags
handled by that extensions.  This is to get around a bug in MediaWiki, which
parses nested tags of the same type incorrectly.
