$.getJSON '/versions.json', (data) ->
  Template.registerHelper 'versions', (versionType) ->
    return data[versionType]
