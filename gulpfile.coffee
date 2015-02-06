gulp       = require 'gulp'
run        = require 'gulp-run'
fs         = require 'fs'
nodePath   = require 'path'
cradle     = require 'cradle'
yargs      = require 'yargs'
gulpif     = require 'gulp-if'
coffee     = require 'gulp-coffee'
notify     = require 'gulp-notify'
source     = require 'vinyl-source-stream'
plumber    = require 'gulp-plumber'
rename     = require 'gulp-rename'
uglify     = require 'gulp-uglify'
browserify = require 'browserify'
sourcemaps = require 'gulp-sourcemaps'

# TODO
# - cp tools/utils.js file

#process.env.BROWSERIFYSHIM_DIAGNOSTICS=1

production = yargs.argv.prod ? false

couchAppModules = ['updates', 'views', 'shows', 'lists', 'rewrites', 'validate']
kansoModules    = couchAppModules.concat(['types', 'fields'])
excludedJSFiles = ('!**/' + modName + '.js' for modName in kansoModules)
console.log excludedJSFiles
excludedFolders = [
  '!**/kanso/**'
  '!**/packages/**'
  '!**/node_modules/**'
]


paths = {
  mainDb:  'dbs/main'
  html:    ['dbs/main/*.html', 'dbs/main/components/**/*.html'].concat excludedFolders
  css:     ['dbs/main/*.css', 'dbs/main/components/**/*.css'].concat excludedFolders
  out:     '_kanso'
  js:      ['dbs/main/*.js', 'dbs/main/components/**/*.js'].concat(excludedFolders, excludedJSFiles)
  static:  'dbs/main/static/**'
  kanso:   ("dbs/main/components/**/#{modName}.js" for modName in kansoModules).concat(excludedFolders)
           .concat ['dbs/main/lib/*']
  coffee:
    src:   ['dbs/main/*.coffee', 'dbs/main/components/**/*.coffee'].concat excludedFolders
    dest:  'main.js'
}

mainJsFile = 'app.js'

getPath = (name, basePath = '.') ->
  nodePath.join(basePath, paths[name])

outFolderPath = (subFolder, basePath) ->
  nodePath.join(getPath('out', basePath), subFolder)

# TODO: take files from dbs/main too
# TODO: gulpify
gulp.task 'loadCouchAppFiles', ['kanso-files'], ->
  for db in getDbs()
    libPath = outFolderPath('lib', db.path)
    unless fs.existsSync(libPath)
      fs.mkdir(libPath)
    firstLines = "var reExports = require('./utils').reExports;"
    for module in kansoModules
      #TODO: each module could be a folder
      filename = module + '.js'
      content = ""
      for model in fs.readdirSync(libPath)
        if fs.existsSync(nodePath.join(libPath, model, filename))
          moduleName = "lib/#{model}/" + filename.split('.')[0]
          content += "\n\nreExports(exports, '#{moduleName}');"
      if content.length > 0
        content = firstLines + content
        console.log content
        fs.writeFileSync(
          nodePath.join(libPath, filename)
          content
        )

gulp.task 'buildAppJSFile', ['loadCouchAppFiles'], ->
  for db in getDbs()
    libPath = outFolderPath('lib', db.path)
    firstLines = "module.exports = {\n  language: 'javascript',"
    lastLine = '\n}'
    appFileContent = firstLines
    for module in kansoModules
      filename = module + '.js'
      if fs.existsSync(nodePath.join(libPath, filename))
        if module == "validate"
          appFileContent += "\n  validate_doc_update: require('./validate').validate_doc_update,"
        else
          appFileContent += "\n  #{module}: require('./#{module}'),"
    appFileContent += lastLine
    fs.writeFileSync(
      nodePath.join(libPath, 'app.js')
      appFileContent
    )

urlWithoutCredentials = (url) ->
  return url.replace(/\/\/.*@/, '\/\/')

getDbs = (appName, envName) ->
  ({
    dirName: dirName
    path:    "dbs/#{dirName}"
    name:    getRealDbName(dirName, appName, envName)
  }) for dirName in fs.readdirSync('dbs/')

getRealDbName = (dbName, appName, instanceName) ->
  if dbName == '_users'
    return '_users'
  realDbName = appName
  if instanceName?
    realDbName += '-' + instanceName
  if dbName != 'main'
    realDbName += '_' + dbName
  return realDbName


gulp.task 'default', ->
  console.log 'test'

kansoInstall = ->
  for db in getDbs()
    folder = outFolderPath('', db.path)
    cmd = "cd #{folder} && kanso install"
    console.log cmd
    run(cmd).exec()


npmUpdates = ->
  for db in getDbs()
    cmd = "cd #{db.path} && npm update"
    console.log cmd
    run(cmd).exec()


gulp.task 'update', ->
  #deployUtilsFiles()
  kansoInstall()
  #npmUpdates()


gulp.task 'coffee', ->
  gulp.src(paths.coffee.src)
    .pipe(plumber(notify.onError('<%=error.stack%>')))
    .pipe(gulpif(not production, sourcemaps.init()))
    .pipe(coffee({bare: true}))
    .pipe(gulpif(not production, sourcemaps.write()))
    .pipe(gulp.dest(outFolderPath('tmp', paths.mainDb)))


