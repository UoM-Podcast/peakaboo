Connection = Npm.require 'ssh2'
xml2js.parseStringSync = Meteor.wrapAsync xml2js.parseString

sshExec = (id, command, action, callback) ->
  room = Rooms.findOne id
  if room
    conn = new Connection()
    conn.on 'ready', ->
      conn.exec command, (err, stream) ->
        callback "Could not complete action '#{action}' on #{id}." if err
        stream.on 'exit', (code, signal) ->
          if code
            callback "Command to '#{command}' did not run successfully on #{id}."
          else
            callback null, 'Success'
    conn.on 'error', (err) ->
      callback "Could not connect to #{id} when attempting to #{action}." if err
    .connect
      host: room.ip
      port: 22
      username: Meteor.settings.auth.username
      password: Meteor.settings.auth.password

Meteor.methods
  restartGalicaster: (id) ->
    if isUserAuthorised Meteor.userId(), ['admin', 'control-rooms']
      Async.runSync (done) ->
        sshExec id, 'pkill -f python', 'restart galicaster', (error, result) ->
          done error, result

  rebootMachine: (id) ->
    if isUserAuthorised Meteor.userId(), ['admin', 'control-rooms']
      Async.runSync (done) ->
        sshExec id, 'sudo reboot', 'reboot', (error, result) ->
          done error, result

  getServerTime: ->
    Math.round new Date() / 1000

  user_ws: (userId) ->
    wsURL = Meteor.settings.user_ws.ws + userId
    picURLs = Meteor.settings.user_ws.pic_urls
    ws = HTTP.get wsURL
    res = xml2js.parseStringSync ws.content
      .formlet
    subtitle = res?.subtitle?[0]
    userName = picURL = modules = null
    if subtitle
      sub = subtitle.split '/'
      userName = sub[0].trim()
      personId = sub[1].trim()

      picURL = ''
      for url in picURLs
        url = url + personId + '.jpg'
        try
          pic = HTTP.get url
          if pic.statusCode is 200
            picURL = url
            break

      modules = []
      if res.row
        for row in res.row
          mod = {}
          for field in row.field
            mod[field.name[0]] = field.value[0]
          modules.push mod
    else
      throw new Meteor.Error 'no-user-found', 'Could not find user using web service.'

    user =
      user_id: userId
      user_name: userName
      pic_url: picURL
      modules: modules

  updateAudioLevel: (_id, channel, level) ->
    if isUserAuthorised Meteor.userId(), ['admin', 'control-rooms']
      Rooms.update { '_id': _id, 'audio.name': channel }, {
        $set: 'audio.$.level' : level
      }, (err, result) ->
        console.log err if err

  getLogins: () ->
    logins = Meteor.settings.logins
    loginMethods = []

    for own login, settings of logins
      if settings.active
        loginMethods.push 'loginWith' + login.charAt(0).toUpperCase() +
          login.slice(1).toLowerCase()

    loginMethods

  getViewOnlyUsers: () ->
    allViewOnlyUser = Meteor.settings.cas.viewOnlyUsers
    if Meteor.user().username in allViewOnlyUser
      Roles.addUsersToRoles(Meteor.user(), ['view-rooms'])

  getAdminUsers: () ->
    allAdminUser = Meteor.settings.cas.adminUsers
    if Meteor.user().username in allAdminUser
      Roles.addUsersToRoles(Meteor.user(), ['admin'])

  getControlUsers: () ->
    allControlUser = Meteor.settings.cas.ControlUsers
    if Meteor.user().username in allControlUser
      Roles.addUsersToRoles(Meteor.user(), ['control-rooms'])
