Meteor.publish 'RoomsDisplay', (filters, vumeter) ->
  if isUserAuthorised @userId, ['admin', 'control-rooms', 'view-rooms']
    query = {}
    if filters
      query['$or'] = []
      for filter in filters
        switch filter
          when 'recording' then query['$or'].push recording: true
          when 'idle' then query['$or'].push recording: false
          when 'paused' then query['$or'].push paused: true
          when 'unpaused' then query['$or'].push paused: false
          when 'quiet' then query['$or'].push vumeter: $lte: 5
          when 'loud' then query['$or'].push vumeter: $gte: 5
          when 'offline' then query['$or'].push offline: true
          when 'online' then query['$or'].push offline: false
          when 'camAvailable' then query['$or'].push camAvailable: 0
      unless query['$or'].length then query = {}
    Counts.publish @, 'offline', Rooms.find(offline: true), noReady: true
    Counts.publish @, 'paused', Rooms.find(paused: true), noReady: true
    Counts.publish @, 'quiet', Rooms.find(vumeter: $lte: 0), noReady: true
    Counts.publish @, 'recording', Rooms.find(recording: true), noReady: true
    Counts.publish @, 'camAvailable', Rooms.find(camAvailable: 1), noReady: true

    fields =
      fields:
        currentMediaPackage: 1
        currentProfile: 1
        displayName: 1
        supportGroup: 1
        heartbeat: 1
        stream: 1
        images: 1
        offline: 1
        paused: 1
        recording: 1
        camAvailable: 1
        vumeter: 1
    unless vumeter
      delete fields.fields.vumeter

    return Rooms.find query, fields

  @stop()

Meteor.publish 'Room', (_id) ->
  if isUserAuthorised @userId, ['admin', 'control-rooms', 'view-rooms']
    return Rooms.find _id: _id

Meteor.publish 'GalicasterControl', (RoomId) ->
  if isUserAuthorised @userId, ['admin', 'galicaster']
    return Rooms.find '_id': RoomId,
      fields:
        audio: 1
        currentMediaPackage: 1
        currentProfile: 1
        paused: 1
        recording: 1
        camAvailable: 1
  @stop()
