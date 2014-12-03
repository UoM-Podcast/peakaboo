slidersRendered = false

Template.room_controls.events
  'click .peakaboo-command': (e) ->
    unsetCommandError()
    Session.set 'modal',
      e.currentTarget.dataset
  'change .slider': (e) ->
    if slidersRendered
      values = {}
      level = $("input[data-slider-id='#{e.currentTarget.id}']").slider 'getValue'
      values["audio.#{e.currentTarget.id}.value.left"] = level
      values["audio.#{e.currentTarget.id}.value.right"] = level
      Rooms.update { '_id': @._id }, {
        $set: values
      }, (err, result) ->
        console.log err if err
        console.log result if result
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

Template.room_controls.helpers
  setSlider: (id, level) ->
    $("#{id}").slider 'setValue', level
    level

Template.room_controls.created = ->
  slidersRendered = false

Template.room_controls.rendered = ->
  @$('[data-toggle="tooltip"]').tooltip()
  $('.fader').each ->
    $(@).slider
      id: $(@).attr 'data-slider-id'
      reversed: true
  slidersRendered = true

Template.confirmModal.rendered = ->
  Ladda.bind 'button.ladda-button'

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
    if $('#module-id').val() isnt 'none__'
      isPartOf = $('#module-id').val()
      series_title = $('#module-id option:selected').text()

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
    'disabled' if Session.get('recWaiting') or Session.get('recError') or not Session.get 'recTitle'
