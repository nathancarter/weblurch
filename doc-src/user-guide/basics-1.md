
# Basics, Part 1: The editor

The WYSIWYG word processor on which Lurch is built is
[TinyMCE](http://www.tinymce.com).  It is extremely straightforward to use,
and little documentation is required.  There are a few extensions to the
standard configuration that Lurch adds, and those are documented on this
page.

## Saving and loading files

You can save your work (and load it again, of course) in one of two ways.

### Dropbox

By default, the Open and Save items on the File menu expect to connect to
your [Dropbox](http://www.dropbox.com) account.  You will be asked for
permission to let Lurch access your Dropbox the first time you attempt to
open or save a file.  There are advantages and disadvantages to this method:

 1. Storage in the cloud is convenient, and accessible from various
    devices.
 1. The data is automatically backed up by Dropbox on their end.
 1. However, this requires you to have a Dropbox account and connect Lurch
    to it.
 1. Also, our support for Dropbox saving is currently minimal, and will
    save under a new filename each time.  This is to be fixed in the future.

### Local storage

You can use the Application Settings item on the File menu to switch Lurch
to use your browser's "local storage" as a file storage area, instead of
Dropbopx.

As long as you continue to use the same browser from the same account on the
same computer, any files you save will continue to be accessible to you.
Even if you log out or reboot the computer, the files are kept, for the next
time you use Lurch in that browser on that account.

If you use a different browser, account, or computer, you will not see the
same files.  They continue to exist in the old browser, even across reboots
or logins on the computer, but the new browser or computer cannot see them.

The Manage Files item on the File menu lets you reorganize files into
folders, within the small filesystem kept in your browser.

## Entering mathematics

There is a button on the toolbar labeled `f(x)`, which allows you to insert
and edit WYSIWYG mathematics.  It uses [MathQuill](http://mathquill.com/) as
its editor.  The interface is very self-explanatory.

To edit a mathematical expression you've already inserted, double-click it,
and the editor will re-open.

To delete a piece of typeset mathematics, simply backspace over it as you
would any other piece of content, or highlight it and press delete.
