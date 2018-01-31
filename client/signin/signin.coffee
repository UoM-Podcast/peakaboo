Template.signin.events
  'click #custom-signin': (evt, tmpl) ->
    evt.preventDefault()
    Session.set 'login.error', ''
    email = tmpl.find('#loginEmail').value
    password = tmpl.find('#loginPassword').value
    if email
      Meteor.call 'getLogins', (err, loginMethods) ->
        console.log err if err
        tryLogin = (loginMethod, done) ->
          Meteor[loginMethod] email, password, (err) ->
            if not err
              go = Session.get('go') or '/'
              Session.set 'go', null
              Router.go go
              return
            done()

        async.eachSeries loginMethods, tryLogin, () ->
          Session.setTemp 'login.error', 'Incorrect username or password'

  'click div.alert>button': (evt, tmpl) ->
    Session.set 'login.error', ''

  'click #cas-signin': (evt, tmpl) ->
    evt.preventDefault()
    Session.set 'login.error', ''
    Meteor.call 'getLogins', (err, loginMethods) ->
      console.log err if err

      tryLogin = (loginMethod, done) ->
        Meteor[loginMethod] (err) ->
          if not err
            Meteor.call 'getViewOnlyUsers', () ->
            Meteor.call 'getAdminUsers', () ->
            Meteor.call 'getControlUsers', () ->
            Meteor.call 'setGroupUsers', () ->
            go = Session.get('go') or '/'
            Session.set 'go', null
            Router.go go
            return
          done()

      async.eachSeries loginMethods, tryLogin, () ->
        Session.setTemp 'login.error', 'Incorrect username or password'

Template.signin.helpers
  loginerror: ->
    Session.get 'login.error'

  cashide: ->
    Session.get 'cas.hide'
