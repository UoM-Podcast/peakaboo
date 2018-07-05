Session.setDefault 'view', 'view-Camera_1'
Session.setDefault 'zoom', 3
Session.setDefault 'showVumeter', false
Session.set 'search-query'

minZoom = 1
maxZoom = 6

resetFilters = ->
  $('#peakaboo-filter-clear').addClass 'disabled'
  $('.peakaboo-filter').removeClass 'active'
  $('.peakaboo-filter input').prop 'checked', false

Template.navbar.events
  'click #signout': (e) ->
    Meteor.logout()
  'keyup input#search, click button#searchReset': (e) ->
    Session.set 'search-query', e.currentTarget.value
  'keydown input#search': (e) ->
    if e.which is 13
      e.preventDefault()
  'click #view a.preview': (e) ->
    Session.setPersistent 'view', e.currentTarget.id
  'click #view a.showVolMeter': (e) ->
    Session.setPersistent 'showVumeter', not Session.get 'showVumeter'
  'click #zoom button': (e) ->
    switch e.currentTarget.id
      when 'zoomOut'
        if Session.get('zoom') > minZoom
          Session.setPersistent 'zoom', Session.get('zoom') - 1
      when 'zoomIn'
        if Session.get('zoom') < maxZoom
          Session.setPersistent 'zoom', Session.get('zoom') + 1
    e.stopPropagation()
  'change .peakaboo-filter': ->
    url = Router.routes['room_list'].path()
    filters = $('input:checked:not([name="all"])')
    if filters.length
      $('#peakaboo-filter-clear').removeClass('disabled')
      for filter in filters
        url += '/' + filter.name
    else
      $('#peakaboo-filter-clear').addClass('disabled')
    Router.go url

  'click #peakaboo-filter-clear': (e) ->
    e.stopImmediatePropagation()
    resetFilters()
    Router.go 'room_list'

Template.navbar.helpers
  zoomOutDisabled: ->
    Session.get('zoom') is minZoom

  zoomInDisabled: ->
    Session.get('zoom') is maxZoom

  resetDisabled: ->
    'disabled' unless Session.get('search-query')

  view: (id) ->
    Session.get('view') is id

  roomList: ->
    Router.current().route.getName() in ['room_list', 'room_list_filter']

Template.navbar.rendered = ->
  params = Router.current().params
  if 0 of params
    filters = params[0].split '/'
    for filter in filters
      selected = $("[name=#{filter}]")
        .prop('checked', true).parent().addClass 'active'
      if selected.length
        $('#peakaboo-filter-clear').removeClass('disabled')
  @autorun ->
    resetFilters() unless Router.current().params[0]
