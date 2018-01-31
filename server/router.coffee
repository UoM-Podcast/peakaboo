mkdirp = Npm.require 'mkdirp'
Busboy = Npm.require 'busboy'
fs = Npm.require 'fs'
os = Npm.require 'os'
path = Npm.require 'path'
cookie = Npm.require 'cookie'

Router.route '/image/:roomId',
  name: 'image'
  where: 'server'
  onBeforeAction: (req, res, next) ->
    {roomId} = @params
    images = {}
    if req.method is 'POST'
      timestamp = Meteor.call 'getServerTime'
      allowedFieldnames = ['galicaster', 'presentation', 'presenter']
      busboy = new Busboy headers: req.headers
      busboy.on 'file', (fieldname, file, filename, encoding, mimetype) ->
        if fieldname in allowedFieldnames
          dir = path.join Meteor.settings.imageDir, roomId
          try
            mkdirp.sync dir
            saveTo = path.join dir, filename
            file.pipe fs.createWriteStream saveTo
            images[fieldname] =
              filename: filename
              mimetype: mimetype
            req.images = images
          catch error
            res.statusCode = 500
            next()
        else
          file.on 'data', ->
          file.on 'end', ->
      busboy.on 'finish', ->
        if Object.keys(images).length
          req.heartbeat = timestamp
          res.statusCode = 204
        else
          res.statusCode = 400
        next()
      req.pipe busboy
    else
      next()
.post ->
  if @response.statusCode is 204
    {roomId} = @params
    Rooms.update { _id: roomId }, {
      $set:
        offline: false
        heartbeat: @request.heartbeat
        images: @request.images
    }, (err, result) ->
      console.log err if err
  @response.end()

Router.route '/image/:roomId/:imageType(galicaster|presentation|presenter)',
  where: 'server'
.get ->
  # get hashed login token from client cookie
  cookies = cookie.parse @request.headers.cookie
  user = getUserFromToken cookies.meteor_login_token

  if user and isUserAuthorised user._id, [
    'admin', 'view-rooms', 'control-rooms'
  ]

    {roomId, imageType} = @params

    # Find all images that are stored for the room
    room = Rooms.findOne
      _id: roomId
      images:
        $exists: true
    ,
      fields:
        images: 1
        imageTimestamp: 1

    # Requested image
    reqImage = room?.images["#{imageType}"]
    imagePath = null
    if reqImage?
      imagePath = path.join Meteor.settings.imageDir,
        roomId, reqImage.filename

    if imagePath and fs.existsSync imagePath
      file = fs.readFileSync imagePath
      @response.writeHead 200,
        'Content-Type': reqImage.mimetype
      @response.write file
    else # image doesn't exist
      @response.writeHead 302, 'Location': '/images/no_image_available.png'
  else # auth failed
    @response.writeHead 403

  @response.end()

Router.route '/stream_key',
  where: 'server'
.post ->
  # check key
  room = Rooms.findOne
    _id: @request.body._id
    'stream.key': @request.body.streamKey

  # reset key
  key = uuid()
  Rooms.update @request.body._id,
    $set:
      'stream.key': key

  if room
    @response.writeHead 204
  else
    @response.writeHead 403
  @response.end()
