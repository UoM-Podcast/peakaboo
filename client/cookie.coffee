# set login token cookie
# based on meteorhacks:fast-render
import Cookies from 'js-cookie'

Meteor.startup ->
  resetToken()

# override Meteor._localStorage methods and resetToken accordingly
originalSetItem = Meteor._localStorage.setItem
Meteor._localStorage.setItem = (key, value) ->
  if key is 'Meteor.loginToken'
    Meteor.defer resetToken

  originalSetItem.call Meteor._localStorage, key, value


originalRemoveItem = Meteor._localStorage.removeItem
Meteor._localStorage.removeItem = (key) ->
  if key is 'Meteor.loginToken'
    Meteor.defer resetToken

  originalRemoveItem.call Meteor._localStorage, key

resetToken = ->
  loginToken = Meteor._localStorage.getItem 'Meteor.loginToken'
  loginTokenExpires = new Date(Meteor._localStorage.getItem 'Meteor.loginTokenExpires')

  if loginToken
    setToken loginToken, loginTokenExpires
  else
    setToken null, -1

setToken = (loginToken, expires) ->
  Cookies.set 'meteor_login_token', loginToken,
    path: '/'
    expires: expires
