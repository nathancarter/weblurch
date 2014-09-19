
# Word Processing Specification

## Purpose: What is this document?

This document explains the overall plan for building a word
processor inside a webpage.

I confess that I have already begun doing this, and so it is a
little bit late to begin writing this document! But, in my
defense, I will say two things. I did actually have a plan when I
began, but as the project unfolded, it became clear that my plan
needed improving; this document is the improved version of the
plan. Secondly, I am of the opinion that one cannot perfectly
plan a large project entirely beforehand; at some point you have
to just get your hands dirty and find out the nitty-gritty
details by so doing, thereby enabling you to return to the
planning stage, more informed. 

The specific way in which I am now more informed to write this
document is as follows. I had originally assumed that the
application would designate some specific portion of the webpage
to be used for word processing, and the document consisted of
precisely those HTML elements that appeared inside that area. A
simple plan. But HTML documents support a truly enormous range of
features, while word processors, in general, do not. There are
many aspects of a webpage that you would not want to show up
inside your document, including forms, videos, drop-down menus,
and similar items. Having such items inside an editable region of
the webpage would tend to confuse the user, because they do not
fit the user's expectations for word processing. 

My realization of these facts came from trying to design a
consistent way to place and move the cursor. But that specific
problem was just a narrow symptom of a larger disease. This new
and improved plan aims to be a cure for that disease. 

## Inspiration: Not re-inventing the wheel

