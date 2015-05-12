
# Tests of Overlay plugin for TinyMCE Editor

Pull in the utility functions in `phantom-utils` that make it easier to
write the tests below.

    { phantomDescribe, pageDo, pageExpects, inPage,
      pageExpectsError } = require './phantom-utils'

<font color='red'>Right now this specification file is almost a stub.  It
will be enhanced later with real tests of the Overlay plugin.  For now, it
just does one or two simple tests that can be replaced later.</font>

## Overlay plugin

This is a very simple test that will be extended later.

    phantomDescribe 'TinyMCE Overlay plugin',
    './app/index.html', ->

### should be installed

Just verify that the active TinyMCE editor has a Overlay plugin.

        it 'should be installed', inPage ->
            pageExpects -> tinymce.activeEditor.Overlay
