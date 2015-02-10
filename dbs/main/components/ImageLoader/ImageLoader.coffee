class ImageLoader
  constructor: (@size, @onload) ->

  addDropZoneByClassName: (className) ->
    for dropzone in document.getElementsByClassName('dropzone')
      dropzone.addEventListener 'dragover', @handleDragOver,   false
      dropzone.addEventListener 'drop',     @handleFileSelect(), false

  handleDragOver: (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
    evt.dataTransfer.dropEffect = 'copy'

  handleFileSelect: ->
    onloadCallback = @onload
    size           = @size
    return (evt) ->
      evt.stopPropagation()
      evt.preventDefault()
      files  = evt.dataTransfer.files
      parent = $(this).parent()
      for f in files
        if not f.type.match('image.*')
          continue
        reader = new FileReader()
        # Closure to capture the file information.
        reader.onload = ( (theFile) ->
          return (e) ->
            # Render thumbnail.
            result = e.target.result
            img = new Image()
            img.src = e.target.result
            img.onload = ->
              # invisible image is loaded
              resize = (longest, other)->
                q = longest / size
                other = Math.round(other/q)
                longest = size
                return [longest, other]

              if img.height > img.width
                [height, width] = resize(img.height, img.width)
              else
                [width, height] = resize(img.width, img.height)
              imgCanvas = document.createElement("canvas")
              imgContext = imgCanvas.getContext("2d")
              imgCanvas.width = width
              imgCanvas.height = height
              imgContext.drawImage(img, 0, 0, width, height)
              dataUrl = imgCanvas.toDataURL(f.type)
              obj = {}
              obj[f.name] = {
                content_type: f.type
                length:       f.size
                data:         dataUrl.slice(dataUrl.indexOf(',') + 1)
              }
              onloadCallback(null, dataUrl, parent, JSON.stringify(obj))
        )(f)
        # Read in the image file as a data URL.
        reader.readAsDataURL(f)

module.exports = ImageLoader