gulp.task 'browserify', ['coffee'], ->
  filepath = './' + nodePath.join(outFolderPath('tmp', paths.mainDb), mainJsFile)
  browserify({
    entries:       filepath
    debug:         not production
  }).bundle()
    .pipe(source(paths.coffee.dest))
    .pipe(gulpif(production, uglify()))
    .pipe(gulp.dest(outFolderPath('static/js', paths.mainDb)))


gulp.task 'html-files', ->
  gulp.src(paths.html)
    .pipe(plumber(notify.onError('<%=error.stack%>')))
    .pipe(gulp.dest(outFolderPath('html', paths.mainDb)))

gulp.task 'css-files', ->
  gulp.src(paths.css)
    .pipe(plumber(notify.onError('<%=error.stack%>')))
    .pipe(gulp.dest(outFolderPath('static/css', paths.mainDb)))

gulp.task 'static-folder', ->
  gulp.src(paths.static)
    .pipe(plumber(notify.onError('<%=error.stack%>')))
    .pipe(gulp.dest(outFolderPath('static', paths.mainDb)))

gulp.task 'js-files', ->
  gulp.src(paths.js)
    .pipe(plumber(notify.onError('<%=error.stack%>')))
    .pipe(gulp.dest(outFolderPath('static/js', paths.mainDb)))

gulp.task 'kanso-files', ->
  gulp.src(paths.kanso)
    .pipe(plumber(notify.onError('<%=error.stack%>')))
    .pipe(gulp.dest(outFolderPath('lib', paths.mainDb)))

gulp.task 'copy-kanso.json', ->
  gulp.src(nodePath.join(paths.mainDb, 'kanso.json'))
    .pipe(plumber(notify.onError('<%=error.stack%>')))
    .pipe(gulp.dest(outFolderPath('', paths.mainDb)))


serverUrlFromDbUrl = (dbUrl) ->
  # get the address without the database name
  #url.match(/^(http(?:s)?:\/\/[^\/]*)\/?/)
  dbUrl.match(/^http(?:s)?:\/\/.*\/?/)[0]


gulp.task 'compile', [
  'browserify'
  'html-files'
  'css-files'
  'js-files'
  'static-folder'
  'buildAppJSFile'
]

runKanso = (path, serverUrl, dbName) ->
  cmd = "kanso push #{serverUrl}/#{dbName}"
  console.log cmd
  folder = outFolderPath('', path)
  run("cd #{folder} && #{cmd}").exec()

runMultipleKansoPush = (serverUrl, dbs) ->
  cmd = ""
  for db in dbs
    folder = outFolderPath('', db.path)
    cmd += "&& kanso push #{folder} #{serverUrl}/#{db.name}"
  cmd = cmd[3..]
  console.log cmd
  run(cmd).exec()

gulp.task 'push', ['compile', 'copy-kanso.json'], ->
  argv = yargs.demand(['url', 'app'])
              .usage("Usage: $0 push url appName [envName]")
              .argv

  #((url, appName, envName) ->
  [url, appName, envName] = [argv.url, argv.app, argv.env]
  serverUrl = serverUrlFromDbUrl(url)
  console.log serverUrl
  runMultipleKansoPush(serverUrl, getDbs(appName, envName))
  .pipe(notify('Pushing'))


  #)(argv.url, argv.app, argv.env)


gulp.task 'bots', ->
  argv = yargs.usage 'Usage: $0 bots path url [appName] [envName]'
              .demand 3
              .argv

  installBots.apply(yargs.argv._)

getEnvs = (basePath = '.') ->
  krcPath = nodePath.join(basePath, '.kansorc')
  return require(krcPath).env

getUrlFromEnv = (envOrUrl) ->
  if isUrl(envOrUrl)
    return envOrUrl
  envs = getEnvs() or {}
  if  envs.hasOwnProperty(envOrUrl) and
      envs[envOrUrl].hasOwnProperty('db')
    return envs[envOrUrl].db
  else
    throw new Error("can't find the url of this environment: #{envOrUrl}")

installBots = (basePath, urlOrEnv, appName, envName) ->
  bots = require(nodePath.join(basePath, 'kanso.json')).bots
  if not bots
    console.log "No bot to install in #{basePath}"
    process.exit(0)

  serverUrl = serverUrlFromDbUrl(getUrlFromEnv(envOrUrl))

  console.log "Installation of bots in " + serverUrl.replace(/\/\/.*@/, '\/\/') + "/_config db"
  db = new(cradle.Connection)(serverUrl).database("_config")
  for botName, bot of bots
    words = []
    for word in bot.split(' ')
      words.push(
        if fs.existsSync(word)
          nodePath.resolve(word)
        else
          switch word
            when "_url"      then serverUrl
            when "_app"      then appName
            when "_instance" then instanceName
            else word
      )
    firstExt = words[0].match(/\.\w+$/)
    if firstExt?
      words.unshift(
        switch firstExt[0]
          when ".coffee" then "coffee"
          when ".js"     then "node"
          else ""
      )
    botCmd = words.join(' ')

    if appName?
      botName += "-" + appName
      if instanceName?
        botName += "-" + instanceName

    ( (name)->
      return db.query({
          method: 'PUT'
          path: "os_daemons/#{name}"
          body: botCmd
        }, (err, res)->
          if err
            console.log("#{name}: ERROR")
            console.log(err)
          else
            console.log("#{name}: INSTALLED")
      )
    )(botName)