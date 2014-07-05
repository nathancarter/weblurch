
# webLurch Documentation

## What is this?

This project is an attempt to rewrite [Lurch](http://lurchmath.org)
in a web browser, together with many major design improvements at
the same time.  So far the main development on *Lurch* is still in
the desktop app, at the website just linked to.  If this project
becomes more promising later, then more development efforts will
be focused here.
 * To know what parts have already been built, see
   [the Project Progress page](progress.md.html).
 * To know what parts remain to be done, see
   [the Project Plan](plan.md.html).
 * To try any of this code out, see
   [Getting Started](#getting-started), below.

## Structure of this repository

Every piece of source code in this repository is written in
[literate CoffeeScript](http://coffeescript.org/#literate).
Such files come with a `.litcoffee` extension.

### Root folder

In the root folder of this repository you will find only a very
few files.

 * `package.json` - used by [node.js](http://nodejs.org) to install
   dependencies for this project.  (This project does not run under
   `node`; it runs in a browser, but the build system runs under
   `node`.)
 * `cake.litcoffee` - definition of the build process.  To run the
   build process, see [Getting Started](#getting-started), below.
 * `Cakefile` - technically, this is the file that `cake` reads,
   but in order to keep all files in the repository in literate
   CoffeeScript, this file is just a one-liner that redirects all
   processing to `cake.litcoffee`.

### `app` folder

The actual web app that this project defines gets built into this
folder.  Its main page is [index.html](../app/index.html), but
as of this writing, things are still very early in the development
process, and thus the app doesn't do anything yet.  It's just a
placeholder file into which working code and a UI will be added
later.

### `doc` folder

The file you're reading now (and most files you can get to using
the navigation bar on the right) reside in the `doc/` subfolder.
Some are [Markdown](https://daringfireball.net/projects/markdown/)
files that get typeset and converted into HTML pages (like this
page, for instance) as part of the build process, and some are
rendered versions of the project's source code, again rendered to
HTML as part of the build process.  (Note that literate
CoffeeScript pretty much *is* Markdown, so these two variants are
not really different.)

### `node_modules` folder

You will not have this folder if you have not configured this
repository.  See [Getting Started](#getting-started), below.

It is where `node` installs all necessary dependencies, locally.

### `reports` folder

A temporary storage location for reports on the results of the
last run of unit tests, used by the build system when generating
[the HTML version of those same reports](test-results.md.html).

### `src` folder

Where the source files are stored that are used when building the
app in the `app` folder.

### `test` folder

Where test files and utilities are stored that are used by the
unit test suite that's part of the build process.  See
[the source file defining the build process](
cake.litcoffee.html) for more information.

### `testapp` folder

This is a secondary app that's also built alongside the real one.
Rather than being the actual functioning app that this source
repository aims to build, this one will instead be used for
experimenting with, debugging, and building test data for the real
app.

For right now, it, too, is just a stub/placeholder that will be
replaced by a more robust application later.

## Getting Started

If you want to build any of the source code or documentation in
this repository, follow these instructions.

 * Clone [this repository](
   https://github.com/nathancarter/weblurch).
 * Install [node.js](http://nodejs.org).
 * Install [CoffeeScript](http://coffeescript.org).
 * Run `cake` in the root folder of the repository to see the
   options for the build process.  Start with `cake all`.
 * Browse these documents for more information.  (See the
   navigation pane to the right.)  The source code is literate, so
   there's lots of documentation embedded in it, by nature.

