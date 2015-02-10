class ClickManager
  constructor: (@_appName) ->
    @isOutside          = true
    @ignoreNextIfNameIs = undefined

    _this = this
    #console.error 'set master click handler'
    $(document).on 'click.' + @_appName, (event) ->
      if not _this.callback?
        return true
      targetEl = event.target
      #console.log "click somewhere", _this.isOutside, targetEl, _this.ignoreNextIfNameIs
      if _this.ignoreNextIfNameIs? and _this.ignoreNextIfNameIs == targetEl.name
        # click event caused by label 'for' attr
        # should be ignored
        #console.log 'ignored', _this.ignoreNextIfNameIs, targetEl.tagName
        delete _this.ignoreNextIfNameIs
        if targetEl.tagName == 'INPUT'
          #console.log "focus", targetEl
          $(targetEl).focus()
        return true
      if _this.isOutside
        #console.log 'outside', _this.insideElement, targetEl
        _this.callback()
      #console.log targetEl, targetEl.tagName, targetEl.htmlFor
      if targetEl.tagName == 'LABEL' and targetEl.htmlFor?
        #console.log targetEl.htmlFor
        _this.ignoreNextIfNameIs = targetEl.htmlFor
      # next click would be outside
      _this.isOutside = true
      return true

  setCallback: (callback) ->
    @callback = callback

  setInsideElement: (element) ->
    @insideElement = element
    element.on 'click.' + @_appName, (event) =>
      #console.log 'inside', @isOutside
      @isOutside = false
      return true

  reinit: () ->
    if @insideElement
      @insideElement.off 'click.' + @_appName
    delete @callback
    delete @insideElement


module.exports = ClickManager