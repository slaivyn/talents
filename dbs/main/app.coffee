#require 'Coworker/add.js'

window.$ = window.jQuery = require 'jquery'
require 'jquery-ui/autocomplete'

Coworker     = require './Coworker/Coworker'
Session      = require './Session/Session'
ClickManager = require './ClickManager/ClickManager'

kansoRequire = require

$.get('ip', (ip) ->
  sessionStorage.setItem("peer", ip)
  kansoRequire('duality/core').init()
)


appName = 'coworkskills'

$(document).ready ->
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


