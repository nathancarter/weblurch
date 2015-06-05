
# webLurch

<!--
Removing this because the tests on Travis-CI were segmentation faulting (!),
while they run without a single error on my laptop.  Will figure it out
later, but for now, I don't want it to look like we have failing tests,
when we don't, really.
[![Build status](https://travis-ci.org/nathancarter/weblurch.svg?branch=master)](https://travis-ci.org/nathancarter/weblurch)
-->

This project is an attempt to rewrite [Lurch](http://lurchmath.org) in a web
browser, together with many major design improvements at the same time.  But
this project is only just beginning; the main Lurch product is still the
desktop app, which works well.

Information on this project:
 * [Overview](doc/overview.md) - start here
 * [Project Progress](doc/progress.md) - what's been built
 * [Project Plan](doc/plan.md) - what's left to build
 * [Repository contents](#repository-contents) - full details on all files

Or just start here:

## Getting Started

Although you can [try the current version out
online](http://nathancarter.github.io/weblurch/app/index.html), right now
it's just a [TinyMCE](http://www.tinymce.com) instance that can load and
save files and has support for "meaningful expression" groups that don't
(yet!) do anything useful.  The interesting features are still to come.

If you want to build any of the source code in this repository on your local
machine, be sure that you have [node.js](http://nodejs.org) installed, and
then execute the commands below. (The software does not run under `node`,
but the build process does.)
```
$ git clone https://github.com/nathancarter/weblurch
$ cd weblurch
$ git submodule init   # prepares git submodule folders
$ git submodule update # downloads all files in all git submodules
$ npm install          # installs required packages in ./node_modules
$ npm test             # builds app and runs unit test suite
```

To then run the app on your own local machine, you will need a web server
(to avoid heightened browser security with `file:///` URLs).  If you have
Python installed, this is trivial.  In the root of the project repository,
run
```
python -m SimpleHTTPServer 8000
```
Then point your browser to `localhost:8000/app/index.html`.

To build the app without running the tests, run `./node_modules/.bin/cake`.
Since that's inconvenient, you can install
[CoffeeScript](http://www.coffeescript.org) globally as follows, and `cake`
will then be in your path.
```
$ npm install -g coffee-script
```
Browse this repository for more information.  The source code is
literate, so there's lots of documentation embedded in it, by nature.

## Building your own app

You can learn how to create your own apps based on webLurch's foundation by
checking out the file for
[a simple example](app/simple-example.solo.litcoffee) and then for
[a complex example](app/complex-example.solo.litcoffee).

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
Its main page is [index.html](app/index.html).

That file also appears in the the `gh-pages` branch, and is therefore
available for use online, served from GitHub.  The link in
[the Getting Started section](#getting-started) leads to the live version.

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
