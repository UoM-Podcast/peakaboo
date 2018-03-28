import {MediaPlayer} from 'dashjs';
Template.room_nav.events
  'click #peakaboo-remove-btn': (e, template) ->
    if isUserAuthorised Meteor.userId(), ['admin']
      Session.setTemp 'removeLocked', true
  'click #peakaboo-remove-room': (e, template) ->
    removeBtn = $(e.currentTarget)
    if removeBtn.hasClass 'peakaboo-locked'
      fireAnim(removeBtn, 'shake')
    if isUserAuthorised Meteor.userId(), ['admin']
      room = template.data.room
      Rooms.remove room._id

Template.room_nav.helpers
  'removeLocked': ->
    Session.get 'removeLocked'

Template.room_controls.events
  'click .peakaboo-command': (e) ->
    unsetCommandError()
    Session.set 'modal',
      e.currentTarget.dataset
  'mousedown .peakaboo-ptz': (e, template) ->
    room = template.data.room
    move_id = e.currentTarget.id
    console.log move_id + ' pressed'
    Rooms.update room._id, {$set: {ptzmove: move_id}}
  'mouseup .peakaboo-ptz': (e, template) ->
    room = template.data.room
    move_id = e.currentTarget.id
    console.log move_id + ' released'
    Rooms.update room._id, {$set: {ptzmove: false}}
  'click .peakaboo-ptz-home': (e, template) ->
    room = template.data.room
    move_id = e.currentTarget.id
    console.log 'home pressed'
    Rooms.update room._id, {$set: {ptzmove: move_id}}
  'click #peakaboo-pause-button': (e, template) ->
    room = template.data.room
    newState = not room.paused
    Rooms.update room._id, {$set: {paused: newState}}
    e.currentTarget.blur()
  'click #peakaboo-stop-button': (e, template) ->
    room = template.data.room
    Rooms.update room._id, {$set: {recording: false}}
    e.currentTarget.blur()
  'click #peakaboo-rec-button': (e, template) ->
    cleanRecModal()
  'click .lock': (e) ->
    if isUserAuthorised Meteor.userId(), ['admin', 'control-rooms']
      switch e.currentTarget.id
        # when 'peakaboo-audio-lock'
        #   Session.setTemp 'audioLocked', not Session.get 'audioLocked'
        when 'peakaboo-controls-lock'
          Session.setTemp 'controlsLocked', not Session.get 'controlsLocked'
  'click .panel-body.lockable': (e) ->
    panelBody = $(e.currentTarget)
    if panelBody.hasClass 'peakaboo-locked'
      lock = $("##{panelBody.data('lock')}")
      fireAnim(panelBody, 'pulse-background')
      fireAnim(lock, 'shake')
  'click #peakaboo-audio-stream': ->
    Session.setTemp 'audioStreaming', not Session.get 'audioStreaming'
  'error #audioStreaming, suspend #audioStreaming': ->
    Session.setTemp 'audioStreaming', false
  'playing #audioStreaming': ->
    $('#peakaboo-audio-stream span').hide 'slow'


Template.room_controls.rendered = ->
  Session.setTemp 'audioLocked', true
  Session.setTemp 'controlsLocked', true
  Session.setTemp 'audioStreaming', false

  # get dash js player
  # $.getScript("https://cdn.dashjs.org/latest/dash.all.min.js");
  room = @data.room
  for i in room.inputs.cameras
    url = "/dash/#{room.displayName}_#{i}/index.mpd";
    player = MediaPlayer().create();
    player.initialize(document.querySelector("#videoPlayer_#{i}"), url, true);
  @autorun =>
    offline = Template.currentData().room.offline
    resizePanelTitle @
  @autorun =>
    audioStreaming = Session.get 'audioStreaming'
    url = ''
    audioServer = Meteor.settings.public.audioServer
    if audioStreaming
      room = @data.room
      if audioServer
        url = audioServer + "/#{room._id}"
      else
        url = "http://#{room.ip}:#{room.stream.port}/#{room.stream.key}"
      console.log url
      @$('#peakaboo-audio-stream span').show 'slow'
    else
      @$('#peakaboo-audio-stream span').hide 'slow'
    @$('#audioStreaming').prop 'src', url

Template.videoPanel.helpers
  'theName': ->
    Rooms.find().fetch()[0]['_id']

Template.confirmModal.rendered = ->
  Ladda.bind 'button.ladda-button'

Template.room_controls.helpers
  'audioLocked': ->
    Session.get 'audioLocked'
  'controlsLocked': ->
    Session.get 'controlsLocked'
  'controlsDisable': ->
    if not @recording or Session.get 'controlsLocked'
      true
  'recControlsDisable': ->
    if @recording or Session.get 'controlsLocked'
      true
  'audioStreaming': ->
    Session.get 'audioStreaming'

