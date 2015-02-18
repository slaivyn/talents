ImageLoader  = require '../ImageLoader/ImageLoader'

kansoRequire = require

#TODO: use "real" rows and not .row
# or switch to flex

getMaxHeightOfRow = (row) ->
  maxHeight = 0
  $('.coworker', row).each ->
    if $(this).outerHeight() > maxHeight
      maxHeight = $(this).outerHeight() + 1
  return maxHeight

adjustColSize = (coworker, maxHeight) ->
  coworker = $(coworker)
  if not maxHeight?
    maxHeight = getMaxHeightOfRow(coworker.closest('.row'))
  coworker.css('min-height', maxHeight)


adjustAllColSizes = () ->
  $('.row').has('.coworker').each (i, row) ->
    maxHeight = getMaxHeightOfRow(row)
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

    #New-coworker button
    displayNewCoworkerButton = () ->
      if _this.session.isConnected()
        $('.coworker-col').has('.new-coworker').hide()
      else
        $('.coworker-col').has('.new-coworker').show()

    @session.on 'change', () ->
      displayNewCoworkerButton()
    displayNewCoworkerButton()

    $(document).on 'click.' + @_appName, 'a.new-coworker', (event) ->
      coworkerElement = $(this).closest('.coworker')
      coworkerModal = _this.open(coworkerElement)
      _this.enterEditMode(coworkerModal)
      return false

    $(document).on 'click.' + @_appName, '.editButton', (event) ->
      coworkerElement = $(this).closest('.coworker')
      _this.enterEditMode(coworkerElement)


    $('.coworker').each (coworkerIndex, coworker) =>
      $('span.skill', $(coworker)).each (i, skill) =>
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



  getCoworkerUsername: (coworkerElement) ->
    return $('input[name="username"]', coworkerElement).val()


  open: (coworkerElement) ->
    if @clickManager.insideElement?
      if @clickManager.insideElement[0] isnt coworkerElement[0]
        @clickManager.callback()
      else
        return @close(coworkerElement)
      #TODO: improve chaining process (use promises?)
    position = coworkerElement.position()
    col = coworkerElement.closest('.col')
    modal = $('.coworker-modal')
    modal.html(col.html())
    .addClass('opened')
    .css({
      'top':  position.top
      'left': position.left
    })
    if position.left < $(window).width()/2
      modal.css('width', col.width() + col.outerWidth() * 2)
    else
      modal.css('left', position.left - col.outerWidth() * 2)
    coworkerModal = $('.coworker-modal .coworker')
    $('.m12', coworkerModal).addClass('m6').removeClass('m12')
    $('.hidden', coworkerModal).show()
    if @isAllowedToEdit(@getCoworkerUsername(coworkerModal))
      $('.editButton', coworkerModal).show()
    modal.show()
    @clickManager.setInsideElement(coworkerModal)
    @clickManager.setCallback =>
      @close(coworkerElement)

    doNotHandleNextSubmit = false

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

      skillList = $("input.skill", form)
      .filter ->
        return this.value != ""
      .map ->
        return @value
      .get().join()
      $("input[name='skillList']", form).val(skillList

      )
      form.attr('action', kansoRequire('duality/utils').getBaseURL() + '/' + _id)
      doNotHandleNextSubmit = true

    _this = this
    $('form', coworkerModal).off 'submit.' + @_appName
    $('form', coworkerModal).on 'submit.' + @_appName, (ev) ->
      if doNotHandleNextSubmit? and doNotHandleNextSubmit
        return true
      ev.preventDefault()
      form    = $(this)
      parent  = form.parent()

      isNewCoworker = (parent) ->
        $(".new-coworker", parent).length > 0
      setError = (msg, parent) ->
        $(".error", parent).text(msg)

      if isNewCoworker(parent)
        username = $("input:text[name='username']", parent).val()
        password = $("input[name='password']", parent).val()
        if username != '' and password != ''
          _this.session.signup username, password, {}, (err, res) ->
            _this.session.login username, password, (loginErr) ->
              if not loginErr?
                beforeSubmit(form)
                form.submit()

        ev.stopImmediatePropagation()
        return false
      else
        if not _this.session.isConnected()?
          setError("Vous devez être connecté(e) pour pouvoir modifier vos données", parent)
          ev.stopImmediatePropagation()
          return false
        else
          username = $("input:text[name='username']", parent).val()
          if _this.session.isConnected(username)
            beforeSubmit(form)
          else
            ev.stopImmediatePropagation()
            return false

    return coworkerModal


  close: (coworkerElement) ->
    @leaveEditMode(coworkerElement)
    @clickManager.reinit()

    col = coworkerElement.closest('.col')
    coworkerModal = $('.coworker-modal .coworker')

    $('.editButton', coworkerModal).hide()
    $('.hidden',     coworkerModal).hide()
    $('.m6',         coworkerModal).delay(200).removeClass('m6').addClass('m12')

    col.html($('.coworker-modal').html())

    $('.coworker-modal').removeClass('opened').hide()


  enterEditMode: (coworkerElement) ->
    $('.modal-background').show()
    loader = new ImageLoader(180, (err, dataUrl, parent, inputVal) ->
      $('img', parent).attr('src', dataUrl).show()
      $('img', $(parent).closest('.cowork')).attr('src', dataUrl)

      $("input:hidden", parent).val(inputVal)
    )
    loader.addDropZoneByClassName('dropzone')
    $('.not-form',           coworkerElement).hide()
    $('.input-field, .form', coworkerElement).show()

    $('label', coworkerElement).each (i, label) ->
      forVal = label.htmlFor
      label = $(label)
      element = label.siblings("*[name='#{forVal}']")
      if element.val() != ""
        label.addClass('active')
      else
        label.removeClass('active')

    validateLength = (input) ->
      if input.val() == ""
        input.removeClass('invalid')
        return
      if input.val().length > input[0].maxLength
        input.removeClass('valid').addClass('invalid')
      else
        input.removeClass('invalid').addClass('valid')

    addNewSkillInputIfNeeded = (coworkerElement) ->
      lastOne = $('input.skill:last', coworkerElement)
      skills  = $('input.skill', coworkerElement)
      nb      = skills.size()
      if lastOne.val() != "" and nb < 5
        newSkill = $('input.skill:first').parent('.input-field').clone()
        newSkill.children('input')
          .attr('name', 'skill' + nb)
          .attr('class', 'form skill')
          .val('')
        lastOne.parent().after(newSkill)
        $('.form', coworkerElement).show()
        skills = $('input.skill', coworkerElement)

      skills.off '.skill'
      lastOne.on 'keyup.' + @_appName + '.skill', (event) ->
        addNewSkillInputIfNeeded(coworkerElement)

      skills.on 'blur.' + @_appName + '.skill', (event) ->
        input = $(this)
        if input.val() == ""
          input.remove()
          addNewSkillInputIfNeeded(coworkerElement)
        else
          validateLength(input)

      skills.on 'keyup.' + @_appName + '.skill', ->
        validateLength($(this))

    addNewSkillInputIfNeeded(coworkerElement)

    $('input.validate', coworkerElement).each ->
      input = $(this)
      if input.val() != "" && input.is(':valid')
        input.addClass('valid')
      else
        input.removeClass('valid')
      if this.maxLength > 0
        validateLength(input)


  leaveEditMode: (coworkerElement) ->
    $('.modal-background'  ).hide()
    $('.coworker .not-form').show()
    $('.coworker .input-field, .coworker .form').hide()
    adjustColSize(coworkerElement)

  showOnlyMatchingSkill: (skill) ->
    if skill
      $(".coworker-col").hide()
      $(".coworker-col").has("span.skill:contains('#{skill}')").show()
    else
      $(".coworker-col").show()

  isAllowedToEdit: (username) ->
    return @session.isConnected(username)


module.exports = Coworker