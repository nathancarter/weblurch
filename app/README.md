
# The `app` folder

This folder contains the source code and HTML files for the main app of this
repository.
 * All `.litcoffee` files in this folder will be concatenated into one, big
   `app.litcoffee` file as part of the build process, which is then compiled
   into `app.min.js`, with an appropriate source map file.
 * The exception to this is that `*-solo.litcoffee` files are not included
   in that large compilation process, but are compiled individually instead
   (hence the "solo").  See each such file for its reasons why.

The page containing the app is [index.html](index.html), and you can see it
runnin live on GitHub Pages [by clicking
here](http://nathancarter.github.io/weblurch/app/index.html).

Thanks to [the lean.js project](https://github.com/leanprover/lean.js) for
many ideas that went into [the Lean example
app](lean-example-solo.litcoffee), and for the freely available
[input-method.js file](input-method.js).