The good news is that I do not need to create my own plan for
structuring the implementation of a word processor in a webpage.
For the past several years, I have been part of the development
of the desktop version of *Lurch,* and therefore have seen
firsthand the internal workings of a word processor, specifically
[QTextDocument](http://qt-project.org/doc/qt-5/qtextdocument.html)
from [the Qt project](http://qt-project.org/).  And it's not just
any word processor, but it was one created by a team of talented
open-source software developers, and tested in many open source
projects, including *Lurch*. Thus we know that its design meets
all of our needs, because we are using it in the desktop version
of *Lurch* already. 

## Specification: How our documents will be structured

Here I repeat the general structure of a QTextDocument, and make
particular comments about how this connects to HTML documents,
thereby suggesting the new implementation of this design in a
webpage.  The reader should see the following bulleted list as a
*restriction;* I hereby declare that the *Lurch* word processor,
when built in a web page, will permit only documents that adhere
to the following structure.

 * _Text_ - the smallest unit of a document
    * Text is simply an ordinary string of Unicode characters.
    * In its simplest form, it is unformatted (an HTML Text
      node), but it may have formats and styles attached as well
      (an HTML SPAN element with one Text node child).
    * (We may need to add here the special case of the `<BR>` tag
      as an individual character, or maybe not, because `&#10;` is
      line feed, and may work just as well.)
    * In Qt, this was a
      [QTextFragment](http://qt-project.org/doc/qt-5/qtextfragment.html),
      but in HTML it would either be text without a tag, or text inside
      a SPAN to style it.
    * Examples:
       * In `<p>Hello</p>`, the paragraph has one child, a plain
         text node.
       * In `<span style="font-style: italic;">one</span> two`,
         there are two text nodes, the first one inside a SPAN
         that gives it style; the second one outside the SPAN.
       * I will add "smart characters" to the list of valid Text
         objects, in the next section.
 * _Block_ - a paragraph-like object that serves to word-wrap a
   sequence of Texts
    * A Block is for containing a list of Text objects and
      presenting them word-wrapped.
    * A paragraph (P element) is the simplest and most common
      example of a Block, but a list item (LI in HTML) is also a
      Block.  For now, we will assume that these are the only two
      tags permitted as Blocks, but this specification can be
      extended later.
    * Blocks cannot contain other blocks; they can only contain
      Texts.
    * Blocks are named after the Qt object
      [QTextBlock](http://qt-project.org/doc/qt-5/qtextblock.html).
 * _Frame_ - a higher-level structure that contains and lays out
   an array of Blocks
    * A Frame is for containing a list of Blocks and/or Frames,
      and it presents them in a way that depends on what type of
      Frame it is; see examples below.
    * Frames can contain a mix of Blocks and Frames, but cannot
      directly contain Texts.
    * For now, we will only permit DIV, OL, and UL elements as
      Frames; see the examples below.
    * It is named after
      [QTextFrame](http://qt-project.org/doc/qt-5/qtextframe.html),
      and *not* after HTML frames.  Although there is some
      potential name confusion there, HTML frames are so uncommon
      in modern websites that I suspect the ambiguity is not a
      big deal.  It also helps me stay consistent with my
      borrowing of the Qt class names.
    * Examples:
       * The entire word processing document, as a sequence of
         paragraphs, will be a Frame.  It will lay out its
         contents vertically, in order.
       * A list (either an OL or UL element) will be a Frame that
         will contain only LI-type blocks, and will lay them out
         vertically as well.
       * Desktop *Lurch* does not currently support tables, and the
         first version of web *Lurch* probably will not either, for
         simplicity, but if/when tables are added, they will be
         constructed of nested Frames (the table body, rows, and
         cells) that are nested in that order (body contains
         rows, which contains cells) and which contain Blocks as
         children of the cells only.  Their layout is complex to
         describe, but familiar to anyone who has used an HTML
         table.

Consider the following HTML as an example.

    # html
    <div>
        <p>Dear Jim,</p>
        <p>I'm writing to create...drum roll...<span style="font-style: italic;">a new Lurch specification!!</span>  Here's why:</p>
        <ol>
            <li>The current one has troubles.</li>
            <li>There is a great source of inspiration available from our desktop app.</li>
            <li>And so on.</li>
        </ol>
    </div>

Its structure is as follows:
 * The document itself, represented by the outermost DIV, is a
   Frame.
    * The first paragraph is a Block.
       * It contains the Text node "Dear Jim," and nothing else.
    * The second paragraph is a Block.  It contains three Texts:
       * "I'm writing to create...drum roll..."
       * "a new Lurch specification!!" with the italic style
         applied to it
       * "  Here's why:"
    * The third piece of the document is not a Block, but another
      Frame, the OL element.  It contains three children, each a
      Block with one Text in it:
       * Block containing "The current one has troubles."
       * Block containing "There is a great source of inspiration
         available from our desktop app."
       * Block containing "And so on."

## Extensions: Smart characters

In order for the web app to support all of the same content as
the desktop app, we must note one additional feature that is
required. The nickname that we gave to it in the desktop app was
"smart characters," because each instance of this feature in the
document behaved as if it were a single character of text, but
had additional features. For instance, an image, no matter how
large, is a single, indivisible item, just like one character of
text (though usually much bigger). Another very important example
includes the opening and closing groupers around bubbles. The
most recent example of a smart character is a little piece of
typeset mathematics; they provide the special feature that when
the user clicks on them or moves their cursor into them, they
become editable. Supporting these smart characters in the web
version of the app requires adding them to the specification, as
follows.

We permit all of the following types of HTML content to appear in
our document, in addition to the types given above. Each of the
types below counts as an object in the Text category, and should
be treated as if it were exactly one character in length.
 * an IMG tag
 * a SPAN element with the class "lurch-char"
    * Example: `<SPAN class="lurch-char"><IMG
      src="open-ME-grouper.png"/><SPAN style="display:
      none;">[meaning data here]</SPAN></SPAN>`
    * The entire example would be treated as a single character,
      so that the cursor can move over it in one step.
    * In this particular example, the open grouper would be seen,
      but the internal SPAN is marked with a style that makes it
      invisible. Of course, the software can still deal with its
      contents, and read/write to them as needed for, e.g.,
      validation.
    * Although this example stores meaning data in an invisible
      internal SPAN element, another viable place to store such
      data might be in [user-data
      attributes](http://www.w3schools.com/tags/att_global_data.asp)
      on the outer SPAN element, e.g., `<SPAN class="lurch-char"
      data-meaning="[data here]">...</SPAN>`.

Note that the examples immediately above are the *only* situation
in which nested SPAN tags will appear. Ordinary Text objects in a
Block will never nest SPAN elements. Only smart characters are
permitted to do so.

## Restrictions: General principles

When we built the desktop app, we did not need to worry about
documents deviating from this structure. It was the only
structure possible, because the word processor we were using, a
[QTextEdit](http://qt-project.org/doc/qt-5/qtextedit.html),
provided only these types of document elements. There simply was
no other option. 

On the web, however, there are two ways that content can get
placed inside of one of our word processing documents, as it sits
in a webpage. First, the content may be added by JavaScript code
from within our app. Second, it may be added by JavaScript code
written by someone else. (This latter case may include script code
in the webpage that contains the *Lurch* word processor, or script
code that someone simply executes from the browser's developer
console directly.) We handle these two cases separately.

To handle the first case, we just ensure that the software we
build preserves the restrictions above. If the initial state of
the document satisfies the above restrictions, and all editing
operations we give the user access to preserve these
restrictions, then the document will always satisfy these
restrictions. This will require careful development and testing
of our own code, but is manageable. I will discuss this more
below. Here I will just mention that a valid initial document is
simply the full-document Frame with one Block inside, as in
`<div><p></p></div>`.

To handle the second case, we simply don't handle it. Even in the
current desktop version of the software, there are ways that the
user can mess the software up. The most obvious of these is to
enable the developer console, open it directly, and execute
arbitrary script code in any of their documents. However, we have
always said that a user who does that is taking their own risks,
and our software does not need to protect the user's document
against such behavior; it would be impossible anyway. This is a
similar case. If you use your browser's JavaScript console or some
other means to inject invalid data into your document, the
behavior of our app becomes undefined. Do not do that.

## Cursor: Where can it be positioned?

Word processor users expect the following behavior for the cursor.
 * The cursor can be placed before or after any character in the
   document. This includes smart characters, which we treat as
   single characters of text.
 * The cursor can only be placed within Blocks.  (Technically,
   the cursor may be in a SPAN inside a Block, but this counts as
   inside the Block, because if any type of insertion were needed
   at that point that couldn't go inside the SPAN, it is trivial
   to split the SPAN before doing the insertion.  For simplicity
   from here on out, I will therefore treat the cursor as if it
   is always immediately inside a Block.  This occurs, for
   instance, in the "Applying a text style" case, in the
   [Editing](#editing-how-we-keep-the-structural-rules) section,
   below.)
 * Every valid cursor position gives the user a distinct visual
   appearance.
    * Most of the time, this simply means that two different
      cursor positions are at different locations on screen.
    * However, sometimes two distinct cursor locations are at the
      same position (e.g., immediately inside/outside a bubble in
      desktop *Lurch,* or immediately inside/outside an Equation
      Editor instance in Microsoft *Word*). In those cases, the
      visual distinction is created by the presence/absence of
      the bubble on screen.

To support these user expectations, I now list all types of valid
cursor positions.

Every Block contains an easily-computable number of text
characters.
 * Unformatted text contains a number of characters equal to its
   length.
 * Formatted text is treated exactly the same way; the SPAN tags
   that surround it are irrelevant for computing the number of
   characters in it.
 * Smart characters, which count as text, count for one
   character.

The total number of characters in a Block is computed simply by summing the number of characters in all the Text objects inside the block.

The number of cursor positions in a Block is one more than its
number of characters, and they are the interstices between those
characters, including one position at the Block start and one at
the Block end. There are no cursor positions outside Blocks.

When a cursor falls on the boundary of a formatted Text object,
it leans leftward; that is, if the formatted text is to the right
of the cursor, the cursor will *not* be inside it, but if the
formatted text is to the left of the cursor, the cursor *will* be
inside it. As an example, consider the HTML code below.

    # html
    <p>A<SPAN style="font-style: italic;">B</SPAN><SPAN style="font-color: #aa0000;">C</SPAN></P>

 * If the cursor is to the left of A, it is not inside any SPAN
   element.
 * If the cursor is to the left of B, it is not inside any SPAN
   element. It is on the boundary of one, but "leans" leftward,
   so remains outside.
 * If the cursor is to the left of C, it is inside the first
   (italic) SPAN element. It is on the boundary of two SPANs, but
   "leans" leftward, so sits in the first of the two.
 * If the cursor is to the right of C, it is inside the second
   (red) SPAN element. It is on the boundary of that element, but
   "leans" leftward, so remains inside.

The total number of cursor positions in a document is the total
number of cursor positions in all of the document's Blocks. The
set of cursor positions in a document is the union of all the
sets of cursor positions in all of its Blocks.

## Movement: How will the cursor move?

There is not yet a fully-detailed plan for cursor placement and
movement, but the following guidelines will later be solidified
into a fully specific plan.
 * Cursor positions in a document are numbered $0$ through $n-1$,
   where $n$ is the number of cursor positions in the document.
 * When a document is opened, the cursor should initially be
   placed at cursor position 0.
 * In response to the user touching the left or right arrows, the
   cursor position is incremented or decremented by one, using
   the numbering system just mentioned. Such movements are
   obviously capped to remain between $0$ and $n-1$, inclusive.
 * In response to the user clicking the mouse to position the
   cursor, the software will seek the cursor position whose
   visual position is nearest to the click point. If there is
   more than one such visual position, which one is chosen is not
   defined here.
 * In response to the user touching the up or down arrows, the
   software will execute the same routine as it does when the
   user clicks the mouse, but iteratively issuing virtual
   "clicks" at points further up/down from the current cursor
   position, until the cursor moves.
 * In response to the user touching the page-up or page-down
   buttons, the software will perform a similar operation, but
   jumping a larger distance before seeking the nearest cursor
   position.

Although this specification does not describe it, the cursor can
also leave its "anchor" in place while moving, thus highlighting
text to create a selection. The details of that exist in a
separate implementation plan, and thus are not discussed here.
(Essentially, two cursors exist, and all text strictly between
the two is highlighted by adding a "lurch-selection" class to its
elements.) This feature has actually already been implemented
before the need for this redesign became obvious, so the methods
for doing so are not only well-known, but exist in current code.

## Editing: How we keep the structural rules

We must now briefly describe the types of editing operations that
will be permitted in our word processor, and give some evidence
for why they will preserve the document structure restrictions
described above, in the
[Restrictions](#restrictions-general-principles) section.

 * Copy is the easiest action to discuss, because it doesn't
   actually edit this user's document at all, and thus can't
   possibly move it to an invalid state! That one's safe.
 * Deleting
    * If there is a selection, and the user presses Delete,
      the word processor must delete all Text, Blocks,
      and Frames that lie entirely within the selection. Such a
      move cannot violate the document restrictions because no
      new objects are inserted; only full subtrees are deleted.
      The cursor will then be at the beginning of the former
      selection, which is of necessity a valid cursor position,
      because both ends of the selection are either (a) where the
      cursor is now, or (b) where the cursor was recently, with
      no edits taking place between then and now.
    * If there is no selection, but there is text after the
      cursor and in the same block, then Delete is the same as
      "select next character, then delete."
    * If there is no selection, and the cursor is at the end of a
      block, then the current block and the next one in the Frame
      are merged into one block with the properties of the first,
      and a list of Text children equal to the concatenation of
      the Text children lists from both blocks.  This is
      acceptable because it is equivalent to moving text from one
      Block to another followed by removing a subtree; these
      operations cannot violate the above restrictions.
    * If there is no selection, and the cursor is at teh end of
      the last Block in the Frame, Delete does nothing.
 * Backspace is the same as Delete but with "before" and "after"
   interchanged.
 * Cut is the same as Copy-then-Delete. Since both have been
   handled successfully above, this one is also safe.
 * Typing letters and symbols
    * When there is no selection, it merely inserts new text
      before the cursor. Because the cursor can never be anywhere
      but inside a Block, it is always at a location where it's
      valid to insert Text.
    * When there is a selection, typing can be broken into
      "Delete the selection as above, which preserves document
      validity, then perform the typing action afterwards, with
      no selection."
 * Pressing enter creates a new Block after the current one (and
   of the same type, so a P creates a new P, an LI creates a new
   LI), then moves all text from the cursor position to the end
   of the current Block into that newly created block, and then
   places the cursor at the start of that new Block. Here is why
   each of these steps is valid.
    * Because the current Block must have a Frame as parent,
      adding a new Block as its sibling guarantees that the new
      Block is also in a valid location for Blocks.
    * Because all the content that will be moved is children of a
      Block, it must be Text objects, and thus it is valid to put
      it all into the new Block.
    * The cursor can be placed at the start of the new Block
      because every Block permits the cursor to sit immediately
      after its opening tag.
 * Pressing shift-enter is just typing the `&#10;` character (or
   the `<BR>` tag, if needed, which counts as a single-character
   Text item, as above).
 * Applying a paragraph style finds the list of Blocks containing
   the cursor and any portion of the selection, and for each one,
   modifies its style attribute. This does not alter any aspect
   of document structure mentioned in the restrictions above.
 * Applying a text style (Note that here I'm glossing over the
   issues where, if the cursor is inside a SPAN, that SPAN may
   need to be split before the following actions take place.
   Recall the comments in the
   [Cursor](#cursor-where-can-it-be-positioned-) section, above.)
    * When there is no selection, it inserts an empty SPAN
      surrounding the cursor, and having the style that the user
      is attempting to apply.  This is acceptable because the
      cursor is always inside a Block, and thus it is acceptable
      to insert an empty, styled Text node there.
    * When there is a selection, it finds all Text objects inside
      the selection and applies the style to each. For Text
      objects that are already SPAN elements, this simply
      involves modifying their style attribute. For Text objects
      that are unattributed Text nodes, this involves wrapping
      them in a new SPAN and then modifying its style attribute.
      The only potential danger here is that we are adding SPAN
      tags, but because we explicitly avoid doing so when such
      tags already exist, we therefore avoid the only possible
      danger, that of nesting SPAN tags.
 * Note that making a hyperlink can be achieved just by applying
   attributes to a span, [as described
   here](http://zachgraeve.com/2006/09/01/using-div-and-span-elements-as-clickable-links/).
 * Inserting a smart character (e.g., inserting an image) is the
   same as typing a single character, because smart characters
   have been defined, in this spec, to be treated exactly like
   individual characters.
 * Inserting a bubble is essentially inserting two smart
   characters at once, with the slight difference that one is
   inserted at the cursor position and the other at the other end
   of the selection (called the "anchor"). Because one is the
   cursor's current position, and the other is a previous
   position of the cursor (since which there have been no edits),
   both remain valid cursor positions, and thus valid places to
   insert text. Thus inserting a smart character (which functions
   exactly like text) at each such position is a valid editing
   operation.
 * Choosing the numbered list action: The following three would
   require a lot of explanation about why they're valid, so it's
   left as an exercise to the reader.
    * If the current Block is an LI inside an UL, it modifies the
      UL tag to be an OL tag instead.
    * If the current Block is an LI inside an OL, it changes the
      LI to a P, and moves it outside the list. (This may involve
      breaking the list into two if needed so that the P sits as
      a sibling to the list, not as a child of the list. Or it
      may involve removing the list entirely, if the current
      Block were the only one in the list.)
    * If the current Block is a P, then it is replaced with the
      nested structure LI-inside-OL.
 * Choosing the bulleted list action is the same, except with OL
   and UL interchanged.
 * Paste
    * Pasting plain text is exactly the same as typing the text,
      which has already been handled.
    * Pasting as plain text converts the contents of the
      clipboard to plain text, then proceeds as in the previous
      bullet.
    * Pasting rich text (HTML) will be handled as follows: First
      paste the text into an invisible DIV outside the document.
      Then traverse the DOM tree that's been created within that
      DIV, and place into the current document, at the cursor
      point, only those structures that satisfy the requirements
      of the document structure, as given above. Obviously this
      will need to be carefully tested, and is a complex
      procedure, but in theory, an algorithm that filters out the
      junk and only keeps the acceptable stuff exists.
 * The undo and redo actions only traverse the history of states
   the document has already been in, so assuming that the above
   evidence correctly shows that the document can't get into an
   invalid state via ordinary editing actions, then undo/redo
   can't, either.

## Junk: Keeping the document clean

You may have noticed that there are ways to create crufty
internal document states that would be externally invisible.  For
instance, one might delete some formatted text, leaving empty
SPAN elements sitting around. Although I do not have one perfect
plan for how to solve this, there are several options.
 * Every time the document is saved, first police away these
   potential abnormalities everywhere in the document.
 * After every single editing action, police away these potential
   abnormalities in every Block that was involved in the editing
   action.
 * Provide the app that uses our word processing foundation with
   a function it can call to do such policing at whatever times
   make sense; for example, *Lurch* itself might do the policing
   before every run of validation, while other apps that use our
   word processing foundation would do it at other times.