Template.confirmModal.helpers
  modal: ->
    Session.get 'modal'
  commandError: ->
    Session.get 'command-error'

modalCall = (error, result) ->
  # When does error occur?
  if result.error
    Session.set 'command-error', result.error
  else
    $('#mymodal').modal 'hide'
  $('#modalOk').removeAttr 'disabled'
  $('#modalOk').removeAttr 'data-loading'
  $('#modalCancel').show 'slow'

unsetCommandError = ->
  Session.set 'command-error', ''

Template.confirmModal.events
  'click #modalOk': (e) ->
    unsetCommandError()
    $('#modalCancel').hide 'slow'
    switch Session.get('modal').action
      when 'restart'
        Meteor.call 'restartGalicaster', @room._id, modalCall
      when 'reboot'
        Meteor.call 'rebootMachine', @room._id, modalCall

Template.tableRow.helpers
  mcreated: ->
    moment(@created).format("DD-MM-YYYY HH:MM")
  mduration: ->
    moment(@duration * 1000).format("HH:mm:ss")

cleanRecModal = () ->
  Session.setTemp 'recUserName', ''
  Session.setTemp 'recUserPic', ''
  Session.setTemp 'recModules', []
  Session.setTemp 'recWaiting', false
  Session.setTemp 'recError', false
  Session.setTemp 'recTitle', ''
  $('#rec-title').val('')
  $('#user-id').val('')
  $('input[name=profile][value=nocam]').prop 'checked', true

userCallback = (err, res) ->
  Session.setTemp 'recError', err
  Session.setTemp 'recWaiting', false
  if res and res.user_id is $('#user-id').val()
    Session.setTemp 'recUserName', res.user_name
    Session.setTemp 'recUserPic', res.pic_url
    mods = []
    if res.modules.length
      mods = [
        course_code: 'none'
        module: 'Choose a module...'
      ].concat res.modules
    Session.setTemp 'recModules', mods
    $('.peakaboo-userdetails').show 'slow'

Template.recordModal.events
  'click #recordModalOk': (e, template) ->
    room = template.data.room
    title = $('#rec-title').val() or 'Unknown'
    $('.peakaboo-userdetails').hide()
    $('#recordmodal').modal 'hide'

    userId = unless Session.get 'recError' then $('#user-id').val() else ''
    userName = $('#user-name').text().trim()

    isPartOf = ''
    series_title = ''
    if $('#module-id').val() and $('#module-id').val() isnt 'none__'
      isPartOf = $('#module-id').val()
      series_title_with_code = $('#module-id option:selected').text()
      code = isPartOf.split '__'
      r = new RegExp '(.+) \\(' + code[0] + '\\)$'
      m = series_title_with_code.match r
      # series title with code stripped
      series_title = m[1]

    profile = $('input[name=profile]:checked').val()

    currentMediaPackage =
      title: title
      rightsHolder: userId
      creator: userName
      created: Session.get 'serverTime'
      isPartOf: isPartOf
      series_title: series_title
      series_identifier: isPartOf

    update =
      recording: true
      currentProfile: profile
      currentMediaPackage: currentMediaPackage

    Rooms.update room._id, $set: update

  'keyup #user-id': (e, template) ->
    if @userTimeout then Meteor.clearTimeout @userTimeout
    $('.peakaboo-userdetails').hide()
    Session.setTemp 'recError', false
    timeoutFunc = ->
      Meteor.call 'user_ws', e.currentTarget.value, userCallback
    if e.currentTarget.value
      Session.setTemp 'recWaiting', true
      @userTimeout = Meteor.setTimeout timeoutFunc, 1000
    else
      Session.setTemp 'recWaiting', false

  'keyup #rec-title': (e, template) ->
    Session.setTemp 'recTitle', $('#rec-title').val()

Template.recordModal.helpers
  userPic: ->
    Session.get 'recUserPic'
  userName: ->
    Session.get 'recUserName'
  modules: ->
    Session.get 'recModules'
  waiting: ->
    Session.get 'recWaiting'
  error: ->
    Session.get 'recError'
  disabled: ->
    'disabled' if Session.get('recWaiting') or
      Session.get('recError') or
      not Session.get 'recTitle'

# Template.videos.rendered = ->
#   k = Meteor.setInterval((->
#     if MediaPlayerFactory
#       MediaPlayerFactory.createAll()
#       Meteor.clearInterval k
#     return
#   ), 200)
#   return
