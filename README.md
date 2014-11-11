
# webLurch

This project is an attempt to rewrite [Lurch](http://lurchmath.org) in a web
browser, together with many major design improvements at the same time.  But
this project is only just beginning; the main Lurch product is still the
desktop app, which works well.

Information on this project:
 * [Overview ](doc/overview.md) - start here
 * [Project Progress](doc/progress.md) - what's been built
 * [Project Plan](doc/plan.md) - what's left to build
 * [Repository contents](#repository-contents) - full details on all files

Or just start here:

## Getting Started

You cannot yet try the software out online, but that opportunity will come
soon.

If you want to build any of the source code or documentation in
this repository on your local machine, follow these instructions.
 * Clone [this repository](https://github.com/nathancarter/weblurch).
 * Install [node.js](http://nodejs.org).
 * Install [CoffeeScript](http://coffeescript.org).
 * Run `cake` in the root folder of the repository to see the options for
   the build process.  Start with `cake all`.
 * Browse this repository for more information.  The source code is
   literate, so there's lots of documentation embedded in it, by nature.

## Repository contents

All source code in this repository is written in [literate
CoffeeScript](http://coffeescript.org/#literate), which GitHub automatically
renders beautifully in the browser; see [this
example](buildutils.litcoffee).

### Root folder

In the root folder of this repository you will find only a very few files.
 * `package.json` - used by [node.js](http://nodejs.org) to install
   dependencies for this project.  (This project does not run under `node`;
   it runs in a browser, but the build system runs under `node`.)
 * `cake.litcoffee` - definition of the build process.  To run the build
   process, see [Getting Started](#getting-started), above.
 * `Cakefile` - technically, this is the file that `cake` reads, but in
   order to keep all files in the repository in the same language, this file
   is just a one-liner that redirects all processing to `cake.litcoffee`.

### `app` folder

The actual web app that this project defines gets built into this folder.
Its main page is [index.html](app/index.html), but as of this writing,
things are still very early in the development process, and thus the app
doesn't do anything yet.  It's just a placeholder file into which working
code and a UI will be added later.

When that app becomes more than just a placeholder, it will be moved to the
`gh-pages` branch, and made available for use online, served from GitHub.
The link above will be updated at that time.

### `src` folder

Where the source files are stored that are used when building the app in the
`app` folder.

### `test` folder

Where test specs (and utilities used by the unit test suite) are stored. See
[the source file defining the build process](cake.litcoffee) for more
information.

### `node_modules` folder

This folder appears when you configure a local copy of this repository.  See
[Getting Started](#getting-started), above.  It is where `node` installs all
necessary dependencies, locally.

### `reports` folder

This folder is not in the repository, but will appear in a local copy if you
run the unit tests.  It's a temporary storage location for reports on the
results of the last run of unit tests, used by the build system when
generating [the Markdown version of those same
reports](test/test-results.md).
