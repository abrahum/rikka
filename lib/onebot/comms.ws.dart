part of 'comms.dart';

class WSS extends Comm {
  WSSConfig config;
  List<WebSocket> sockets = [];
  HttpServer? server;
  WSS(this.config);

  @override
  int send(String msg) {
    var count = 0;
    for (final socket in sockets) {
      socket.add(msg);
      count += 1;
    }
    return count;
  }

  void implStart(OneBotImpl ob) async {
    server = await HttpServer.bind(config.address, config.port);
    await server?.forEach((HttpRequest req) async {
      if (requestCheck(req, config.path, config.accessToken)) {
        final socket = await WebSocketTransformer.upgrade(req);
        socket.listen(
          (msg) async {
            try {
              final action = ob.actionParser.fromString(msg);
              var resp = await ob.handleAction(action);
              socket.add(resp.toString());
            } on FormatException {
              socket.add(Response.badRequest().toString());
            } on MissFieldError {
              socket.add(Response.badParam().toString());
            } catch (e) {
              print(e);
            }
          },
          onDone: () => sockets.remove(socket),
          onError: (e) => sockets.remove(socket),
        );
        sockets.add(socket);
      } else {
        req.response.statusCode = HttpStatus.forbidden;
        req.response.close();
      }
    });
  }

  void appStart(OneBotApp ob) async {
    server = await HttpServer.bind(config.address, config.port);
    await server?.forEach((HttpRequest req) async {
      if (requestCheck(req, config.path, config.accessToken)) {
        final socket = await WebSocketTransformer.upgrade(req);
        logger.fine('new websocket connection');
        var bot = Bot(socket);
        socket.listen(
          (msg) async {
            try {
              final i = ob.eventParser.eorFromString(msg);
              if (i is Event) {
                ob.handleEvent(bot, i);
              } else if (i is Response) {
                bot.handleResponse(i);
              } else {
                logger.warning('unknown msg: $msg');
              }
            } catch (e) {
              logger.warning('handling error: $e');
            }
          },
          onDone: () => sockets.remove(socket),
          onError: (e) => sockets.remove(socket),
        );
        sockets.add(socket);
      } else {
        req.response.statusCode = HttpStatus.forbidden;
        req.response.close();
      }
    });
  }

  @override
  void close() {
    for (final s in sockets) {
      s.close();
    }
    sockets.clear();
    server?.close();
  }
}
