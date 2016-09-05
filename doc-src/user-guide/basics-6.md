
# Basics, Part 6: Connecting Dependencies

## Saving a document for use as a dependency

Before you can tell Lurch about a library you want to use as a dependency in
a document, you must have the library somewhere you can access it.  Lurch
supports (for now) two locations where you can store libraries.

 * the local storage filesystem in your browser (which we learned about in
   [the first part of this tutorial](basics-1.md))
 * a global wiki of Lurch documents (which is not yet publicly available,
   but will become so as the project matures)

Therefore we will do an example in which you store a library in your
browser's local storage, and import it into another document from there.
If you're using Dropbox for storage, temporarily switch over to using your
browser's local storage, as described in
[the first part of this tutorial](basics-1.md).

I'll provide you a document to save.  Here it is.  Use the File menu in this
embedded Lurch app to save the document under any name you choose, such as
"example library.lurch".

<div class='lurch-embed'><shorthand>
<p>This document defines one rule, using JavaScript.</p>
<p>Don't worry about the code for now; you just have to save the file!</p>
<p>This silly rule judges everything to be valid.
   We'll name it <e at='label' to='1'>enthusiasm</e>.</p>
<p><e n='1'><e at='rule'>yes</e><e at='code'>JavaScript</e>return { result : 'valid', message : 'Heck yeah!' }</e></p>
</shorthand></div>

## Citing a library from a document

Once you've saved the above document, you can then import it into another
document.  Try following these steps:

 1. In the same embedded Lurch window, above, choose File, then New.
 1. In the new document, choose File, then Document Settings.
 1. Click the button to add a file dependency.
 1. Choose the file you just saved, with the enthusiasm rule in it.
 1. Click Save to store those settings in the document.
 1. Write any expression in the new, empty document.
 1. Apply to it a reason whose contents are "enthusiasm" (lower case, no
    quotation marks).

You should see the step judged correct, and if you hover your mouse over the
green check mark, Lurch should give you an enthusiastic affirmation of your
work.
