Template.room_list.rendered = ->
  @autorun =>
    Session.get 'zoom'
    Session.get 'resize'
    Session.get 'roomSummaryRendered'
    resizeThumbnails @

Template.room_list.helpers
  rooms: ->
    allRoles = Roles.getRolesForUser(Meteor.userId())
    groupRoles = []
    Meteor.call 'getGroups', (err, allGroups) ->
      Session.set 'allGroups', allGroups
    allGroups = Session.get 'allGroups'
    for g in allGroups
      if g in allRoles
        groupRoles.push g
    try
      if groupRoles.length
        query = {}
        query.supportGroup = {$in: groupRoles}
        Rooms.find query, { sort: { displayName: 1 } }
      else
        searchQuery = Session.get 'search-query'
        query = {}
        query.displayName =  new RegExp searchQuery, 'i'
        Rooms.find query, { sort: { displayName: 1 } }
    catch error

Template.room_summary.events
  'click #peakaboo-audio-stream': (e, template) ->
    room =  Template.currentData()
# FIXME stream
    if room.stream
      Session.setTemp 'audiourl', "http://#{room.stream.host}:#{room.stream.port}/#{room.stream.key}"
    else
      Session.setTemp 'audiourl', "#{Meteor.settings.public.audioServer}/#{room._id}"
    Session.setTemp 'audioStreaming', not Session.get 'audioStreaming'
  'error #audioStreaming, suspend #audioStreaming': ->
    Session.setTemp 'audioStreaming', false
  'playing #audioStreaming': ->
    $('#peakaboo-audio-stream span').hide 'slow'


Template.room_summary.rendered = ->
  Session.setTemp 'audioStreaming', false
  Session.setTemp 'audiourl', ''
  self = @
  @autorun =>
    Session.get 'zoom'
    Session.get 'resize'
    offline = Template.currentData().offline
    resizePanelTitle @
  Session.set 'roomSummaryRendered', new Date()
  @autorun =>
    audioStreaming = Session.get 'audioStreaming'
    url = ''
    if audioStreaming
      room = @data.displayName
      url = Session.get 'audiourl'
      @$('#peakaboo-audio-stream span').show 'slow'
    else
      @$('#peakaboo-audio-stream span').hide 'slow'
    @$('#audioStreaming').prop 'src', url

Template.room_summary.helpers
  zoom: ->
    Session.get 'zoom'
  'audioStreaming': ->
    Session.get 'audioStreaming'

Template.rec.rendered = ->
  @$('[data-toggle="popover"]').each ->
    $(@).popover
      placement: 'auto left'
      html: true
      container: 'body'
      content: ->
        $(@).parent().find('.meta').html()
