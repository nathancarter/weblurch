
# Canvas Utilities

This module defines several functions useful when working with the HTML5
Canvas.

## Curved arrows

The following function draws an arrow along a cubic Bézier curve.  It
requires the four control points, each as an (x,y) pair.  The arrowhead
size can be adjusted with the final parameter, the altitude of the arrowhead
triangle, measured in pixels

    CanvasRenderingContext2D::bezierArrow =
    ( x1, y1, x2, y2, x3, y3, x4, y4, size = 10 ) ->
        unit = ( x, y ) ->
            length = Math.sqrt( x*x + y*y ) or 1
            x : x/length, y : y/length
        @beginPath()
        @moveTo x1, y1
        @bezierCurveTo x2, y2, x3, y3, x4, y4
        nearEnd =
            x : @applyBezier x1, x2, x3, x4, 0.9
            y : @applyBezier y1, y2, y3, y4, 0.9
        nearEndVector = x : x4 - nearEnd.x, y : y4 - nearEnd.y
        localY = unit nearEndVector.x, nearEndVector.y
        localY.x *= size * 0.7
        localY.y *= size
        localX = x : localY.y, y : -localY.x
        @moveTo x4-localX.x-localY.x, y4-localX.y-localY.y
        @lineTo x4, y4
        @lineTo x4+localX.x-localY.x, y4+localX.y-localY.y

The following utility function is useful to the function above, as well as
to other functions in the codebase.

    CanvasRenderingContext2D::applyBezier = ( C1, C2, C3, C4, t ) ->
        ( 1-t )**3*C1 + 3*( 1-t )**2*t*C2 + 3*( 1-t )*t**2*C3 + t**3*C4

## Rounded rectangles

The following function traces a rounded rectangle path in the context.  It
sits entirely inside the rectangle from the upper-left point (x1,y1) to the
lower-right point (x2,y2), and its corners are quarter circles with the
given radius.

It calls `beginPath()` and `closePath()` but does not stroke or fill the
path.  You should do whichever (or both) of those you like.

    CanvasRenderingContext2D::roundedRect = ( x1, y1, x2, y2, radius ) ->
        @beginPath()
        @moveTo x1 + radius, y1
        @lineTo x2 - radius, y1
        @arcTo x2, y1, x2, y1 + radius, radius
        @lineTo x2, y2 - radius
        @arcTo x2, y2, x2 - radius, y2, radius
        @lineTo x1 + radius, y2
        @arcTo x1, y2, x1, y2 - radius, radius
        @lineTo x1, y1 + radius
        @arcTo x1, y1, x1 + radius, y1, radius
        @closePath()

## Rounded zones

The following function traces a rounded rectangle that extends from
character in a word processor to another, which are on different lines, and
thus the rectangle is stretched.  Rather than looking like a normal
rectangle, the effect looks like the following illustration, with X
indicating text and lines indicating the boundaries of the rounded zone.

```
  x x x x x x x x x x x x
       /------------------+
  x x x|x x x x x x x x x |
+------+                  |
| x x x x x x x x x x x x |
|          +--------------|
| x x x x x|x x x x x x x
+----------/
  x x x x x x x x x x x x
```

The corners marked with slashes are to be rounded, and the other corners are
square.  The left and right edges are the edges of the canvas, minus the
given values of `leftMargin` and `rightMargin`.  The y coordinates of the
two interior horizontal lines are given by `upperLine` and `lowerLine`,
respectively.

It calls `beginPath()` and `closePath()` but does not stroke or fill the
path.  You should do whichever (or both) of those you like.

    CanvasRenderingContext2D::roundedZone = ( x1, y1, x2, y2,
    upperLine, lowerLine, leftMargin, rightMargin, radius ) ->
        @beginPath()
        @moveTo x1 + radius, y1
        @lineTo @canvas.width - rightMargin, y1
        @lineTo @canvas.width - rightMargin, lowerLine
        @lineTo x2, lowerLine
        @lineTo x2, y2 - radius
        @arcTo x2, y2, x2 - radius, y2, radius
        @lineTo leftMargin, y2
        @lineTo leftMargin, upperLine
        @lineTo x1, upperLine
        @lineTo x1, y1 + radius
        @arcTo x1, y1, x1 + radius, y1, radius
        @closePath()

## Rectangle overlapping

The following routine computes whether two rectangles collide.  The first is
given by upper-left corner (x1,y1) and lower-right corner (x2,y2).  The
second is given by upper-left corner (x3,y3) and lower-right corner (x4,y4).
The routine returns true iff the interior of the rectangles intersect.
(If they intersect only on their boundaries, false is returned.)

    window.rectanglesCollide = ( x1, y1, x2, y2, x3, y3, x4, y4 ) ->
        not ( x3 >= x2 or x4 <= x1 or y3 >= y2 or y4 <= y1 )

## Rendering HTML to Images and/or Canvases

This section provides several routines related to converting arbitrary HTML
into image data in various forms (SVG, Blob, object URLs, base64 encoding)
and for drawing such forms onto an HTML canvas.

This first function converts arbitrary (strictly well-formed!) HTML into a
Blob containing SVG XML for the given HTML.  This makes use of the
document's body, it can only be called once page loading has completed.

    window.svgBlobForHTML = ( html, style = 'font-size:12px' ) ->

