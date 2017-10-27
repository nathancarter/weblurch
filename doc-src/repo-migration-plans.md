
# Plans for Migrating this Repository

We plan to migrate this repository to a GitHub organization shared by both
project collaborators, [Nathan Carter](http://nathancarter.github.io) and
[Ken Monks](http://github.com/kenmonks).

Reasons for the move:

 * The [project plan file](plan.md) already lists several ways in which this
   repository needs to be tidied up.  Those plans will be accomplished as
   part of the migration.
 * Until now, Nathan has been the primary author, but Ken will be getting
   more involved in the development from this point forward.  Thus a shared
   space is sensible.  We also hope to have other developers and student
   assistants join us in the future, thereby making the organization account
   even more sensible and useful.
 * The move will simplify our URL to something easier to remember,
   [lurchmath.github.io](http://lurchmath.github.io).  (At the time of this
   writing, that URL has no content at it.  One of the tasks listed below is
   to create such content.)

## Preparing the new space

The organization account has been created, Nathan is an owner, and Ken has
been invited as a member.  Tasks to do to complete the space include these:

 - [x] Create a project with name `lurchmath.github.io` owned by the
   organization, following the directions
   [on this page](https://pages.github.com/).
 - [x] Ensure both collaborators have ownership of/access to this project.
 - [x] For consistency with the existing repo, let's use
   [MkDocs](http://www.mkdocs.org) to create that site.  Follow the
   directions [here](http://www.mkdocs.org/#getting-started) to get started.
   You probably want to add a redirection page from the root folder to the
   `site/` folder, or configure GitHub to go there without a redirection
   page needed (better option if possible).  For now, make a placeholder
   website we can extend later.
 - [x] Create a `README.md` in that project that simply points the reader to
   the website.

## Moving the first subproject over

One of the repository tidying tasks is to factor out independent subprojects
into their own repositories, and use GitHub pages like a CDN for serving
their compiled JavaScript versions.  Another goal is to start using a build
tool, and I've chosen [Gulp](https://gulpjs.com/) as what seems best for our
needs.  We will try both of those things out on a single subproject, to test
and cement a good process before proceeding to factor out other subprojects.

We will use the [OpenMath](../src/openmath-duo.litcoffee) module as the
first subproject to factor out into its own repository.  As you do the
following steps, record somewhere the proper way to do each one, so that you
can repeat this process for other subprojects more easily hereafter.

 * [x] Create a new project in the Lurch Math organization for the OpenMath
   JavaScript library and clone it to your local machine.
 * [x] Copy the [source](../src/openmath-duo.litcoffee) and
   [test](../test/openmath-spec.litcoffee) files to the new repository, in
   its root folder.  Rename them to `openmath.litcoffee` and
   `spec.litcoffee`, respectively.  Commit.
 * [x] Create a `package.json` file that imports the Jasmine test tool.
   Ensure that you can run Jasmine on the spec file and that the tests
   pass; modify any paths necessary to make this happen.  Commit.
 * [x] Install Gulp and create a
   [Gulpfile](https://github.com/gulpjs/gulp/blob/master/docs/getting-started.md) that does nothing.  Commit.
 * [x] Extend the Gulpfile to compile a JavaScript version of the OpenMath
   module.  Add the `.js` file to the repo and commit.
 * [x] Extend the Gulpfile to also compile a minified version, with source
   maps.  Add these files to the repository and commit again.
 * [x] Extend the Gulpfile with a `tests` task that runs the Jasmine
   command on your behalf.  Commit.
 * [x] Register the project with TravisCI so that the tests are run on every
   push to the repository.
 * [x] Create a `README.md` in the repository root that explains the
   project and includes the TravisCI test status image.  It should refer
   the user to the GitHub links to the raw compiled and minified scripts,
   so that GitHub can be used as a makeshift CDN.
 * [x] Add documentation for this subproject using
   [MkDocs](http://www.mkdocs.org), as you did for the new Lurch Math
   organization.  Follow the directions
   [here](http://www.mkdocs.org/#getting-started) to get started.  Commit.
 * [x] Extend the Gulpfile with a `docs` task that runs the `mkdocs`
   command on your behalf.  Commit.
 * [x] Remove the OpenMath code from the existing webLurch repository,
   instead importing it using the makeshift CDN mentioned above.  Change all
   references to it in the documentation to mention the newly-factored-out
   repository in the new organization.  Verify that all uses of that module
   still function in the main webLurch repository, and commit changes there.

## Moving more subprojects over

Once you've accomplished the process in the previous section, and documented
it well so that you can do it more smoothly the second time (and the third,
and so on), do that process to factor out each of the following subprojects
from the main, existing webLurch repository.

 * [x] The Parsing module
 * [x] The Matching module

## Supporting Cloud Storage

Now that the [cloud storage
module](https://github.com/lurchmath/cloud-storage) has been built and
tested, it should replace both the LocalStorage and baby Dropbox support in
webLurch at present.  Here's a to-do list for accomplishing that.

 * [x] Update the cloud storage module to show how to import its files with
   [jsDelivr](http://www.jsdeliver.net) in the README.
 * [x] Have all the apps import the cloud storage module from that CDN,
   before importing [app.js](../app/app.js), and ensure that nothing gets
   broken in the process.  The module won't be used yet, just imported for
   later.
 * [x] Make a copy of [the Load/Save
   Plugin](../app/loadsaveplugin.litcoffee) and call it the Cloud Storage
   Plugin instead, renaming it in both filename and script code.
 * [x] Ensure that the Cloud Storage Plugin is part of the build process and
   is included in the app and installed in the editor object.
 * [x] Figure out a way to get the cloud storage tools to function
   exclusively from cloud.  This may involve using GitHub web serving, since
   jsdelivr won't serve HTML pages as HTML pages.  If this can't be done,
   at least move the tools into a subfolder of the app folder, and enhance
   their API so that they can support living in a subfolder.  Then extend
   the build process to always fetch the latest versions.  (Or add that as a
   task to be done once grunt is adopted.)
 * [x] Replace the LoadSave plugin and the Dropbox plugin with a single
   Storage plugin, as follows.
    * [x] Rename the DropboxPlugin to the StoragePlugin
    * [x] Translate the following code from LoadSave to Storage:
       * [x] All code in the constructor section, except Manage Files item
       * [x] Add to the constructor the creation of both back ends
       * [x] All code in the setters section
       * [x] Add a member that reports all available back ends
       * [x] Add a member that lets users get/set which back end is active
       * [x] All code in the new documents section
       * [x] All code in the saving documents section except `save`
       * [x] Replace `tryToSave` with the handler Dropbox would install
       * [x] Create the "loading documents" section in the Storage plugin
       * [x] Convert the old `@load` member to one that takes the
         `[content,metadata]` array as input and loads it into the editor
       * [x] Create a new function for loading a named file from
         LocalStorage, returning `[content,metadata]`; no editor updating
    * [x] Ensure the Storage plugin exposes a `filename` member; this
      should be easy to do whenever you update `lastFileObject`
    * [x] Update `DependenciesPlugin.getFileMetadata` to call the new
      Storage plugin function that loads files from LocalStorage
    * [x] Update `setup.litcoffee` to say `storage` instead of
      `cloudstorage`
    * [x] Ensure that the install procedure for the StoragePlugin calls
      it `storage` and not `dropbox`
    * [x] Remove from `setup.litcoffee` the `loadsave` plugin
    * [x] Replace every instance of `LoadSave` with `Storage` throughout
    * [x] Remove the LoadSave plugin entirely from the application.
    * [x] Update the wiki plugin because you've implemented `embedMetadata`
      and `extractMetadata` in the Storage plugin now, so they aren't
      globally defined, and don't need to be redefined in the wiki plugin.
      Also, everyone who calls them should do so through the Storage plugin.
 * [x] In [main-app-settings.litcoffee](main-app-settings.litcoffee), change
   the `setFilesystem` function so that any chosen filesystem calls the new
   API function in the Storage plugin, telling it to change to that
   filesystem.  Ensure that the right options are provided as radio buttons,
   up around line 47.  Test to be sure that all filesystems now work.
 * [x] Ensure that no reference to the `jsfs` submodule remains in the
   application.
 * [x] Update any other demo apps to remove all references to the `jsfs`
   submodule.
 * [x] Remove the `jsfs` submodule from the repository.  Ensure that the
   applications still function.
 * [x] Remove [the old file dialog
   source](../app/filedialog/filedialog.html).  Ensure that the
   applications still function.
 * [x] Get rid of the LZString JS library from our repository.  Ensure that
   the applications still function.
 * [x] Make the functionality improvements listed in the cloud storage repo.

## Obviating some files in the repository

 * [x] Because our only targeted browser is Chrome, which now supports
   `navigator.hardwardConcurrency` natively, you can drop the
   `core-estimator` files in the repository, and update any code to use the
   native version instead (if any updates are even needed).  Be sure to
   stop importing the removed polyfill.
 * [x] Get rid of the `jquery-splitter/` folder and submodule.  Instead,
   use the following CDN URLs:
   https://cdn.jsdelivr.net/gh/jcubic/jquery.splitter@0.24/js/jquery.splitter.min.js
   and
   https://cdn.jsdelivr.net/gh/jcubic/jquery.splitter@0.24/css/jquery.splitter.min.css

## Starting a new main repository

 * [x] Create a new project in the Lurch Math organization for receiving the
   main repository, as we slowly transfer pieces over, cleaning cruft as we
   go.  Call it `Lurch`.  Ensure both collaborators have permissions.
 * [x] Transfer the `README.md` from the old repository (with any needed
   images and updated links) to the new one.  Commit.
 * [x] Start documentation for this project using
   [MkDocs](http://www.mkdocs.org), as you did in previous projects.
   Follow the directions
   [here](http://www.mkdocs.org/#getting-started) to get started.  Use a
   `docs/` subfolder that compiles to a `site/` subfolder.  For now, it
   should be 99% blank, just a placeholder for where future documentation
   will go.  Commit.
 * [x] Ensure that GitHub is set up to use the root of the project as the
   web site, and create an `index.html` that is a one-line redirecting META
   tag into the `site/` folder, as we did earlier.
 * [x] Create a Gulpfile with a `docs` task that runs the `mkdocs`
   command on your behalf.  Commit.

## Moving large chunks of code that will get used later

 * [x] Create a `source/modules` subfolder in the new repository and move
   into it all remaining code in the `src/` folder of the old repository.
   Commit, but mention that these files are not yet used for anything, and
   are just part of an ongoing migration process.
 * [x] Create a `source/plugins` subfolder in the new repository and move
   into it all files matching `app/*plugin.litcoffee` from the old
   repository.  Also move any files that those plugins require, such as
   `.css` files.  Commit, but mention that these files are not yet used for
   anything, and are just part of an ongoing migration process.
 * [x] Move the following important source files from the old repo into
   `source/` in the new repo.  Commit, again mentioning this is part of an
   ongoing migration.
    * [x] `keyboard-shortcuts-workaround.litcoffee`
    * [x] `mathquill-parser-solo.litcoffee`
    * [x] `setup.litcoffee`
    * [x] `testrecorder-solo.litcoffee`
    * [x] `testrecorder.html`
    * [x] `testrecorder.litcoffee`
    * [x] `lurch-embed-solo.litcoffee`
 * [x] Create a `source/experimental` subfolder in the new repository and
   move into it the following files from the old repository.  Commit, but
   mention that these files are not yet used for anything, and are just
   part of an ongoing migration process.
    * [x] `cp-test-solo.litcoffee`
    * [x] `cp-test.html`
    * [x] `lpf-test-solo.litcoffee`
    * [x] `lpf-test.html`
 * [x] Create a `source/main-app` subfolder in the new repository and move
   into it the following files from the old repository.  Commit, but
   mention that these files are not yet used for anything, and are just
   part of an ongoing migration process.
    * [x] `main-app-attr-dialog-solo.litcoffee` (dropping the `main-app-`)
    * [x] `main-app-basics-solo.` (dropping the `main-app-`)
    * [x] `main-app-group-class-solo.` (dropping the `main-app-`)
    * [x] `main-app-group-labels-solo.` (dropping the `main-app-`)
    * [x] `main-app-group-validation-solo.` (dropping the `main-app-`)
    * [x] `main-app-groups-solo.` (dropping the `main-app-`)
    * [x] `main-app-import-export-solo.` (dropping the `main-app-`)
    * [x] `main-app-proto-groups-solo.` (dropping the `main-app-`)
    * [x] `main-app-settings-solo.` (dropping the `main-app-`)
    * [x] `main-app-sharing-solo.` (dropping the `main-app-`)
    * [x] `app.html`
 * [x] Create a `source/assets` subfolder in the new repository and move
   into it the following files from the old repository.  Commit, but
   mention that these files are not yet used for anything, and are just
   part of an ongoing migration process.
    * [x] `eqed/` folder
    * [x] `input-method.js` (Which is online here, if you want to import it
      from GitHub raw, like a fake CDN: https://leanprover.github.io/tutorial/js/input-method.js)
    * [x] `icons/` folder
    * [x] `images/` folder
 * [x] Create a `unit-tests` subfolder in the new repository and move into
   it the following files from the old repository.  Commit, but mention that
   these files are not yet used for anything, and are just part of an
   ongoing migration process.
    * [x] `app-test-utils.litcoffee`
    * [x] `domutils-spec.litcoffee`
    * [x] `groupsplugin-change-spec.litcoffee`
    * [x] `groupsplugin-spec.litcoffee`
    * [x] `loadsaveplugin-spec.litcoffee`
    * [x] `overlayplugin-spec.litcoffee`
    * [x] `phantom-utils.litcoffee`
    * [x] `tinymce-basics-spec.litcoffee`
    * [x] `utils-spec.litcoffee`
    * [x] `embedding/` folder

## Beginning to use the migrated code

 * [x] Rename files that end with `-solo` to not have that suffix.
 * [x] Create a `release/` folder within the new repository.
 * [x] Implement a gulp task called `lwp-build` that
   concatenates all the following into a single file, in this order, then
   compiles it with minification and source maps into
   `release/lurch-web-platform.*`:
    * `source/modules/utils.litcoffee`
    * `source/modules/domutils.litcoffee`
    * `source/modules/canvasutils.litcoffee`
    * `source/plugins/*.litcoffee`
    * `source/auxiliary/keyboard-shortcuts-workaround.litcoffee`
    * `source/auxiliary/testrecorder.litcoffee`
    * `source/auxiliary/setup.litcoffee`
 * [x] Implement a gulp task called `build-auxiliary-js-files` that
   compiles each of the following files, with minification and source maps,
   into the `release/` folder.
    * `source/auxiliary/lurch-embed.litcoffee`
    * `source/auxiliary/mathquill-parser.litcoffee`
    * `source/auxiliary/testrecorder.litcoffee`
    * `source/auxiliary/background.litcoffee`
    * `source/auxiliary/worker.litcoffee`
 * [x] Implement a gulp task called `build-experiments` that compiles (with
   minification and source maps) `source/experiments/*.litcoffee` into the
   same (experiments) folder.
 * [x] Implement a default gulp task that runs all the previous ones.
 * [x] Test that this has succeeded by temporarily moving into the new repo
   the compiled versions of `simple-example*.*` from the old repo's `app/`
   folder, and verifying that the example still runs.  Do not keep these
   files in the new repo; move them out and *then* commit the changes.  (But
   keep the files so that you can use them in the next stage, below.)

## Creating demo apps as separate projects

Consider each of the following example applications.

 * [x] `simple-example*.*`
 * [x] `complex-example*.*`
 * [x] `math-example*.*`
 * [x] `openmath-example*.*`
 * [x] `lean-example*.*`
 * [x] `sidebar-example*.*`

For each of them, do all of the following steps.

 * Create a new project to house the example.
    * mkdir lwp-example-<name>
    * cd lwp-example-<name>
    * git init
    * On https://github.com/lurchmath, click New.
    * Give the repo the name `lwp-example-<name>`.
    * Description: <Some kinda> example built on the Lurch Web Platform.
    * Don't initialize with a README; just Create repository.
    * git remote add origin https://github.com/lurchmath/lwp-example-<name>.git
 * Move files in.
    * cp ../../weblurch/app/<name>-example*.* .
    * mv <name>-example.html index.html
    * Rename the other files to `lwp-example-<name>.*`.
    * git add --all
    * git commit -m 'Importing files from old webLurch repo (with renaming)'
    * git push -u origin master
    * Update index.html, mimicking lwp-example-simple/index.html, which
      is a very different style than it was.
    * Test with a local web server, and get it working.
    * Open that new repo in GitHub desktop.
    * Commit.
 * Create a build process.
    * npm install gulp gulp-coffee gulp-uglify gulp-sourcemaps pump --save-dev
    * Create a .gitignore that mentions node_modules.
    * It should compile and minify the source code all in the root dir.
    * Remove any files not generated by that build process.
    * Commit and push.
 * Add a README.
    * It should explain the repository briefly.
    * It should direct readers into the literate source for details.
    * It should also link to the build process source.
    * Commit and push.
 * Web space:
    * Visit https://github.com/lurchmath/lwp-example-<name>.
    * Click Settings, scroll down to GitHub Pages.
    * Choose Master branch, click Save.
    * Verify that the application works when you visit
      https://lurchmath.github.io/lwp-example-<name>
    * Add to the README a link to the functioning app at that URL.
    * Commit and push.
 * Update source code.
    * Update links in `addHelpMenuSourceCodeLink` and `helpAboutText`.
    * Update links in any of the Markdown documentation.
    * Read the literate comments and fix anything else out-of-date.
    * Be sure there is a link to the main project repo:
      https://github.com/lurchmath/lurch

## Handling experimental content

 * [ ] Create a Gulp build process called `experimental` that compiles and
   minifies all the code in the `source/experimental/` folder in the new
   repository, and copies all the results into a `site/experimental/`
   directory, having first deleted everything in that folder.
 * [ ] Ensure that the HTML files in that directory correctly import the
   Lurch Web Platform from the parent directory (`site/`).
 * [ ] Ensure that the experimental HTML apps in that folder still function
   (or at least function as well as they do in the old repo).  Commit.

## Miscellaneous

 * [ ] Update `lurch-embed.litcoffee` to function in the new space.
 * [ ] Since you've changed the `Api-User-Agent` of the MediaWiki Plugin
   from "webLurch Application" to "Lurch Application," check to see if your
   MediaWiki modifications on the other end are sensitive to that, and if
   so, update them.

## Warning

It may be best to stop here for now, until our design efforts progress far
enough that we know with some certainty whether the following tasks still
make sense, or at least know better how to do them correctly.

## Handling the main app

 * [ ] Create a Gulp build process called `main-app` that compiles and
   minifies all the code in the `source/main-app/` folder in the new
   repository, and copies all the result into a `site/app/` directory,
   having first deleted everything in that folder.
 * [ ] Ensure that the HTML file in that directory correctly imports the
   Lurch Web Platform from the parent directory (`site/`).
 * [ ] Ensure that the HTML app in that folder still functions, just as it
   does in the old repo.  Commit.

## Migrating documentation

 * [ ] Copy all the content from the old repo's `doc-src/` folder into the
   new repo's `docs/` folder.  Do not commit.
 * [ ] Proofread each page in that new folder, updating any links or
   explanations to be accurate and up-to-date after all the recent migration
   changes.  Test often as you write, using the Gulp task that builds the
   documentation.  Commit.
 * [ ] Update `setup.litcoffee`, in which I formerly commented out the
   section linking to the developer tutorial from the Help menu.  Now you
   can add that link back in, to the new developer tutorial.
 * [ ] Update the README in the `lwp-example-lean` repository to reference
   the full Lean tutorial documentation.  While you're at it, check to see
   if that app actually uses the equation editor at all.  If not, remove
   the `eqed/` subfolder from that repository, as well as the scripts
   imported from it, just to simplify things.

## Migrating unit tests

 * [ ] Make a Gulp task called `tests` that initially does nothing.  Commit,
   but mention that obviously this is not yet complete.
 * [ ] Extend that Gulp task so that it runs any unit tests that do not yet
   need [PhantomJS](http://phantomjs.org/).  Ensure that they run (not
   necessarily passing yet) and then commit.
 * [ ] If needed, fix any errors detected by the newly running unit tests,
   and commit.
 * [ ] Add PhantomJS to the `package.json` file of the new repository,
   following the lead of how this was first done in the old repository.
 * [ ] Extend the Gulp tests task so that it successfully runs the simplest
   of the unit tests that require PhantomJS (probably `domutils`).  Commit.
 * [ ] Extend the Gulp tests task iteratively with new unit tests that
   require PhantomJS, fixing errors as you proceed, committing after each.
