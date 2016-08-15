
# Part 4, Code attributes

<font color='red'>Most authors do not need code attributes for any portion
of their work. Unless you plan to write very unusual logical systems within
Lurch, you can skip to the next part of the User Guide.</font>

## Creating code attributes

To tell Lurch that an atomic expression contains computer code, give it an
attribute with key "code" and whose value is the language in which the code
is written.  The only language supported at present is JavaScript.

Example:

<div class='lurch-embed'><shorthand>
<p>The code <e n='1'>console.log( "Hello!" );</e>
is valid <e at='code' to='1'>javascript</e>.</p>
</shorthand></div>

## Editing code

When you right-click an expression that has a code attribute, one of the
choices on the context menu is "Edit as code."  Choosing it launches a code
editor, and any changes you make can be saved or discarded.  Saving them
updates the expression in the document with the new contents of the editor.

Try it now in the example above.

Suppose you were to mark an expression as code by attaching a code attribute
to it, then used the expression itself as an attribute to yet another
expression, and finally hid the code expression within that final
expression.  If you examined the attributes summary dialog for that final
expression, you would find an edit link next to the hidden code that would
let you launch the same code-editing dialog directly from there.
