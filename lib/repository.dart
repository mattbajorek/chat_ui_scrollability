import 'dart:math';

import 'main.dart';

class Message {
  final String id;
  final String content;
  final DateTime createdAt;

  Message({required this.id, required this.content, required this.createdAt});
}

final mockMessages = List<Message>.generate(mockMessagesSize, (index) {
  final id = '${index + 1}';
  final content = 'Message ${index + 1}';
  final createdAt = DateTime.now().add(Duration(seconds: index));
  return Message(id: id, content: content, createdAt: createdAt);
});

Future<Message> getMessageByMessageId({required String messageId}) async {
  await Future.delayed(Duration(milliseconds: 500));
  return mockMessages.firstWhere((message) => message.id == messageId);
}

Future<Message> getFirstMessageForMessageThreadId() async {
  await Future.delayed(Duration(milliseconds: 500));
  return mockMessages.first;
}

Future<Message> getLastMessageForMessageThreadId() async {
  await Future.delayed(Duration(milliseconds: 500));
  return mockMessages.last;
}

List<Message> getMessagesLessThanId({required String lessThanId, int limit = mockPaginationLimit}) {
  final lessThanMessageIndex = mockMessages.indexWhere((message) => message.id == lessThanId);
  final lessThanMessages = mockMessages
      .sublist(max(0, lessThanMessageIndex - limit), lessThanMessageIndex)
      .reversed
      .toList();
  return lessThanMessages;
}

List<Message> getMessagesGreaterThanId({required String greaterThanId, int limit = mockPaginationLimit}) {
  final greaterThanMessageIndex = mockMessages.indexWhere((message) => message.id == greaterThanId);
  final greaterThanMessages = mockMessages
      .sublist(greaterThanMessageIndex + 1, min(mockMessages.length, greaterThanMessageIndex + limit + 1))
      .toList();
  return greaterThanMessages;
}

Future<List<Message>> getMessages({
  int limit = mockPaginationLimit,
  String? initialMessageId,
  String? lessThanId,
  String? greaterThanId,
}) async {
  await Future.delayed(Duration(milliseconds: 500));

  final allMessages = <Message>[];

  if (initialMessageId != null) {
    final halfLimit = (limit / 2).round();
    final lessThanMessages = getMessagesLessThanId(lessThanId: initialMessageId, limit: halfLimit);
    allMessages.addAll(lessThanMessages);
    final greaterThanMessages = getMessagesGreaterThanId(greaterThanId: initialMessageId, limit: halfLimit);
    allMessages.addAll(greaterThanMessages);
  }

  if (lessThanId != null) {
    final lessThanMessages = getMessagesLessThanId(lessThanId: lessThanId, limit: limit);
    allMessages.addAll(lessThanMessages);
  }

  if (greaterThanId != null) {
    final greaterThanMessages = getMessagesGreaterThanId(greaterThanId: greaterThanId, limit: limit);
    allMessages.addAll(greaterThanMessages);
  }

  return allMessages;
}
