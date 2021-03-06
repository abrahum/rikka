import 'dart:io';

import 'package:rikka/onebot.dart';
import 'package:rikka/rikka.dart' show logger;

part 'comms.ws.dart';

abstract class Comm {
  int send(String msg);
  int sendEvent(Event event) => send(event.toString());
  void close();
}

bool requestCheck(HttpRequest req, String? path, String? accessToken) {
  if (path != null) {
    if (req.uri.path != path) {
      return false;
    }
  }
  if (accessToken != null) {
    if (req.headers.value('access_token') != accessToken) {
      return false;
    }
  }
  return true;
}
