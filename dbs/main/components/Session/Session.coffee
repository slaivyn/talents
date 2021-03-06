kansoRequire  = require

class Session
  constructor: (@_appName, @mainDb) ->
    @kansoSession = kansoRequire 'session'
    @kansoUsers   = kansoRequire 'users'
    _this         = this

    if @mainDb?
      @kansoSession.userCtx.db = @mainDb

    @kansoSession.on 'change', (userCtx) =>
      console.log "session's changed", userCtx.db
      if @mainDb? and !@kansoSession.userCtx.db?
        @kansoSession.userCtx.db = @mainDb
      @showOrHideLoginForm(userCtx)

    $("form[name='login']").on 'submit.' + @_appName, (ev) ->
      ev.preventDefault()
      ev.stopImmediatePropagation()
      username = $("input[name='login_username']", this).val()
      dbUsername = _this.getUserId(username)
      pwd = $("input[name='login_password']").val()
      _this.kansoSession.login(
        dbUsername
        pwd
        (err, res) ->
          console.log res, err, dbUsername
          if err?
            console.error err
            toast("Identifiants incorrects", 4000)

      )

    $("button.logout").on 'click.' + @_appName, (ev) =>
      @kansoSession.logout()

    @showOrHideLoginForm(@kansoSession.userCtx)

  getUsername: (dbUsername = @kansoSession.userCtx.name) ->
    if not @mainDb?
      return dbUsername
    if dbUsername? and dbUsername.indexOf(@mainDb + '.') == 0
      username = dbUsername[@mainDb.length+1..]
    return username

  getUserId: (username) ->
    if not @mainDb?
      return username
    if not username?
      return @kansoSession.userCtx.name
    return @mainDb + '.' + username

  isConnected: (username) ->
    if not username?
      return @kansoSession.userCtx.name?
    return @getUserId(username) is @kansoSession.userCtx.name

  login: (username, pwd, callback) ->
    dbUsername = @getUserId(username)
    @kansoSession.login(dbUsername, pwd, callback)

  logout: (callback) ->
    @kansoSession.logout(callback)

  signup: (username, password, options, callback) ->
    dbUsername = @getUserId(username)
    if @isConnected(dbUsername)
      return callback(null)
    else
      @logout ->
        kansoRequire('users').create dbUsername, password, options, callback
        console.log 'users.create en cours'

  signupAndLogin: (username, password, options, callback) ->
    @signup username, password, options, (err, res) =>
      @login(username, password, callback)

  showOrHideLoginForm: () ->
    form     = $("form[name='login']")
    username = @getUsername()
    if username?
      $('button.login, input', form).hide()
      $('span.username',              form).text(username)
      $('button.logout',              form).show()
    else
      $('span.username',              form).text('')
      $('button.logout',              form).hide()
      $('button.login, input', form).show()

  on: (name, callback) ->
    if name == 'login' or name == 'logout'
      @kansoSession.on 'change', (userCtx) ->
        if name == 'login' and userCtx.name
          return callback(userCtx)
        if name == 'logout' and not userCtx.name
          return callback(userCtx)

    @kansoSession.on name, callback


module.exports = Session