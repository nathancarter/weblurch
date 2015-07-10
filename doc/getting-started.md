
# Getting Started

## Try the demos online

You can [try out demo apps right now online](tutorial.md), but doing
development requires cloning and setting up this repository on your machine.
Here's how.

## Setting up a local repository

Install [node.js](http://nodejs.org), which governs our building and tesitng
process.  (The apps run in a browser.)

Then execute the commands below from a \*nix prompt.
```
$ git clone https://github.com/nathancarter/weblurch
$ cd weblurch
$ git submodule init   # prepares git submodule folders
$ git submodule update # downloads all files in all git submodules
$ npm install          # installs required packages in ./node_modules
$ npm test             # builds app and runs unit test suite
```

## Running a local web server

To use any of the demo apps on your own local machine, you need a web server
(to avoid browser security concerns with `file:///` URLs).  You almost
certainly have Python installed, so in the root of the project repository,
do this.
```
$ python -m SimpleHTTPServer 8000
```
Point your browser to `localhost:8000/app/index.html`, or any other page in
the repository's `app/` folder.

## [CoffeeScript](http://www.coffeescript.org)

To build the app without running the tests, you'll want to run the build
command `cake`, which is part of [CoffeeScript](http://www.coffeescript.org).
Install CoffeeScript globally (just once) with this command.
```
$ npm install -g coffee-script
```
Now you have the `cake` command.  Use it to build the app without running
tests as follows.
```
$ cake app
```
See more options by running `cake` with no parameters.
