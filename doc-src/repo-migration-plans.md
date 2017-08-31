
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

## The `jsfs` subproject

Investigate how [the `jsfs` project](https://github.com/nathancarter/jsfs)
could be used in the main webLurch repository through links to the raw
script files on GitHub (makeshift CDN) rather than by importing it as a
submodule.  In other words, `jsfs` is already factored out as a separate
project, but is imported using the clunky `git submodules` mechanism, rather
than the much cleaner (and more loosely coupled) `<script src='...'>`
mechanism; solve this problem.

## Obviating some files in the repository

 * [ ] In the [Load/Save Plugin](../app/loadsaveplugin.litcoffee), assume
   the existence of the
   [Canvas Utilities Module](../src/canvasutils.litcoffee), and thus delete
   the tiny, simple file `../app/filedialog/filedialog.html`, instead
   creating an internal object URL with `objectURLForBlob` directly in the
   code.  This should get rid of both the `filedialog.html` file and the
   `tinymcedialog-solo.litcoffee` file, which is very short and is imported
   by only `filedialog.html`.
 * [ ] Because our only targeted browser is Chrome, which now supports
   `navigator.hardwardConcurrency` natively, you can drop the
   `core-estimator` files in the repository, and update any code to use the
   native version instead (if any updates are even needed).  Be sure to
   stop importing the removed polyfill.

## Starting a new main repository

 * [ ] Create a new project in the Lurch Math organization for receiving the
   main repository, as we slowly transfer pieces over, cleaning cruft as we
   go.  Call it `Lurch`.  Ensure both collaborators have permissions.
 * [ ] Transfer the `README.md` from the old repository (with any needed
   images and updated links) to the new one.  Commit.
 * [ ] Start documentation for this project using
   [MkDocs](http://www.mkdocs.org), as you did in previous projects.
   Follow the directions
   [here](http://www.mkdocs.org/#getting-started) to get started.  Use a
   `docs/` subfolder that compiles to a `site/` subfolder.  For now, it
   should be 99% blank, just a placeholder for where future documentation
   will go.  Commit.
 * [ ] Ensure that GitHub is set up to use the root of the project as the
   web site, and create an `index.html` that is a one-line redirecting META
   tag into the `site/` folder, as we did earlier.
 * [ ] Create a Gulpfile with a `docs` task that runs the `mkdocs`
   command on your behalf.  Commit.

## Moving large chunks of code that will get used later

 * [ ] Create a `source/modules` subfolder in the new repository and move
   into it all remaining code in the `src/` folder of the old repository.
   Commit, but mention that these files are not yet used for anything, and
   are just part of an ongoing migration process.
 * [ ] Create a `source/plugins` subfolder in the new repository and move
   into it all files matching `app/*plugin.litcoffee` from the old
   repository.  Also move any files that those plugins require, such as
   `.css` files.  Commit, but mention that these files are not yet used for
   anything, and are just part of an ongoing migration process.
 * [ ] Move the following important source files from the old repo into
   `source/` in the new repo.  Commit, again mentioning this is part of an
   ongoing migration.
    * `keyboard-shortcuts-workaround.litcoffee`
    * `mathquill-parser-solo.litcoffee`
    * `setup.litcoffee`
    * `testrecorder-solo.litcoffee`
    * `testrecorder.html`
    * `testrecorder.litcoffee`
    * `lurch-embed-solo.litcoffee`
 * [ ] Create a `source/experimental` subfolder in the new repository and
   move into it the following files from the old repository.  Commit, but
   mention that these files are not yet used for anything, and are just
   part of an ongoing migration process.
    * `cp-test-solo.litcoffee`
    * `cp-test.html`
    * `lpf-test-solo.litcoffee`
    * `lpf-test.html`
 * [ ] Create a `source/main-app` subfolder in the new repository and move
   into it the following files from the old repository.  Commit, but
   mention that these files are not yet used for anything, and are just
   part of an ongoing migration process.
    * `main-app-attr-dialog-solo.litcoffee` (dropping the `main-app-`)
    * `main-app-basics-solo.` (dropping the `main-app-`)
    * `main-app-group-class-solo.` (dropping the `main-app-`)
    * `main-app-group-labels-solo.` (dropping the `main-app-`)
    * `main-app-group-validation-solo.` (dropping the `main-app-`)
    * `main-app-groups-solo.` (dropping the `main-app-`)
    * `main-app-import-export-solo.` (dropping the `main-app-`)
    * `main-app-proto-groups-solo.` (dropping the `main-app-`)
    * `main-app-settings-solo.` (dropping the `main-app-`)
    * `main-app-sharing-solo.` (dropping the `main-app-`)
    * `app.html`
 * [ ] Create a `source/assets` subfolder in the new repository and move
   into it the following files from the old repository.  Commit, but
   mention that these files are not yet used for anything, and are just
   part of an ongoing migration process.
    * `eqed/` folder
    * `input-method.js`
    * `jquery-splitter/` folder
    * `lz-string-1.3.3.js`
    * `icons/` folder
    * `images/` folder
 * [ ] Create a `unit-tests` subfolder in the new repository and move into
   it the following files from the old repository.  Commit, but mention that
   these files are not yet used for anything, and are just part of an
   ongoing migration process.
    * `app-test-utils.litcoffee
    * `domutils-spec.litcoffee`
    * `groupsplugin-change-spec.litcoffee`
    * `groupsplugin-spec.litcoffee`
    * `loadsaveplugin-spec.litcoffee`
    * `overlayplugin-spec.litcoffee`
    * `phantom-utils.litcoffee`
    * `tinymce-basics-spec.litcoffee`
    * `utils-spec.litcoffee`
    * `embedding/` folder

## Beginning to use the migrated code

 * [ ] Examine the code in the old `cake.litcoffee` file to determine how to
   compile the code from the new `source/modules/`, `source/plugins/`, and
   `source/` folders into a single compiled and minified JavaScript file
   that represents the Lurch Web Platform.  Implement that build process in
   Gulp as the `lwp` task, and ensure that the files it builds are named
   `lurch-web-platform.*` and are placed in the `site/` folder.
 * [ ] Test that this has succeeded by temporarily moving into the new repo
   the compiled versions of `simple-example*.*` from the old repo's `app/`
   folder, and verifying that the example still runs.  Do not keep these
   files in the new repo; move them out and *then* commit the changes.  (But
   keep the files so that you can use them in the next stage, below.)

## Creating demo apps as separate projects

As you do the following steps, keep track of exactly what you do to help you
repeat the process with other example apps.

 * [ ] Create a new project in the Lurch Math organization's GitHub space,
   named "Simple Example using the Lurch Web Platform"
   (`lwp-simple-example`).
 * [ ] Move into it the `simple-example*.*` files from the old repository's
   `app/` folder (or, preferably, the modified versions you created when
   testing the `lwp` build from the previous stage, above).  Commit.
 * [ ] Create a `README.md` that explains the repository briefly, and
   redirects readers into the main file's literate source code for more
   details.  Commit.
 * [ ] Create a build process that compiles and minifies the source code and
   places all the resulting files in the same root folder.  Commit.
 * [ ] Ensure GitHub is set up so that it uses as the project's web content
   the root directory of the master branch.
 * [ ] Verify that the simple example app loads correctly on GitHub and
   functions.  Make any changes needed to make this happen, and commit.

Repeat the above process for the remaining demo applications:

 * [ ] `complex-example*.*`
 * [ ] `math-example*.*`
 * [ ] `openmath-example*.*`
 * [ ] `lean-example*.*`
 * [ ] `sidebar-example*.*`

## Handling experimental content

 * [ ] Create a Gulp build process called `experimental` that compiles and
   minifies all the code in the `source/experimental/` folder in the new
   repository, and copies all the results into a `site/experimental/`
   directory, having first deleted everything in that folder.
 * [ ] Ensure that the HTML files in that directory correctly import the
   Lurch Web Platform from the parent directory (`site/`).
 * [ ] Ensure that the experimental HTML apps in that folder still function
   (or at least function as well as they do in the old repo).  Commit.

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

## Further work

Is it possible to make the Lurch Web Platform completely importable through
a CDN, with one JavaScript file, one CSS file, and some configuration code?
That would be the ideal goal for the end user.
