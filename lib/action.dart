import 'dart:convert';
import 'package:onebot/onebot.dart';

const standardActionParserMap = {
  GetLatestEventsAction.ty: GetLatestEventsAction.fromData,
};

class ActionParser {
  late final Map<String, Function(Map<String, dynamic>)> map;
  ActionParser([Map<String, Function(Map<String, dynamic>)>? extra]) {
    if (extra != null) {
      map = Map.from(standardActionParserMap)..addAll(extra);
    } else {
      map = standardActionParserMap;
    }
  }

  Action fromJson(Map<String, dynamic> json) {
    final action = json.tryRemove('action') as String;
    final data = json.tryRemove('data');
    final f = map[action];
    if (f != null) {
      return f(data);
    }
    return Action(action, data);
  }

  Action fromString(String json) {
    return fromJson(jsonDecode(json));
  }
}

class Action {
  String action;
  Map<String, dynamic> extra;
  Action(this.action, [Map<String, dynamic>? extra]) : extra = extra ?? {};
  Map<String, dynamic> data() {
    return extra;
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'params': data(),
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}

class GetLatestEventsAction extends Action {
  static const String ty = 'get_latest_events';
  int limit;
  int timeout;
  GetLatestEventsAction(this.limit, this.timeout, [Map<String, dynamic>? extra])
      : super(ty, extra);
  GetLatestEventsAction.fromData(Map<String, dynamic> data)
      : limit = data.tryRemove('limit') as int,
        timeout = data.tryRemove('timeout') as int,
        super(ty, data);

  @override
  Map<String, dynamic> data() => extra
    ..addAll({
      'limit': limit,
      'timeout': timeout,
    });
}

class Response {
  String status;
  int retcode;
  Map<String, dynamic> data;
  String message;
  Response(this.status, this.retcode,
      {String? message, Map<String, dynamic>? data})
      : message = message ?? '',
        data = data ?? {};
  Response.fromJson(Map<String, dynamic> json)
      : status = json.tryRemove('status') as String,
        retcode = json.tryRemove('retcode') as int,
        message = json.tryRemove('message') as String,
        data = json.tryRemove('data');

  Map<String, dynamic> toJson() => {
        'status': status,
        'retcode': retcode,
        'message': message,
        'data': data,
      };
  factory Response.badRequest() => Response('bad_request', 10001);
  factory Response.unsupportedAction() => Response('Unsupported Action', 10002);
  factory Response.badParam() => Response('bad_param', 10003);
  factory Response.unsupportedParam() => Response('unsupported_param', 10004);
  factory Response.unsupportedSegment() =>
      Response('unsupported_segment', 10005);
  factory Response.badSegmentData() => Response('bad_segment_data', 10006);
  factory Response.unsupportedSegmentData() =>
      Response('unsupported_segment_data', 10007);

  @override
  String toString() => jsonEncode(toJson());
}