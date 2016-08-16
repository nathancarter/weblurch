
# Part 3, Connections and attributes

## Attributes

Each expression has a set of attributes, which is a list of key-value pairs.
By default, each expressions set of attributes is empty.

To use one expression as an expression for another, you must connect the
attribute to its target with an arrow.  Do so as follows.

 1. Place your cursor in the expression that will become an attribute.
 1. Click the connections button on the toolbar (with the &#x2197; icon).
 1. Click to place your cursor in the target expression.

See the examples below.

<div class='lurch-embed'><shorthand>
<p>A connection has been created for you here:</p>
<p>From this <e to='1' at='label'>source</e>
    to this <e n='1'>target</e>.</p>
<p>Place your cursor in either expression to see the connection.</p>
<p>Now try it yourself.  Form a connection here:</p>
<p><e>Make this the source,</e> and <e>make this the target</e>.</p>
</shorthand></div>

## Keys

In the examples above, all the attributes have the word "label" on their
arrows.  That is the *key* for the attribute, and the source expression is
the attribute's *value.*  So for example, the "target" expression has an
attribute with key "label" and value "source."

You can change this in a few ways.

 * To change where the key is shown:
    * Right-click the attribute expression and choose:
      Move "label" onto attribute.  This will move the word "label" from the
      arrow onto the top of the attribute bubble itself.
    * To undo that action, right-click again and choose to move it back, or
      click the word "label" where it sits on top of the attribute bubble.
 * To change the key:
    * If the key is shown on the arrow, right-click the expression and
      choose: Change attribute key to...
    * If the key is shown on top of the attribute bubble, click it and make
      the same choice.

Try each of these methods in the example Lurch document above.

## Attributes summary

You can hide an attribute inside the expression it modifies.  Right-click
the attribute and choose "Hide this attribute."

To reveal an attribute, right-click the expression into which it was hidden,
and choose "Attributes..."  A dialog will appear listing all attributes of
the expression, both hidden and visible.  You can hide/show them, edit the
keys, edit the values of any atomic attribute values, delete attributes, and
add new ones from that dialog.

Here is an example of a single target with many attributes attached to it.
Right-click the target and ask to see its attributes summary.  (Notice the
one hidden attribute!)

<div class='lurch-embed'><shorthand>
<p>Target expression:</p>
<ul><li><e n='1'>Abraham Lincoln<e at='party'>Whig</e></e></li></ul>
<p>Some attributes attached to it:</p>
<ul>
    <li><e at='gender' to='1'>male</e></li>
    <li><e at='occupation' to='1'>lawyer</e></li>
    <li><e at='occupation' to='1'>state representative</e></li>
    <li><e at='occupation' to='1'>president</e></li>
</ul>
</shorthand></div>
