Meteor.startup ->
  if Meteor.users.find().fetch().length is 0
    console.log 'creating test users'

    users = [
      email: 'galicaster@example.com'
      password: 'galicaster'
      name: 'Galicaster'
      roles: ['galicaster']
    ,
      email: 'administrator@2UlD[#I+_c?oVqH/k2nw>yVV.com'
      password: '83UlDOSRm#8(0?UOs5:]s)6*'
      name: 'Admin'
      roles: ['admin']
    ]

    for user in users
      id = Accounts.createUser
        email: user.email
        password: user.password
        profile:
          name: user.name

      Meteor.users.update {_id: id}, {$set: {'emails.0.verified': true}}
      Roles.addUsersToRoles id, user.roles

  Accounts.validateNewUser (user) ->
    try
      return true if isUserAuthorised Meteor.userId(), ['admin', 'manage-users']
    catch
      throw new Meteor.Error 403, 'Not authorized to create new users'

Meteor.setInterval ->
  now = Meteor.call 'getServerTime'
  caTimeout = Meteor.settings.caTimeout
  Rooms.update {heartbeat: {$lt: now - caTimeout}},
    {$set: {offline: true}},
    {multi: true}
, 10000
