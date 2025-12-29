import 'package:chat_ui_scrollability/repository.dart';
import 'package:flutter/material.dart';

import 'auxilliary.dart';

const mockMessagesSize = 1000;
// const mockMessagesSize = 5;

const mockPaginationLimit = 20;

void main() {
  final messageSelectedId = null;
  // final messageSelectedId = '990';
  runApp(ChatUIScrollability(messageSelectedId: messageSelectedId));
}

const topAnchor = 0.0;
const middleAnchor = 0.5;
const bottomAnchor = 1.0;
const centerKey = ValueKey('messagesListViewCenterMessage');
const centerLine = SliverToBoxAdapter(key: centerKey, child: Empty);

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(16)),
      child: Text(message.content, style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
  }
}

class ChatUIScrollability extends StatefulWidget {
  final String? messageSelectedId;

  const ChatUIScrollability({super.key, this.messageSelectedId});

  @override
  State<ChatUIScrollability> createState() => _ChatUIScrollabilityState();
}

class _ChatUIScrollabilityState extends State<ChatUIScrollability> {
  final _scrollController = ScrollController();

  double _anchor = bottomAnchor;
  bool _allFitsInView = true;

  Message? _firstMessage;
  Message? _centerMessage;
  Message? _lastMessage;

  // Storage for messages
  List<Message> _messagesOlder = [];
  List<Message> _messagesNewer = [];

  // Efficient deduplication using Sets for O(1) lookups
  final Set<String> _messageIdsNewer = <String>{};
  final Set<String> _messageIdsOlder = <String>{};

  @override
  void initState() {
    super.initState();
    _loadMoreMessages(isInitial: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMoreMessages({bool isInitial = false, bool isOlder = false, bool isNewer = false}) async {
    if (!mounted) {
      return;
    }

    final hasMessageId = widget.messageSelectedId != null;

    if (isInitial) {
      _messagesOlder = [];
      _messagesNewer = [];
      _firstMessage = null;
      _centerMessage = null;
      _anchor = bottomAnchor;
      _messageIdsNewer.clear();
      _messageIdsOlder.clear();

      final futures = await Future.wait([
        getFirstMessageForMessageThreadId(),
        getLastMessageForMessageThreadId(),
        if (hasMessageId) getMessageByMessageId(messageId: widget.messageSelectedId!),
      ]);

      _firstMessage = futures[0];
      _lastMessage = futures[1];
      _centerMessage = hasMessageId ? futures[2] : _lastMessage;
    }

    final additionalMessages = await getMessages(
      initialMessageId: isInitial ? widget.messageSelectedId : null,
      lessThanId: isOlder
          ? _messagesOlder.isNotEmpty
                ? _messagesOlder.last.id
                : _centerMessage?.id
          : null,
      greaterThanId: isNewer
          ? _messagesNewer.isNotEmpty
                ? _messagesNewer.last.id
                : _centerMessage?.id
          : null,
    );

    final messagesOlder = additionalMessages
        .where((message) => _centerMessage != null ? message.createdAt.isBefore(_centerMessage!.createdAt) : true)
        .toList();
    final messagesNewer = additionalMessages
        .where((message) => _centerMessage != null ? message.createdAt.isAfter(_centerMessage!.createdAt) : true)
        .toList();

    _messagesOlder.addAll(messagesOlder);
    _messageIdsOlder.addAll(messagesOlder.map((message) => message.id));
    _messagesNewer.addAll(messagesNewer);
    _messageIdsNewer.addAll(messagesNewer.map((message) => message.id));

    setState(() {});
  }

  void _handleOverflow(ScrollMetrics metrics) {
    if (_allFitsInView) {
      final hasOverflow = metrics.extentTotal > metrics.extentInside;

      if (!hasOverflow) {
        return;
      }

      final isCenterLastMessage = _centerMessage?.id == _lastMessage?.id;
      final isCenterFirstMessage = _centerMessage?.id == _firstMessage?.id;

      setState(() {
        _allFitsInView = false;
        _anchor = isCenterLastMessage
            ? topAnchor
            : isCenterFirstMessage
            ? bottomAnchor
            : middleAnchor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCenterLastMessage = _centerMessage?.id == _lastMessage?.id;
    final isCenterFirstMessage = _centerMessage?.id == _firstMessage?.id;

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(backgroundColor: Colors.lightBlue, title: Text(title)),
        body: _centerMessage == null || _firstMessage == null || _lastMessage == null
            ? const CenteredProgressIndicator()
            : NotificationListener<ScrollMetricsNotification>(
                onNotification: (n) {
                  _handleOverflow(n.metrics);
                  return false;
                },
                child: CustomScrollView(
                  reverse: true,
                  center: centerKey,
                  anchor: _anchor,
                  controller: _scrollController,
                  slivers: [
                    if (!isCenterLastMessage && !_messageIdsNewer.contains(_lastMessage!.id))
                      SliverLoader(
                        visibilityDetectorKey: const ValueKey('loadedMessagesSliverLoadingNewer'),
                        onVisibilityChanged: () => _loadMoreMessages(isNewer: true),
                      ),
                    // This list in incrementing order
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        childCount: _messagesNewer.length,
                        (context, index) => MessageBubble(message: _messagesNewer[index]),
                      ),
                    ),
                    if (_anchor == topAnchor || _anchor == middleAnchor) centerLine,
                    if (_centerMessage != null) SliverToBoxAdapter(child: MessageBubble(message: _centerMessage!)),
                    if (_anchor == bottomAnchor && !_allFitsInView) centerLine,
                    // This list in decrementing order (only if after the center line)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(childCount: _messagesOlder.length, (context, index) {
                        final calculatedIndex = _allFitsInView ? _messagesOlder.length - index - 1 : index;
                        return MessageBubble(message: _messagesOlder[calculatedIndex]);
                      }),
                    ),
                    if (!isCenterFirstMessage && !_messageIdsOlder.contains(_firstMessage!.id))
                      SliverLoader(
                        visibilityDetectorKey: const ValueKey('loadedMessagesSliverLoadingOlder'),
                        onVisibilityChanged: () => _loadMoreMessages(isOlder: true),
                      ),
                    if (_anchor == bottomAnchor && _allFitsInView) centerLine,
                  ],
                ),
              ),
      ),
    );
  }
}
