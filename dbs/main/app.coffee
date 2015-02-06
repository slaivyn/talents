#require 'Coworker/add.js'

window.$ = window.jQuery = require 'jquery'
require 'jquery-ui/autocomplete'
require 'materialize'

Coworker     = require './Coworker/Coworker'
Session      = require './Session/Session'
ImageLoader  = require './ImageLoader/ImageLoader'
ClickManager = require './ClickManager/ClickManager'

kansoRequire = require

appName = 'coworkskills'

$(document).ready ->
  #loadApp()
  events = kansoRequire 'duality/events'
  events.on 'afterResponse', loadApp

loadApp = ->
  $(document).unbind('.' + appName)

  if $("input[name='dbname']").val()?
    dbname = $("input[name='dbname']").val()
    $("body").data('dbname', dbname)
  else
    dbname = $("body").data('dbname')

  #session      = new Session(appName, dbname)
  session      = new Session(appName)

  clickManager = new ClickManager(appName)

  coworker     = new Coworker(appName, clickManager, session)

  loader       = new ImageLoader(180, (err, dataUrl, parent, inputVal) ->
    #console.log 'dataURL2', dataUrl
    $('img', parent).attr('src', dataUrl).show()
    $('img', $(parent).closest('.cowork')).attr('src', dataUrl)

    $("input:hidden", parent).val(inputVal)
  )
  loader.addDropZoneByClassName('dropzone')


