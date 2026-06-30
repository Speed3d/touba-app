import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: شاشة المحادثة (كابتن↔كابتن في التحدي). بثّ حيّ للرسائل (snapshots
/// — مسموح لأنها الشاشة الجارية)، تصفير غير المقروء عند الفتح، وفقاعات بسيطة.
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  const ChatScreen({super.key, required this.chatId, required this.title});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  String? _uid;
  String _name = '';

  @override
  void initState() {
    super.initState();
    final st = context.read<AuthCubit>().state;
    if (st is AuthAuthenticated) {
      _uid = st.user.id;
      _name = st.user.name;
    }
    if (_uid != null) {
      context.read<ChatRepository>().markAsRead(widget.chatId, _uid!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _uid == null || _sending) return;
    setState(() => _sending = true);
    final repo = context.read<ChatRepository>();
    try {
      await repo.sendMessage(
          chatId: widget.chatId,
          senderId: _uid!,
          senderName: _name,
          content: text);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ToobaSnackBar.error(
            context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ChatRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: repo.streamMessages(widget.chatId),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data!;
                if (_uid != null) repo.markAsRead(widget.chatId, _uid!);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) {
                    _scroll.jumpTo(_scroll.position.maxScrollExtent);
                  }
                });
                if (msgs.isEmpty) {
                  return Center(
                      child: Text('ابدأ المحادثة',
                          style: TextStyle(color: Colors.grey[600])));
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (c, i) => _bubble(msgs[i]),
                );
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessageModel m) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (m.isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.transparent),
          ),
          child: Text(m.content,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700])),
        ),
      );
    }
    final mine = _uid != null && m.isFromMe(_uid!);
    final time = m.sentAt != null ? DateFormat('HH:mm').format(m.sentAt!) : '';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFF00D166).withValues(alpha: isDark ? 0.2 : 1)
              : (isDark ? AppColors.surfaceDark : Colors.grey.shade200),
          border: mine
              ? Border.all(color: isDark ? const Color(0xFF00D166).withValues(alpha: 0.5) : Colors.transparent)
              : Border.all(color: isDark ? const Color(0xFF1A2A3A) : Colors.transparent),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: mine ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !mine ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text(m.senderName,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[700])),
            Text(m.content,
                style: TextStyle(color: mine ? (isDark ? const Color(0xFF00D166) : Colors.white) : (isDark ? Colors.white : Colors.black87))),
            const SizedBox(height: 4),
            Text(time,
                style: TextStyle(
                    fontSize: 9,
                    color: mine ? (isDark ? const Color(0xFF00D166).withValues(alpha: 0.7) : Colors.white70) : (isDark ? Colors.grey[500] : Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة…',
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _send),
            ),
          ],
        ),
      ),
    );
  }
}
