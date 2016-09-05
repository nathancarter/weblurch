
# Basics, Part 5: Rules in Dependencies

In [the previous part](basics-4.md), we saw how to apply a rule to a step of
work, but it was unsatisfying because we didn't have access to any rules!

The most common way to access rules is by telling Lurch that the document
you're working on wants to use a set of rules contained in another
document (often one written by an instructor).  Doing so does not change
the appearance of your document at all, but invisibly imports those rules so
that you can use them.

In such a situation, the imported document is a *dependency* of the current
document.  Documents can have zero or more dependencies.  The dependency is
also sometimes called a *library,* because it contains a set of rules that
users want to reference.

In the document below, a dependency has been invisibly imported for you.
It contains just one rule, called "EE" that judges a step of work
correct if it contains two E's in a row.  For example, "peek" would be
correct, but "poke" would not.

Try applying the "EE" rule to the two expressions in the document.  Be sure
to correctly capitalize the rule name.

<div class='lurch-embed'><shorthand>
<dependency>
  <e n='1'>var valid = /ee/i.test( conclusion.value );
  var verb = valid ? 'contains' : 'does not contain';
  return {
    result : valid ? 'valid' : 'invalid',
    message : 'The expression ' + verb + ' two successive E\'s.'
  }</e>
  <e at='label' to='1'>EE</e>
  <e at='rule' to='1'>yes</e>
  <e at='code' to='1'>JavaScript</e>
</dependency>
<p>Justify both of these with the EE rule:</p>
<ul>
  <li><e>peek</e></li>
  <li><e>poke</e></li>
</ul>
</shorthand></div>
