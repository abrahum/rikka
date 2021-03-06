import 'dart:convert';
import 'message.dart';
import 'utils.dart';
import 'error.dart';
import 'action.dart';

typedef EventMap = Map<String,
    Map<String, Event Function(Map<String, dynamic>, SegmentParser)>>;

const EventMap standardEventBuilderMap = {
  MetaEvent.ty: {HeartbeatEvent.detailTy: HeartbeatEvent._fromJson},
  MessageEvent.ty: {
    PrivateMessageEvent.detailTy: PrivateMessageEvent._fromJson,
    GroupMessageEvent.detailTy: GroupMessageEvent._fromJson,
  },
};

class EventParser {
  late final EventMap map;
  late final SegmentParser segmentParser;
  EventParser(this.segmentParser, [EventMap? extra]) {
    if (extra != null) {
      map = Map.from(standardEventBuilderMap)..addAll(extra);
    } else {
      map = standardEventBuilderMap;
    }
  }

  Event fromJson(Map<String, dynamic> json) {
    final type = json.tryRemove('type') as String;
    final detailType = json.tryRemove('detail_type') as String;
    final fs = map[type];
    if (fs != null) {
      final f = fs[detailType];
      if (f != null) {
        return f(json, segmentParser);
      }
    }
    return Event._fromJson(json, type, detailType);
  }

  dynamic _eor(Map<String, dynamic> json) {
    try {
      return fromJson(json);
    } on MissFieldError catch (e) {
      if (e.field == 'type') {
        return Response.fromJson(json);
      }
      rethrow;
    }
  }

  Event fromString(String json) {
    return fromJson(jsonDecode(json));
  }

  dynamic eorFromString(String json) {
    return _eor(jsonDecode(json));
  }
}

class Event {
  String id, impl, platform, selfId, type, detailType;
  String subType = '';
  double time;
  Map<String, dynamic> extra;
  Event(this.id, this.impl, this.platform, this.type, this.selfId,
      this.detailType, this.subType, this.time,
      [Map<String, dynamic>? extra])
      : extra = extra ?? {};
  Map<String, dynamic> toJson() {
    return _toJson({});
  }

  @override
  String toString() => jsonEncode(toJson());

  Map<String, dynamic> _toJson(Map<String, dynamic> data) {
    return extra
      ..addAll(data)
      ..addAll({
        'id': id,
        'impl': impl,
        'platform': platform,
        'self_id': selfId,
        'type': type,
        'detail_type': detailType,
        'sub_type': subType,
        'time': time
      });
  }

  Event._fromJson(Map<String, dynamic> data, this.type, this.detailType)
      : id = data.tryRemove('id') as String,
        impl = data.tryRemove('impl') as String,
        platform = data.tryRemove('platform') as String,
        selfId = data.tryRemove('self_id') as String,
        subType = data.tryRemove('sub_type') as String,
        time = data.tryRemove('time') as double,
        extra = data;
}

class MetaEvent extends Event {
  static const String ty = 'meta';
  MetaEvent(String id, String impl, String plateform, String selfId,
      String detailType, String subType, double time,
      [Map<String, dynamic>? extra])
      : super(
            id, impl, plateform, ty, selfId, detailType, subType, time, extra);
  MetaEvent._fromJson(Map<String, dynamic> data, String detailType)
      : super._fromJson(data, ty, detailType);
}

class HeartbeatEvent extends MetaEvent {
  static const String detailTy = 'heartbeat';
  int interval;
  HeartbeatEvent(String id, String impl, String plateform, String selfId,
      this.interval, num time, [Map<String, dynamic>? extra])
      : super(
            id, impl, plateform, selfId, detailTy, "", time.toDouble(), extra);
  HeartbeatEvent._fromJson(
      Map<String, dynamic> json, SegmentParser segmentParser)
      : interval = json.tryRemove('interval') as int,
        super._fromJson(json, detailTy);

  @override
  Map<String, dynamic> toJson() => _toJson({'interval': interval});
}

class MessageEvent extends Event {
  static const String ty = 'message';
  String messageId, altMessage, userId;
  List<Segment> message;
  MessageEvent(
      String id,
      String impl,
      String plateform,
      String selfId,
      String detailType,
      String subType,
      double time,
      this.messageId,
      this.altMessage,
      this.userId,
      this.message,
      [Map<String, dynamic>? extra])
      : super(
            id, impl, plateform, ty, selfId, detailType, subType, time, extra);
  MessageEvent._fromJson(
      Map<String, dynamic> data, SegmentParser segmentParser, String detailType)
      : messageId = data.tryRemove('message_id') as String,
        altMessage = data.tryRemove('alt_message') as String,
        userId = data.tryRemove('user_id') as String,
        message = segmentParser.fromJsonList(data.tryRemove('message')),
        super._fromJson(data, ty, detailType);
}

class PrivateMessageEvent extends MessageEvent {
  static const String detailTy = 'private';
  PrivateMessageEvent(
      String id,
      String impl,
      String plateform,
      String selfId,
      String subType,
      double time,
      String messageId,
      String altMessage,
      String userId,
      List<Segment> message,
      [Map<String, dynamic>? extra])
      : super(id, impl, plateform, selfId, detailTy, subType, time, messageId,
            altMessage, userId, message, extra);
  PrivateMessageEvent._fromJson(
      Map<String, dynamic> data, SegmentParser segmentParser)
      : super._fromJson(data, segmentParser, detailTy);

  @override
  Map<String, dynamic> toJson() => _toJson({
        'message_id': messageId,
        'alt_message': altMessage,
        'user_id': userId,
        'message': message,
      });
}

class GroupMessageEvent extends MessageEvent {
  static const String detailTy = 'group';
  String groupId;
  GroupMessageEvent(
      String id,
      String impl,
      String plateform,
      String selfId,
      String subType,
      double time,
      String messageId,
      String altMessage,
      String userId,
      this.groupId,
      List<Segment> message,
      [Map<String, dynamic>? extra])
      : super(id, impl, plateform, selfId, detailTy, subType, time, messageId,
            altMessage, userId, message, extra);
  GroupMessageEvent._fromJson(
      Map<String, dynamic> data, SegmentParser segmentParser)
      : groupId = data.tryRemove('group_id') as String,
        super._fromJson(data, segmentParser, detailTy);

  @override
  Map<String, dynamic> toJson() => _toJson({
        'message_id': messageId,
        'alt_message': altMessage,
        'user_id': userId,
        'group_id': groupId,
        'message': message,
      });
}
