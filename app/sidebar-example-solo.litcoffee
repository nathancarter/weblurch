
# Sidebar Example webLurch Application

## Overview

To know what's going on here, you should first have read the documenation
for [the simple example application](simple-example-solo.litcoffee) and then
for [the complex example application](complex-example-solo.litcoffee).
This application is more useful than either of those.

[A live version of this app is online here.](
http://nathancarter.github.io/weblurch/app/sidebar-example.html)

Set the app name with the same function we used in the simple example app.

    setAppName 'SidebarApp'

Add a source code link to the help menu, as in the simple example app.

    addHelpMenuSourceCodeLink 'app/sidebar-example-solo.litcoffee'

We also change the Help/About menu item to be specific to this demo app.

    window.helpAboutText =
        '<p>See the fully documented <a target="top"
        href="https://github.com/nathancarter/weblurch/blob/master/app/sidebar-example-solo.litcoffee"
        >source code for this demo app</a>.</p>'

## Infrastructure for code forms and categories

A code form is an abstract syntactic element that will be represented in the
document as a group, and represented in the right sidebar as code in a
programming language or text in a natural language.  Examples of code forms
include "assignment statement," "loop through a list," "two-part conditional
statement," "block of statements," and so on.

A category is simply a collection of code forms or other categories that
are topically related.  Thus the set of top-level categories is a forest.
It will be represented in the GUI as a set of toolbar buttons with menus
and optionally submenus whose leaf items represent code forms.

Both code forms and categories are given string names that are globally
unique across the application.  Register them with the functions below,
which update the following global data structure.

    formsAndCategories = { }

That data structure can be converted into a set of toolbar buttons and items
using the following functions.  First, one to compute the set of categories
that are not nested inside any others.

    topLevelCategories = ->
        allCategories = [ ]
        innerCategories = [ ]
        for own name, data of formsAndCategories
            if data.type is 'category'
                allCategories.push name
                for name in data.contents
                    if name not in innerCategories
                        innerCategories.push name
        ( name for name in allCategories when name not in innerCategories )

Next, one to compute an array of top-level menus built recursively from
those categories.  Note that we take measures to avoid infinite recursion
through cyclic data.

The parameter is optional.  If provided, it is a function mapping form names
to actions that should be taken when those forms are chosen.  If omitted,
it creates actions that insert boilerplate code at the cursor point, or if
there is a selection, then wrap the selection in the given group type.

    codeFormHierarchy = ( makeFormAction ) ->
        categoriesProcessed = [ ]

First, we define a function that can convert any code form to a menu (or
toolbar) item.

        formToMenuItem = ( name ) ->
            text : name
            onclick : if makeFormAction?
                -> makeFormAction name
            else
                ->
                    editor = tinymce.activeEditor
                    boilerplate = codeFormTranslators[name]['example']['en']

If the user has highlighed some document content, or if there is no
boilerplate code available to insert, then just wrap the current selection
(or the cursor) in an empty group of the given type.

                    if not boilerplate? or \
                       not editor?.selection?.getRng()?.collapsed
                        group = editor.Groups.groupCurrentSelection 'codexp'
                        group.set 'tagName', name
                        return

The following code inserts boilerplate content for the chosen code form.  It
expects HTML text, plus tags of the form `<X>...</X>` for any code form name
`X` (even if it is multiple words, unlike in normal XML).  For example, if
you have a form called "First name" you can create groups of that type with
pseudo-HTML code of the form `<First name>Jane</First name>`.

You can also use `<math>LaTeX code here</math>` to insert MathQuill
instances containing the given LaTeX mathematics.

The following loop simply finds tags of that form and replaces them with
tags for open and close groupers, keeping a stack of types and IDs so that
it generates correct code.

                    idStack = [ ]
                    idToTag = { }
                    html = ''
                    while nextTag = /<(\/?)([^>]+)>/.exec boilerplate
                        html += boilerplate[...nextTag.index]
                        if codeFormTranslators.hasOwnProperty nextTag[2]
                            if nextTag[1] is ''
                                openClose = 'open'
                                idStack.push id = editor.Groups.nextFreeId()
                            else
                                openClose = 'close'
                                id = idStack.pop()
                            idToTag[id] = nextTag[2]
                            html += grouperHTML 'codexp', openClose, id, no,
                                editor.Groups.groupTypes \
                                .codexp["#{openClose}Image"]
                        else
                            html += nextTag[0]
                        after = nextTag.index + nextTag[0].length
                        boilerplate = boilerplate[after...]
                    html += boilerplate
                    editor.insertContent html
                    for own id, tagName of idToTag
                        editor.Groups[id].set 'tagName', tagName

This final section of code creates MathQuill instances.

                    ( $ editor.getDoc() ).find( '.math' )
                    .each ( i, block ) ->
                        block.setAttribute 'contenteditable', 'false'
                        ( $ block ).addClass 'rendered-latex'
                        ( $ block ).mathquill()

That completes the function that converts any code form to a menu (or
toolbar) item.

Second, we define a function that converts any category to a menu (or
toolbar) item.

        categoryToMenuItem = ( name ) ->
            if name in categoriesProcessed
                text : name
                menu : [ ]
            else
                categoriesProcessed.push name
                text : name
                menu : for item in formsAndCategories[name].contents
                    toMenuItem item

The following function dispatches to either the function or category
method given above, based on the type of its input.

        toMenuItem = ( name ) ->
            if formsAndCategories[name].type is 'form'
                formToMenuItem name
            else
                categoryToMenuItem name

Finally, the actual work:  Apply that general function to every top-level
category in the hierarchy of code forms, returning the resulting list of
menu/toolbar items.

        toMenuItem category for category in topLevelCategories()

Now we provide a function that adds that set of top-level menus to the app
toolbar.  It calls the previous function to convert the form hierarchy into
a menu/toolbar hierarchy, then adds it to the toolbar.

    addFormsAndCategoriesToToolbar = ->
        window.groupToolbarButtons = { }
        count = 1
        for menu in codeFormHierarchy()
            menu.type = 'menubutton'
            window.groupToolbarButtons["category#{count++}"] = menu

It also adds one new toolbar item, for toggling the visibility of the code
sidebar.

        window.groupToolbarButtons.toggleSidebar =
            text : 'Toggle code view'
            onclick : ->
                sidebar = document.getElementById 'sidebar'
                splitbar = window.splitter.find( '.vsplitter' ).get 0
                if sidebar.style.display is 'none'
                    sidebar.style.display = 'block'
                    splitbar.style.display = 'block'
                    splitter.position splitter.position()
                else
                    sidebar.style.display = 'none'
                    splitbar.style.display = 'none'
                    window.editorContainer.style.width = '100%'

A code form may come with an optional validator.  This can be a function to
be run to validate the group, or if none is provided then all instances pass
validation; no checks are performed.  Or the validator can instead be an
array of types (names of other code forms), each with an optional name, in
which case a validation function will be provided, checking group contents
against this array as a function signature.

Validators will take a group as input, and a boolean flag as a second
argument, called "verbose."  They must return objects with these members:
 * `result`: a string, "valid" or "invalid"
 * `message`: a plain text string briefly describing the reason for the
   result
 * `verbose`: only necessary if the second argument was true, an HTML string
   describing the reason for the result in much more detail
 * Other members in the object are permitted for application-specific needs.

This function returns its first parameter, so that calls to it can be nested
inside calls to `window.registerCategory`, defined below.

    window.registerCodeForm = ( name, validator ) ->
        formsAndCategories[name] =
            type : 'form'
            validator : validator
        addFormsAndCategoriesToToolbar()
        name

A category is simply a name and an array of strings, the names of categories
or code forms inside this category.

This function returns its first parameter, so that calls to it can be nested
inside others.

    window.registerCategory = ( name, contents ) ->
        formsAndCategories[name] =
            type : 'category'
            contents : contents
        addFormsAndCategoriesToToolbar()
        name

## Infrastructure for translators

A translator maps an instance of a form to another language.  It has these
attributes.
 * form: a text string, the name of the code form that this translator can
   process, which should be registered with `registerCodeForm`, above.
 * language: a text string, globally unique, either the name of a
   programming language or [the standard code for a natural  language](http://www.metamodpro.com/browser-language-codes).
 * output: a text string, one of three choices, "code," "structure," or
   "explanation", with the following meanings.
    * "Code" means the translator outputs code in the language given in the
      previous attribute.
    * "Structure" means the translator outputs HTML that can be used in the
      document to phrase the interior contents of the group accurately and
      readably.
    * "Explanation" means the translator outputs HTML that can be used in
      popup dialogs to help teach users the meanings of the code forms in
      the document, and will generally be more verbose than structure
      translators, and may use HTML more freely.
 * translator: a way to convert an instance of the form into the target
   language.  This may be given in one of two ways.
    * It may be a function that takes two parameters, the first being the
      form instance, which is a group in the document, and the second being
      a function that can be called recursively on child groups to translate
      them.  (That function will dispatch the correct code form translator
      for the chlid group, so that each translator does not need to figure
      out how to do so on its own.)  If the first parameter is null,
      generic or boilerplate code should be generated, using `__A__`,
      `__B__`, `__C__`, and so on as parameter placeholders.  Such a
      function is permitted to read and re-use data stored in a group during
      validation.  If at all possible, translators should attempt to give
      output.  Even if the form of the group or its inner groups is
      invalid, it would generally be better to create bad output code,
      including comments that say why it's bad and won't run, to maximize
      user feedback and understanding.
    * It may be a text string containing placeholders of the form `__A__`,
      `__B__`, `__C__`, and so on, for which the results of recursive calls
      on the child groups will be replaced.

We store translators in this global variable.

    codeFormTranslators = { }

Register a new translator using the following function.

    window.registerTranslator = ( form, language, output, translator ) ->
        codeFormTranslators[form] ?= { }
        codeFormTranslators[form][output] ?= { }
        codeFormTranslators[form][output][language] ?= translator

Perform translation with the following function.  The parameters are named
just as in the explanation at the top of this section.  So, for example, you
might call `runTranslation G, 'en', 'explanation'` or
`runTranslation G, 'javascript', 'code'`.

    runTranslation = ( group, language, output ) ->
        recur = ( g ) -> runTranslation g, language, output

Verify that there exists a translator of the type requested.

        formName = group.get 'tagName'
        if not codeFormTranslators.hasOwnProperty formName
            return "Translation error: Form #{formName} has no translators
                registered"
        if not codeFormTranslators[formName].hasOwnProperty output
            return "Translation error: Form #{formName} has no translators
                of type #{output} registered"
        if not codeFormTranslators[formName][output].hasOwnProperty language
            return "Translation error: Form #{formName} has no #{language}
                translators of type #{output} registered"
        translator = codeFormTranslators[formName][output][language]

For string translators, iteratively replace `__A__`-type patterns with the
results of recursive calls on child groups.

        if typeof translator is 'string'
            letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            numArgs = 0
            while -1 < translator.indexOf "__#{letters[numArgs]}__"
                numArgs++
            if group.children.length isnt numArgs
                return "Translation error: Form #{formName} requires
                    #{numArgs} parts, but contains only
                    #{group.children.length}"
            for child, index in group.children
                pattern = "__#{letters[index]}__"
                childText = recur child
                return childText if /^Translation error/.test childText
                translator = translator.replace RegExp( pattern, 'g' ),
                    childText
            translator

Otherwise the translator is a function that can be run on its own.

        else
            try
                translator group, recur
            catch e
                console.log 'User-defined translator error:', e

## Event handlers

Handler for when users edit the contents of a group.

    window.groupContentsChanged = ( group, firstTime ) ->
        window.validate group

Handler for when users remove a group.

    window.groupDeleted = ( group ) ->
        if group.parent?
            if group.parent.children[0]
                window.validate group.parent.children[0]
        else
            if group.plugin?.topLevel[0]
                window.validate group.plugin.topLevel[0]

Handler for both the context menu and the tag menu of a group.  It creates
three different items for such menus, each documented separately below.

    menuItems = ( group ) ->
        [

First, a menu item for changing the type of the selected group to any other
form type.

            text : 'Change this to...'
            menu : codeFormHierarchy ( formName ) ->
                group.set 'tagName', formName
        ,

Second, a menu item that asks the app to explain the meaning of the code
form selected.  This pops up a modal dialog displaying in HTML form all the
various explanations of the code form on which this was invoked.

            text : 'Explain this...'
            onclick : ->
                explanation = ''
                for language in allNaturalLanguages()
                    explanation +=
                        "<h2>Language: #{language}</h2>\n" + \
                        groupToExplanation group, language
                tinymce.activeEditor.Dialogs.alert
                    title : 'Explanation of one structure'
                    message : addMathQuillCSS explanation
                    width : 600
                    height : 450
        ,

Third, a menu item that functions just like the previous, but it explains
all top-level code forms in the entire document, in order.  This provides an
interpretation of all the meaning in the document.

            text : 'Explain all...'
            onclick : ->
                explanation = ''
                for language in allNaturalLanguages()
                    explanation += "<h2>Language: #{language}</h2>\n"
                    for group in tinymce.activeEditor.Groups.topLevel
                        if explanation isnt '' then explanation += '<hr>'
                        explanation += groupToExplanation group, language
                tinymce.activeEditor.Dialogs.alert
                    title : 'Explanation of all structures'
                    message : addMathQuillCSS explanation
                    width : 600
                    height : 450
        ]

Utilities used by the functions above:

Get all languages that appear in any registered "explanation" form, which
should therefore be natural languages (such as English) as opposed to
programming languages (such as Python).

    allNaturalLanguages = ->
        languages = [ ]
        for own formName, data of codeFormTranslators
            for own language of data['explanation']
                if language not in languages then languages.push language
        languages

The following function wraps given HTML in tags that import two necessary
CSS files for appropriate viewing of document content.  The first is the
MathQuill CSS for viewing typeset equations.  The second is the CSS for the
Groups plugin, for viewing open and close groupers.

    addMathQuillCSS = ( html ) ->
        currentPath = window.location.href.split( '/' )[...-1].join '/'
        "<html>
            <head><link rel='stylesheet'
                        href='#{currentPath}/eqed/mathquill.css'></head>
            <head><link rel='stylesheet'
                        href='#{currentPath}/groupsplugin.css'></head>
            <body>#{html}</body>
        </html>"

Convert a group in the document into an explanation of it in the given
natural language.

    groupToExplanation = ( group, language ) ->
        "<h4>Structure:</h4>\n
        <p style='margin-left: 2em;'>#{group.groupAsHTML()}</p>\n
        <h4>Explanation:</h4>\n
        <p style='margin-left: 2em;'
            >#{runTranslation group, language, 'explanation'}</p>\n"

## Define one group type

    window.groupTypes = [

Basic appearance attributes for the group:

        name : 'codexp'
        color : '#6666cc'
        text : 'Code expression'
        tooltip : 'Tag the selection'
        imageHTML : '<font color="#6666cc">[ ]</font>'
        openImageHTML : '<font color="#6666cc">[</font>'
        closeImageHTML : '<font color="#6666cc">]</font>'
        onToolbar : no

Install event handlers, most of which are defined in code further below.

        contentsChanged : window.groupContentsChanged
        deleted : window.groupDeleted
        tagContents : ( group ) -> group.get 'tagName'
        tagMenuItems : ( group ) -> menuItems group
        contextMenuItems : ( group ) -> menuItems group
    ]

## Validating groups

We will need three functions, one for marking a group as without problems,
one for marking a group as having problems (with explanations of them), and
one for detecting whether a group has problems.

    markGroupRight = ( group ) ->
        group.set 'valid', yes
        group.clear 'closeDecoration'
        group.clear 'closeHoverText'
        window.createSidebarContent()
    markGroupWrong = ( group, reason ) ->
        group.set 'valid', no
        group.set 'closeDecoration', '<font color="red">&#10006;</font>'
        group.set 'closeHoverText', reason
        window.createSidebarContent()
    markGroupWith = ( group, validationData ) ->
        group.set 'validationResult', validationData
        if validationData.result is 'valid'
            markGroupRight group
        else
            markGroupWrong group, validationData.message
    isGroupRight = ( group ) -> group.get 'valid'

This function validates the given group, and stores the results in the
group's closing tag using one of the above functions.

    window.validate = ( group, verbose ) ->

If the group does not even have a children array, then it probably just
appeared, and is still being initialized.  In that case, just do validation
in 100ms isntead of now.

        if not group.children
            setTimeout ( -> window.validate group ), 100
            return

If this group does not have a tag name, we cannot even tell if it belongs
here or not, and it cannot be converted to source code.  That is a problem.

        if not ( groupTag = group.get 'tagName' )?
            return markGroupWith group,
                result : 'invalid'
                message : "Each group must have a tag, but this one does
                    not.  Add a tag using the context menu."

If the group does have a tag name, run the validation routine for that code
form, and add any problems it reports to our list of problems.  We convert
array validators into functions that check inner groups against that array
as a function signature.  Each entry in the signature must be a string
containing either a single type or a slash-separated list of types (e.g.,
"A/B/C") to indicate multiple options.

        validator = formsAndCategories[groupTag].validator
        if validator instanceof Array
            validation =
                result : 'valid'
                message : 'All inner groups have the correct types.'
            args = group.children
            if validator.length isnt args.length
                return markGroupWith group,
                    result : 'invalid'
                    message : "This form needs #{validator.length} parts:
                        #{validator.join ', '}."
            for arg, index in args
                argType = arg.get 'tagName'
                options = validator[index].split '/'
                if argType not in options
                    return markGroupWith group,
                        result : 'invalid'
                        message : "Part #{index+1} must be of type
                            #{validator[index]}, but it is of type
                            #{argType} instead."

Or if they gave us a validator function, run it.

        else
            validation = validator group, verbose

And store the result, valid or invalid, which automatically updates the
visual feedback.

        markGroupWith group, validation

## GUI modifications and setup

    window.fullScreenEditor = no
    window.editorContainer = -> document.getElementById 'editorContainer'
    window.afterEditorReady = ( editor ) ->

Install a resize handler.

        mainContainer = window.editorContainer.parentNode
        handleResize = ->
            editorContainer = editor.getContainer()
            iframe = editor.getContentAreaContainer().firstChild
            vp = tinymce.DOM.getViewPort()
            iframe.style.width = iframe.style.height =
                mainContainer.style.height = '100%'
            editorContainer.style.width = editorContainer.style.height = ''
            iframe.style.height = mainContainer.clientHeight - 2 \
                - ( editorContainer.clientHeight - iframe.clientHeight )
            window.scrollTo vp.x, vp.y

Create the splitter, which will notice that the editor is adjacent to a
second DIV defined in [sidebar-example.html], and resize them appropriately.

        window.splitter = ( $ mainContainer ).split
            orientation : 'vertical'
            limit : 100
            position : '75%'
            onDrag : handleResize
        ( $ window ).resize handleResize
        handleResize()
        window.createSidebarContent()

## Filling the sidebar with content

The main function that does so, iterating through all top-level groups in
the document, and calling an auxiliary function below on each.  For some
languages, it adds extra functionality.

    window.createSidebarContent = ->
        sidebar = document.getElementById 'sidebar'

The heading of the sidebar contains a selector for the output (programming)
language, and links to click to either run the code (if and only if it is
JavaScript) or to copy the code to the clipboard.

        sidebar.innerHTML = '''
            <div style="border-bottom: solid 1px black;
                        text-align: center;">
                <p>Choose a language:
                <select onchange='updateSidebarContent();'
                        id='languagePicker'>
                    <option value='javascript'>JavaScript</option>
                    <option value='python'>Python</option>
                    <option value='r'>R</option>
                </select></p>
                <p id='runJSLink'><a href='#'
                    onclick='runGeneratedJavaScript();'
                    >Run this code</a></p>
                <p><a href='#' onclick='copyGeneratedCode();'
                    >Copy this code</a></p>
            </div>
            '''
        ( $ '#languagePicker' ).val lastLanguageChoice
        ( $ '#runJSLink' ).get( 0 ).style.display = \
            if lastLanguageChoice is 'javascript' then 'block' else 'none'

We now regenerate the content of the sidebar by looping through the
top-level groups in the document, calling `createSidebarEntryHTML` on each,
and wrapping it in a DIV with an appropriate ID and click handler.  The
click handler makes it so that clicking one of the generated-code DIVs
highlights the corresponding structure in the user's document.

        window.lastSidebarContent = ''
        for group in tinymce.activeEditor.Groups.topLevel
            entry = document.createElement 'div'
            entry.setAttribute 'id', "codeForGroup#{group.id()}"
            ( $ entry ).click group.id(), ( event ) ->
                group = tinymce.activeEditor.Groups[event.data]
                tinymce.activeEditor.selection.setRng group.innerRange()
            entry.style.padding = '1em'
            entry.style.borderBottom = 'dotted 1px black'
            entry.innerHTML = window.createSidebarEntryHTML group
            sidebar.appendChild entry
            lastSidebarContent += entry.textContent + '\n'
        ( $ sidebar ).find( 'pre' ).each ( i, block ) ->
            hljs.highlightBlock block

The default output language is JavaScript, but whenever the user changes it,
we will regenerate all the contents of the sidebar based on their choice.

    lastLanguageChoice = 'javascript'
    window.updateSidebarContent = ->
        lastLanguageChoice = ( $ '#languagePicker' ).val()
        createSidebarContent()

When the user clicks the "Run" button, it is safe to simply call the
notorious JavaScript `eval` in this case, because this demo app never
speaks to a server side, and thus any harm the user wanted to do via code
injection attacks could simply be done from their browser's console anyway.

    window.runGeneratedJavaScript = ->
        try
            eval lastSidebarContent
        catch e
            alert "Error when running code:\n\n#{e.message}"

When the user clicks the "Copy" button, we place the code into a modal
dialog and select it, so that the user can easily press Ctrl+C and then
close the window.

    window.copyGeneratedCode = ->
        tinymce.activeEditor.Dialogs.alert
            title : 'Copy the code, then close'
            width : 600
            message : """
                <textarea id='codeToCopy'
                          style='width: 100%; height: 100%;
                                 font-family: monospace;'
                    >#{lastSidebarContent}</textarea>
                <script>
                    var T = document.getElementById( 'codeToCopy' );
                    T.select();
                    T.focus();
                </script>
                """

The above function uses the following to create each entry, based on one
given top-level group.  It should encode the entirety of that top-level
group, and return it as HTML to be placed inside a DIV.

    window.createSidebarEntryHTML = ( group ) ->
        code = runTranslation group, lastLanguageChoice, 'code'
        comment = codeFormTranslators['COMMENT']['code'][lastLanguageChoice]
        result = comment.replace '__A__', niceText group.contentNodes()...
        result += '\n' + if not /^Translation error/.test code
            code
        else
            comment.replace '__A__', code
        "<pre class='javascript'>#{result}</pre>"

The following utility function takes a list of HTML nodes (usually called on
the content nodes of some group) and converts them to plain text, with
special handling of MathQuill instances, converting them to their LaTeX form
(surrounded by dollar signs).

    niceText = ( nodes... ) ->
        result = ''
        for node in nodes
            if node?.nodeType is 3 # HTML Text node
                result += node.textContent
            else if ( $ node ).hasClass 'mathquill-rendered-math'
                result += node.childNodes[0].textContent
            else
                result += niceText node.childNodes...
        result

Every 0.1 seconds, highlight the DIV in the sidebar that corresponds to the
current cursor location, if there is such a DIV.  If there isn't, highlight
none of them.

    setInterval ->
        range = tinymce.activeEditor.selection.getRng()
        ( $ sidebar ).find( 'div' ).css 'background-color', '#fff'
        if group = tinymce.activeEditor.Groups.groupAboveSelection range
            while group.parent then group = group.parent
            ( $ "\#codeForGroup#{group.id()}" ).css 'background-color',
                '#eee'
    , 100

The following function used to be able to open any given JavaScript code in
a new JSFiddle.  It is modeled after code by the creator of JSFiddle,
[located here](http://jsfiddle.net/zalun/sthmj/?utm_source=website&utm_medium=embed&utm_campaign=sthmj),
but that code seems to no longer function (even on that fiddle), and so this
code is not currently used in this app.  I leave it here for reference, in
case that fiddle gets fixed, then this can be updated to use it.

    window.openInJSFiddle = ( jsCode ) ->
        nbsp = String.fromCharCode 160
        jsCode = jsCode.replace RegExp( nbsp, 'g' ), ' '
        form = document.createElement 'form'
        form.setAttribute 'method', 'post'
        form.setAttribute 'action',
            'http://jsfiddle.net/api/post/mootools/1.2/dependencies/more/'
        form.setAttribute 'target', '_blank'
        form.style.display = 'none'
        form.appendChild makeSelect 'panel_html', 0 : 'HTML'
        form.appendChild makeTextarea 'html'
        form.appendChild makeSelect 'panel_js',
            0 : 'JavaScript'
            1 : 'CoffeeScript'
            2 : 'JavaScript 1.7'
        form.appendChild makeTextarea 'js', jsCode
        form.appendChild makeSelect 'panel_css', 0 : 'CSS', 1 : 'SCSS'
        form.appendChild makeTextarea 'css'
        form.appendChild makeText 'title', 'Fiddle Title Here'
        form.appendChild makeTextarea 'description',
            'Fiddle Description Here'
        form.appendChild makeTextarea 'resources'
        form.appendChild makeText 'dtd', 'html 4'
        form.appendChild makeText 'wrap', 'l'
        document.body.appendChild form
        form.submit()
        document.body.removeChild form

The previous function uses the following utilities.

Create an HTML "select" element with the given value-to-text mapping.

    makeSelect = ( name, options ) ->
        result = document.createElement 'select'
        result.setAttribute 'name', name
        for own value, representation of options
            option = document.createElement 'option'
            option.setAttribute 'value', value
            option.innerHTML = representation
            result.appendChild option
        result

Create an HTML text area with the given content.

    makeTextarea = ( name, content ) ->
        result = document.createElement 'textarea'
        result.setAttribute 'name', name
        result.innerHTML = content or ''
        result

Create an HTML text input with the given content.

    makeText = ( name, value ) ->
        result = document.createElement 'input'
        result.setAttribute 'type', 'text'
        result.setAttribute 'name', name
        result.setAttribute 'value', value
        result
