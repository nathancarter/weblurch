
# OpenMath Content Dictionary Example webLurch Application

## Overview

To know what's going on here, you should first have read the documenation
for [the simple example application](simple-example.solo.litcoffee) and then
for [the complex example application](complex-example.solo.litcoffee).
This application is more useful than either of those.

    setAppName 'OM-CD-Writer'
    window.menuBarIcon = { }

[See a live version of this application online here.](
http://nathancarter.github.io/weblurch/app/openmath-example.html)

## Define one group type

For information on what this code does, see the simple example linked to
above.  At present this file is a stub, so nothing special happens here yet.

    window.groupTypes = [

Basic appearance attributes for the group:

        name : 'tag'
        text : 'Content Dictionary Tag'
        tooltip : 'Tag the selection'
        imageHTML : '<font color="#999999"><b>{ }</b></font>'
        openImageHTML : '<font color="#999999"><b>{</b></font>'
        closeImageHTML : '<font color="#999999"><b>}</b></font>'

The very important content changed event handler:

        contentsChanged : ( group, firstTime ) ->

If the group has just come into existence, we must check to see what its
default tag type should be, and initialize it to that default.  We must do
this on a delay, because when `firstTime` is true, the group does not even
yet have its parent pointer set.

            if firstTime
                setTimeout ( -> window.initializeGroupTag group ), 0

The tag name for a group is what shows up in its bubble tag.

        tagContents : ( group ) -> group.get 'tagName'
    ]

## Define the XML tags for this application

    window.setTagData
        CD :
            topLevel : yes
            defaultChild : 'Description'