First, compute its dimensions using a temporary span in the document.

        span = document.createElement 'span'
        span.setAttribute 'style', style
        span.innerHTML = html
        document.body.appendChild span
        span = $ span
        width = span.width() + 2 # cushion for error
        height = span.height() + 2 # cushion for error
        span.remove()

Then build an SVG and store it as blob data.  (See the next function in this
file for how the blob is built.)

        window.makeBlob "<svg xmlns='http://www.w3.org/2000/svg'
            width='#{width}' height='#{height}'><foreignObject width='100%'
            height='100%'><div xmlns='http://www.w3.org/1999/xhtml'
            style='#{style}'>#{html}</div></foreignObject></svg>",
            'image/svg+xml;charset=utf-8'

The previous function makes use of the following cross-browser Blob-building
utility gleaned from [this StackOverflow
post](http://stackoverflow.com/questions/15293694/blob-constructor-browser-compatibility).

    window.makeBlob = ( data, type ) ->
        try
            new Blob [ data ], type : type
        catch e
            # TypeError old chrome and FF
            window.BlobBuilder = window.BlobBuilder ?
                                 window.WebKitBlobBuilder ?
                                 window.MozBlobBuilder ?
                                 window.MSBlobBuilder
            if e.name is 'TypeError' and window.BlobBuilder?
                bb = new BlobBuilder()
                bb.append data.buffer
                bb.getBlob type
            else if e.name is 'InvalidStateError'
                # InvalidStateError (tested on FF13 WinXP)
                new Blob [ data.buffer ], type : type

Now we move on to a routine for rendering arbitrary HTML to a canvas, but
there are some preliminaries we need to build first.

Canvas rendering happens asynchronously.  If the routine returns false, then
it did not render, but rather began preparing the HTML for rendering (by
initiating the background rendering of the HTML to an image).  Those results
will then be cached, so later calls to this routine will return true,
indicating success (immediate rendering).

To support this, we need a cache.  The following routines define the cache.

    drawHTMLCache = order : [ ], maxSize : 100
    cacheLookup = ( html, style ) ->
        key = JSON.stringify [ html, style ]
        if drawHTMLCache.hasOwnProperty key then drawHTMLCache[key] \
            else null
    addToCache = ( html, style, image ) ->
        key = JSON.stringify [ html, style ]
        drawHTMLCache[key] = image
        markUsed html, style
    markUsed = ( html, style ) ->
        key = JSON.stringify [ html, style ]
        if ( index = drawHTMLCache.order.indexOf key ) > -1
            drawHTMLCache.order.splice index, 1
        drawHTMLCache.order.unshift key
        pruneCache()
    pruneCache = ->
        while drawHTMLCache.order.length > drawHTMLCache.maxSize
            delete drawHTMLCache[drawHTMLCache.order.pop()]

And now, the rendering routine, which is based on code taken from [this MDN
article](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Drawing_DOM_objects_into_a_canvas).

    CanvasRenderingContext2D::drawHTML =
    ( html, x, y, style = 'font-size:12px' ) ->

If the given HTML has already been rendered to an image that remains in the
cache, just use that immediately and return success.

        if image = cacheLookup html, style
            @drawImage image, x, y
            markUsed html, style
            return yes

Otherwise, begin rendering that HTML to an image, for later insertion into
the cache, and return (temporary) failure.  Start by creating the image and
assign its URL, so that when rendering completes asynchronously, we can
store the results in the cache.

        url = objectURLForBlob svgBlobForHTML html, style
        image = new Image()
        image.onload = ->
            addToCache html, style, image
            ( window.URL ? window.webkitURL ? window ).revokeObjectURL url
        image.onerror = ( error ) ->
            addToCache html, style, new Image()
            console.log 'Failed to load SVG with this <foreignObject> div
                content:', html
        image.src = url
        no

The following routine queries the same cache to determine the width and
height of a given piece of HTML that could be rendered to the canvas.  If
the HTML is not in the cache, this returns null.  Otherwise, it returns an
object with width and height attributes.

    CanvasRenderingContext2D::measureHTML =
    ( html, style = 'font-size:12px' ) ->
        if image = cacheLookup html, style
            markUsed html, style
            width : image.width
            height : image.height
        else
            @drawHTML html, 0, 0, style # forces caching
            null

The `drawHTML` function makes use of the following routine, which converts a
Blob into an image URL using `createObjectURL`.

    window.objectURLForBlob = ( blob ) ->
        ( window.URL ? window.webkitURL ? window ).createObjectURL blob

The following does the same thing, but creates a URL with the base-64
encoding of the Blob in it.  This must be done asynchronously, but then the
URL can be used anywhere, not just in this script environment.  The result
is sent to the given callback.

    window.base64URLForBlob = ( blob, callback ) ->
        reader = new FileReader
        reader.onload = ( event ) -> callback event.target.result
        reader.readAsDataURL blob

As long as we're here, let's also create the inverse for this function,
which takes a base64 URL and converts it into a Blob.  This one is
synchronous.

    window.blobForBase64URL = ( url ) ->
        # For this code, thanks to:
        # http://stackoverflow.com/a/12300351/670492
        byteString = atob url.split( ',' )[1]
        mimeString = url.split( ',' )[0].split( ':' )[1].split( ';' )[0]
        ab = new ArrayBuffer byteString.length
        ia = new Uint8Array ab
        for i in [0...byteString.length]
            ia[i] = byteString.charCodeAt i
        window.makeBlob ab, mimeString
