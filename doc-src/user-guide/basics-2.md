
# Basics, Part 2: Expressions and canonical form

## What's an expression?

A section of text in a Lurch document can be marked as an *expression.*
Lurch pays attention to the content of expressions, trying to interpret them
as meaningful mathematics (perhaps an algebraic equation, or a statement
from logic or analysis, or perhaps the name of a theorem being cited, for
example).

## Inserting expressions

You can create expressions in your document in any of the following ways.

 * Click the "expression" toolbar button to insert an empty expression at
   the cursor, then begin typing to fill it in.  The toolbar button looks
   like this:  <font color='#996666'>[ ]</font>
 * Use the "expression" keyboard shortcut (Ctrl+[ on PCs, or Cmd+[ on Macs,
   which behaves exactly like the "expression" toolbar button) to insert an
   empty expression, then type.
 * Use a LaTeX-like keyboard shortcut (such as `\[` followed by the
   spacebar) to open a new expression, with the cursor placed immediately
   inside.
 * Select the section of the document (usually very short) that the user
   wishes to convert into an expression, then click the "expression"
   toolbar button so that the software will then begin treating the
   selection as an expression.
 * Same as the previous, except using the keyboard shortcut instead of the
   toolbar button.
 * Expression boundaries can be dragged using the mouse.  This is useful
   when you have formed an expression, but then find that it should have
   enclosed a bit more or less text.  Especially if you have
   decorated/attributed the expression (as described later in this User
   Guide) and do not wish to repeat that work.  Dragging an expression's
   boundaries in a way that creates invalid nesting (one boundary inside
   another expression, the other not) will result in removal of the
   offending expression.

## Canonical form

A few quick foundational definitions:

 1. An *atomic expression* is one with no other expressions inside it.
 1. A *compound expression* is one with at least one expression inside it.
 1. Content not inside an atomic expression is informally called *flarf,*
    to signify its lack of importance:
 1. The *cannoical form* of an expression is obtained by deleting all flarf.

Here are some examples of these definitions.

<div class='lurch-embed'><shorthand>
<p>Example atomic expression: <e>Hello.</e>  (Click to place your cursor
    inside it to see the bubble UI appear around it.  Bubbles are shown to
    highlight expressions only when your cursor is inside them.)</p>
<p>Example compound expression: <e><e>an inner expression</e>
    <e>another inner expression</e></e>  (Try placing your cursor at various
    spots within the inner and outer expressions.)</p>
<p>This text is flarf.
    <e>So is this text, <e>but this is not flarf.</e></e></p>
<p>The canonical form of the expression in the previous paragraph
    is therefore <e><e>but this is not flarf.</e></e></p>
</shorthand></div>
