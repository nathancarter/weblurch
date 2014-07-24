
# How to use the Test App

[The test app can be found at this link.](../testapp/index.html)

## Purpose of the test app

The test app makes it easy to record, within a webLurch document,
three things:
 * a sequence of actions performed
 * the sequence of document states those actions brought about
 * a judgment, for each state achieved, of whether it is correct
   (i.e., how the software should behave) or incorrect
   (i.e., a bug)

It also makes it possible to download such recordings as a file
that can be put directly into the repository as part of the
automated unit testing of the software.

## Features and limitations

Right now the test app only supports one very limited type of
action:  Running a single line of JavaScript code.  (Technically,
this is actually quite *un*limited, but is not the best user
experience.)

Eventually, the test app will support all the same actions that
the software itself will support, including keyboard and mouse
interaction with a webLurch document.  But since none of those
features are built for the main app yet, they are also not present
in the test app.

## Example use

Here is one very simple example use of the test app.
 1. Open [the test app](../testapp/index.html).
    The HTML tab will be empty, because it shows the document,
    which is empty at first.
    (Click the Source tab to see the HTML source of the empty
    document.)
 1. Navigate to the History tab to see a record of the changes you
    are about to make.
 1. In the text box at the top for running code, execute the
    following code by typing it and pressing enter:
    <br>
    `maindiv.innerHTML = 'foo'`
    <br>
    You will see the history expand to show the command you ran
    as well as the resulting state of the document after it.
 1. If you believe that the document is in a *correct* state, then
    you can mark that state correct using the green thumbs-up icon
    on the right hand side of the state in the history.  If the
    state represents a software bug, use the red thumbs-down icon.
 1. Optionally execute more code, such as this:
    <br>
    `maindiv.appendChild(document.createElement('hr'))`
 1. Eventually download your test history by clicking the download
    button you see near the center below the History tab.
 1. To incorporate your test into the automated test suite, commit
    it to the repository in any folder under the `test/histories`
    folder.  Use a descriptive filename.

## Other features

This section merely documents other buttons and controls in the
test app not covered in the example above.
 * Controls for the whole app
   * The Run button next to the code input box executes the code in
     that box, but it is easier to use the keyboard shortcut of
     just pressing enter.
   * The Undo button next to the Run button moves the entire
     document (and the state of its undo/redo history, believe it
     or not) back one state in the history you can see in the
     History tab.
   * The Reset button next to the Undo button puts the test app
     back in its initial state, as if the page were just refreshed.
 * Controls in the History tab
   * Any test history in the repository is automatically embedded
     in the drop-down list on the top right of the History panel.
     Choose one to have it displayed side-by-side with your current
     test history.
   * Every command in one of the test histories displayed from that
     drop-down list can be executed by clicking the Run button in
     its panel's title bar.
   * To run them all at once, use the Run button next to the
     drop-down menu itself.

