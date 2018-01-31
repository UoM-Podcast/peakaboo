setHeartbeat = (err, res) ->
  Session.setTemp 'serverTime', res if not error?

Meteor.startup ->
  Meteor.call 'getLogins', (err, loginMethods) ->
    if 'loginWithCas' not in loginMethods
      Session.set 'cas.hide', true

  $(window).resize ->
    Session.set 'resize', new Date()

@fixNav = ->
  $('body').css 'margin-top', "#{$('.navbar-fixed-top').outerHeight(true)}px"

@resizeThumbnails = (template) ->
  Meteor.defer ->
    template.$ 'a.thumbnail img'
      .height template.$('a.thumbnail').first().width() / 16 * 9 + 'px'

@resizePanelTitle = (template) ->
  title = template.$ '.panel-title'
  span = title.find '[data-toggle="tooltip"]'
  Meteor.setTimeout ->
    span.width 'initial'
    if span.width() > title.width()
      span.width '100%'
    span.tooltip 'fixTitle'
  , 50

# call once straight away and every 10 seconds thereafter
Meteor.call 'getServerTime', setHeartbeat
@heartbeatInterval = Meteor.setInterval ->
  Meteor.call 'getServerTime', setHeartbeat
, 10000

Template.registerHelper 'roomOffline', ->
  data = Template.currentData()
  offline = data.offline
  if offline
    heartbeat = data.heartbeat
    now = Session.get 'serverTime'
    lastUpdate = now - heartbeat
    lastUpdateTime = moment.unix heartbeat
    whenAgo = lastUpdateTime.fromNow true
    whenTime = lastUpdateTime.format 'dddd, MMMM Do YYYY, HH:mm:ss'
    {ago: whenAgo, time: whenTime}
  else null

Template.registerHelper 'metadata', (metadata) ->
  if metadata
    created = moment.unix(metadata.created)
    metadata.createdDisplay = created.format "HH:mm"
    serverNow = Session.get 'serverTime'
    duration = serverNow - created.unix()
    duration = 0 if duration < 0
    durationMoment = moment.unix(duration)
    durationMoment.utc()
    durationH = durationMoment.hour()
    durationM = durationMoment.minute()
    durationHString = switch
      when durationH is 1
        '1 hour'
      when durationH > 1
        "#{durationH} hours"
      else ''
    durationMString = switch
      when durationM is 0 and durationH is 0
        'Just started...'
      when durationM is 1
        '1 minute'
      when durationM is 0 and durationH > 0
        ''
      else
        "#{durationM} minutes"
    metadata.durationDisplay = if durationHString
      "#{durationHString} #{durationMString}"
    else
      "#{durationMString}"
    if metadata.series_identifier
      metadata.series_identifier = metadata.series_identifier.replace '__', ':'
  metadata

Template.registerHelper 'presentation', (profile) ->
  true if profile is 'cam' or profile is 'nocam'

Template.registerHelper 'cam', (profile) ->
  true if profile is 'cam'

Template.registerHelper 'thumbnail', ->
  roomId = Template.currentData()._id
  timestamp = Template.currentData().heartbeat
  images = Template.currentData().images
  switch Session.get 'view'
    when 'view-presentation'
      file = 'presentation'
    when 'view-camera'
      file = 'presenter'
    when 'view-galicaster'
      file = 'galicaster'

  if images?[file]
    "/image/#{roomId}/#{file}?#{timestamp}"
  else
    '/images/no_image_available.png'

Template.registerHelper 'showVolMeter', ->
  Session.get 'showVumeter'

Template.registerHelper 'notcool', ->
  try
    isUserAuthorised Meteor.userId(), ['view-rooms', 'control-rooms', 'admin']
    return false
  true

Template.registerHelper 'appname', ->
  return Meteor.settings.public.applicationName

@fireAnim = (element, anim) ->
  events = 'webkitAnimationEnd mozAnimationEnd ' +
           'MSAnimationEnd oanimationend animationend'
  element.removeClass(anim).addClass(anim).one events , ->
    element.removeClass anim
