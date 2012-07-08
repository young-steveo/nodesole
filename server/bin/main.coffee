Fs = require 'fs'
Path = require 'path'

paths =
  config: Path.join __dirname, '..', 'config'
  srcDir: Path.join __dirname, '..', 'src'
  scriptDir: Path.join __dirname, '..', 'scripts'

config = require paths.config
Message = require paths.srcDir + '/message';
command = new (require paths.srcDir + '/command');

app = require('express').createServer()
io = require('socket.io').listen app

app.get '/', (req, res) ->
  res.sendfile(Path.join __dirname, '../..', 'client/index.html');

app.get '/config.js', (req, res) ->
  res.sendfile(Path.join __dirname, '../..', 'client/config.js');

for file in Fs.readdirSync paths.scriptDir
  require(paths.scriptDir + '/' + file)(command)

io.sockets.on 'connection', (socket) ->
  socket.emit 'handshake', message: 'Connected to host.'
  socket.broadcast.emit 'client-status', { message: 'Client connected.', type: 'connect' }

  socket.on 'command-request', (data) ->
    message = new Message(socket, 'command-response', data);
    command.trigger('command-request', message)
    if !message.isHandled()
      socket.emit 'command-response', { message: 'Invalid command: ' + data.command }

  socket.on 'disconnect', (data) ->
    message = new Message(socket, 'client-status', data);
    command.trigger('disconnect', message)

console.log 'Nodesole listening on port ' + config.port
app.listen config.port