
# Technicalities, Part 2: Code-based Rules

A code-based rule is an atomic expression in the document containing code
that can evaluate steps of a user's work, and return data about the validity
of that step of work (including not only whether the step is valid, but also
an explanation to the user about why).

## Writing a code-based rule

To write a code-based rule, follow these steps.

 1. Create an atomic expression that will contain the code.
 1. Give it an attribute with key "code" and with value "JavaScript",
    as in the previous page of this User Guide.
 1. Give it an attribute with key "rule" and with any value, such as "yes".
 1. Give it a label, so that users can cite it.  For instance, if your rule
    will judge simple statements of arithmetic, you might label your rule
    "simple arithmetic", so that users can say that a step of their work is
    true by simple arithmetic.
 1. Write code that will be used as the body of a function.  The function
    takes two parameters, `conclusion` and `premises`.  The first is an
    OpenMath structure about the expression to be judged.  The second is an
    array of such structures, for each cited premise.  Your code should
    return an object with two members:
     * `result` - a string, one of "valid", "invalid", or "intermediate"
     * `message` - a string, a short message to show to users who hover over
       the validation icon

## Example

Here is a code-based rule that judges whether an atomic expression contains
the letter x.  If so, it calls that expression valid; if not, then invalid.
(Surely, this rule is useless, except as a simple example.)

<div class='lurch-embed'><shorthand>
<p>I'll call this the <e at='label' to='1'>X rule</e>:</p>
<p><e n='1'><e at='code'>javascript</e><e at='rule'>yes</e>var hasX =
    /x/i.test( conclusion.value );<br>
return {<br>
&emsp;result : hasX ? 'valid' : 'invalid',<br>
&emsp;message : hasX ? 'This contains an X.' : 'This contains no X.'<br>
};</p>
<p>Now let's try using the rule, once correctly, and once incorrectly.</p>
<p>I think that <e n='2'>excellent</e> should be marked valid
    and <e n='3'>awesome</e> should be marked invalid by the
    <e at='reason' to='2,3'>X rule</e>.</p>
</shorthand></div>

## Editing and debugging

If you edit the document, the validation results should update in real time
in response to your edits.  For instance, if you change the rule citation
to "Y rule", both expressions citing it should be marked invalid because
there is no such rule.  You can even edit the code of the rule; if it is in
a syntactically invalid state, anything citing it will be marked invalid,
with an internal rule error as the explanation.

When writing the code for a rule, don't forget that you can right-click the
rule and choose "Edit as code" to use an editor with syntax highlighting.
Rules are evaluated in a separate thread without access to the DOM or the
browser window, so you cannot harm the Lurch application itself.  But you
can use the `console.log` command to dump data to the console and inspect
its structure.

The conclusion and premise objects are both instances of the `OMNode` class
defined in [this source code
file](https://github.com/nathancarter/weblurch/blob/master/src/openmath-duo.litcoffee).
Documentation on the class is included in the source code itself.
