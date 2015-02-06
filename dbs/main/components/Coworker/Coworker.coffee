kansoRequire = require

#TODO: use "real" rows and not .row
# or switch to flex

getMaxHeightOfRow = (row) ->
  maxHeight = 0
  $('.coworker', row).each ->
    #console.log maxHeight, parent
    #$(this).css({'height':'auto'})
    if $(this).outerHeight() > maxHeight
      maxHeight = $(this).outerHeight()
  return maxHeight

adjustColSize = (coworker, maxHeight) ->
  coworker = $(coworker)
  if not maxHeight?
    maxHeight = getMaxHeightOfRow(coworker.closest('.row'))
  coworker.css('height', maxHeight)


adjustAllColSizes = () ->
  $('.row').has('.coworker').each (i, row) ->
    #console.log 'row', parent
    maxHeight = getMaxHeightOfRow(row)
    #console.log "max", maxHeight
    $('.coworker', row).each ->
      adjustColSize(this, maxHeight)


class Coworker
  constructor: (@_appName, @clickManager, @session) ->
    @skills =      {}
    @filterValue = ''
    _this = this

    _this.close($('.opened .coworker'))
    adjustAllColSizes()
    $(window).resize(adjustAllColSizes)

    $(document).on  'click.' + @_appName, 'a.openCoworker', (event) ->
      coworkerElement = $(this).closest('.coworker')
      _this.open(coworkerElement)
      return false

    $(document).on 'click.' + @_appName, 'a.new-coworker', (event) ->
      coworkerElement = $(this).closest('.coworker')
      _this.open(coworkerElement)
      _this.enterEditMode(coworkerElement)
      $('a.new-coworker', coworkerElement).hide()
      return false

    $(document).on 'click.' + @_appName, '.editButton', (event) ->
      coworkerElement = $(this).closest('.coworker')
      _this.enterEditMode(coworkerElement)


    $('.coworker').each (coworkerIndex, coworker) =>
      $('.skill', $(coworker)).each (i, skill) =>
        unless @skills[skill.textContent]
          @skills[skill.textContent] = 0
        @skills[skill.textContent] += 1

    $('.coworkerfilter').autocomplete({
      source:    Object.keys(@skills)
      autoFocus: true

      select: (event, ui) ->
        _this.showOnlyMatchingSkill(ui.item.value)
    })
    .on('keyup.' + @_appName, (event) ->
      if this.value isnt _this.filterValue
        _this.showOnlyMatchingSkill(this.value)
      _this.filterValue = this.value
    )

    doNotHandleNextSubmit = false
    $('.coworker form').on 'submit.' + @_appName, (ev) ->
      #console.log 'myOnSubmit', $(this).attr('action')
      if doNotHandleNextSubmit? and doNotHandleNextSubmit
        #console.log 'not handled'
        return true
      ev.preventDefault()
      form    = $(this)
      parent  = form.parent()

      beforeSubmit = (form) ->
        coworker = kansoRequire('lib/types').coworker
        tmpDoc = {
          type: 'coworker'
          username: $("input[name='username']", form).val()
        }
        id = coworker.fields.id.buildId(tmpDoc)
        _id = coworker.fields.id.build_id(tmpDoc, id)
        $("input[name='id']", form).val(id)
        $("input[name='_id']", form).val(_id)
        form.attr('action', kansoRequire('duality/utils').getBaseURL() + '/' + _id)

      isNewCoworker = (parent) ->
        $(".new-coworker", parent).length > 0
      setError = (msg, parent) ->
        $(".error", parent).text(msg)

      if isNewCoworker(parent)
        #console.log 'new coworker'
        username = $("input:text[name='username']", parent).val()
        password = $("input[name='password']", parent).val()
        if username != '' and password != ''
          _this.session.signup username, password, {}, (err, res) ->
            #console.log("user created?", err, res)
            _this.session.login username, password, (loginErr) ->
              if not loginErr?
                doNotHandleNextSubmit = true
                beforeSubmit(form)
                form.submit()

        ev.stopImmediatePropagation()
        return false
      else
        #console.log 'existing'
        if not session.isConnected()?
          console.error "not connected"
          setError("Vous devez être connecté(e) pour pouvoir modifier vos données", parent)
          ev.stopImmediatePropagation()
          return false
        else
          #console.log 'connected'
          username = $("input:text[name='username']", parent).val()
          if session.isConnected(username)
            #console.log 'continue'
            beforeSubmit(form)
          else
            ev.stopImmediatePropagation()
            #console.log 'wrong user'
            ev.stopImmediatePropagation()
            return false

  getCoworkerUsername: (coworkerElement) ->
    return $('input[name="username"]', coworkerElement).val()

  open: (coworkerElement) ->
    if @clickManager.insideElement? and
        @clickManager.insideElement isnt coworkerElement
      @clickManager.callback()
      #TODO: improve chaining process (use promises?)
    coworkerElement.closest('.col').addClass('opened')
    #$('.avatar, .right-col', coworkerElement).addClass('m6').removeClass('m12')
    $('.m12', coworkerElement).addClass('m6').removeClass('m12')
    $('.hidden', coworkerElement).delay(300).show(0)
    if @isAllowedToEdit(@getCoworkerUsername(coworkerElement))
      $('.editButton', coworkerElement).delay(300).show(0)

    @clickManager.setInsideElement(coworkerElement)
    @clickManager.setCallback =>
      @close(coworkerElement)

  close: (coworkerElement) ->
    @leaveEditMode(coworkerElement)
    coworkerElement.off('click')

    $('.editButton', coworkerElement).hide()
    $('.hidden', coworkerElement).hide(0)
    #$('.avatar, .right-col', coworkerElement).delay(200).removeClass('m6').addClass('m12')
    $('.m6', coworkerElement).delay(200).removeClass('m6').addClass('m12')
    coworkerElement.closest('.col').delay(200).removeClass('opened')

    $('a.new-coworker', coworkerElement).show()

  enterEditMode: (coworkerElement) ->
    $('.not-form', coworkerElement).hide()
    coworkerElement.css('height', 'auto')
    $('.input-field, .form', coworkerElement).show()

  leaveEditMode: (coworkerElement) ->
    $('.coworker .not-form').show()
    $('.coworker .input-field, .coworker .form').hide()
    adjustColSize(coworkerElement)

  showOnlyMatchingSkill: (skill) ->
    if skill
      $(".coworker-col").hide()
      $(".coworker-col").has(".skill:contains('#{skill}')").show()
    else
      $(".coworker-col").show()

  isAllowedToEdit: (username) ->
    return @session.isConnected(username)


module.exports = Coworker