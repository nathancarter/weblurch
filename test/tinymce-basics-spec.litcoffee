
# Tests of basic TinyMCE Editor

Pull in the utility functions in `phantom-utils` that make it easier to
write the tests below.

    { phantomDescribe, pageDo, pageExpects, inPage,
      pageExpectsError, pageType, pageWaitFor } = require './phantom-utils'

<font color='red'>Right now this specification file is almost a stub.  It
will be enhanced later with real tests of the TinyMCE Editor.  (That is not
to say that this project will attempt to re-test a separate project, but
rather to verify that we have correctly imported it into this project such
that its basics are working.)  For now, it just does one or two simple tests
that can be extended.</font>

## Editor object

This is a very simple test that will be extended later.

    phantomDescribe 'TinyMCE active editor',
    './app/index.html', ->

### should exist

Just verify that the page contains an active TinyMCE editor.

        it 'should exist', inPage ->
            pageExpects -> tinymce.activeEditor

### should permit editing by typing

Just verify that typing some letters in the page changes the contents of the
editor.

        it 'should permit editing by typing', inPage ->
            pageWaitFor -> not tinymce.activeEditor.isHidden()
            pageExpects ( -> tinymce.activeEditor.getContent() ),
                'toEqual', ''
            pageType 'EXAMPLE'
            pageExpects ( -> tinymce.activeEditor.getContent() ),
                'toEqual', '<p>EXAMPLE</p>'
