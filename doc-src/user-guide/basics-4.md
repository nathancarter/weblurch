
# Basics, Part 4: Steps and Reasons

## The purpose of Lurch

Lurch's purpose is that if users type mathematical reasoning into a
document, the software should be able to check that reasoning, giving
immediate and helpful feedback about correct and incorrect steps.

The primary way this happens is that users tell Lurch the reason for each
step of work they do, and Lurch looks up the reason and checks to see
whether it justifies the step of work, as the user claims it does.  Lurch
appends an icon to the end of the step of work to show the results of
validation (<font color=green>&#10003;</font> for correct,
<font color=red>&#10006;</font> for incorrect).  Users can hover their
mouse over the icon to get more feedback.

## How to create a step of work

It's a bit early to discuss how to write a step of work, since this User
Guide has not yet covered even how to write a mathematical expression in
Lurch!  But for now, let's pretend that Lurch understands ordinary
mathematical notation, including symbols like + and = and so on.

 1. Write an expression that contains the step of work.
    For instance, in a proof, you might write, "And so we see that x+1=5."
    You would mark the x+1=5 as an expression.
 1. Specify your reason as a "reason" attribute.  That is, create a new
    expression, attach it as an attribute to the first, and change it from
    being a label to being a reason.

Here is an example.  Because there is no Theorem 6.1 defined here, Lurch
marks the step of work invalid, but that's good -- validation is happening,
and correctly!

<div class='lurch-embed'><shorthand>
<p>Let's pretend we're part way through a proof or computation.</p>
<p>...And so we can clearly see that <e n='1'>x+1=5</e>,
    by applying <e at='reason' to='1'>Theorem 6.1</e>.</p>
<p>Place your cursor in either expression to see the connection.</p>
</shorthand></div>

## Where do reasons come from?

The step of work in the example above was marked invalid because there is no
Theorem 6.1, but the user cited it as a reason as if there were.  Anything
you can cite as a reason we call a *rule.*  This includes mathematical
theorems, axioms from a particular mathematical field, and rules of logic.

In order for a rule to be usable, it must exist either

 1. in the same document as where it's used, earlier than those steps which
    use it, or
 1. in a separate document that the current document cites as a source of
    rules it wants to use.

In later parts of the User Guide, we'll see how to define our own rules in
our documents, and how to import other documents (as "dependencies") so that
we can access the rules in them.
