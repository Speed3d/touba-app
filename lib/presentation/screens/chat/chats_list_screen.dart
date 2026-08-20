import '../../../core/utils/image_helper.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:intl/intl.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../app/router/tooba_route.dart';
import 'chat_screen.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: قائمة محادثات المستخدم (بثّ حيّ، مرتّبة بآخر رسالة) — كل عنصر يفتح
/// المحادثة. شارة عدد غير المقروء لكل محادثة.
class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AuthCubit>().state;
    final uid = st is AuthAuthenticated ? st.user.id : null;
    final repo = context.read<ChatRepository>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myChatsTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: uid == null
            ? _visitorView(context)
            : StreamBuilder<List<ChatModel>>(
                stream: repo.streamUserChats(uid),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final chats = snap.data!;
                  if (chats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forum_outlined,
                              size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(AppLocalizations.of(context)!.noChatsYet,
                              style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text(AppLocalizations.of(context)!.chatOpensWhenChallengeAccepted,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: chats.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => _tile(context, chats[i], uid),
                  );
                },
              ),
      ),
    );
  }

  // 📝 HINT AR: الزائر لا محادثات له — نوجّهه لتسجيل الدخول/إنشاء حساب.
  // logout() يصدر AuthUnauthenticated فيُظهر AuthWrapper شاشة الدخول.
  Widget _visitorView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.loginToViewYourChats,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(AppLocalizations.of(context)!.chatsOpenBetweenCaptainsWhenChallengeAccepted,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<AuthCubit>().logout(),
              icon: const Icon(Icons.login),
              label: Text(AppLocalizations.of(context)!.loginOrCreateAccountBtn),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, ChatModel chat, String uid) {
    final photo = chat.otherPhoto(uid);
    final unread = chat.unreadFor(uid);
    final time = chat.lastMessageTime != null
        ? DateFormat('d MMM • HH:mm', 'ar').format(chat.lastMessageTime!)
        : '';
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: (photo != null && photo.isNotEmpty)
            ? ImageHelper.getProvider(photo)
            : null,
        child: (photo == null || photo.isEmpty)
            ? const Icon(Icons.shield, color: Colors.grey)
            : null,
      ),
      title: Text(chat.otherName(uid),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(chat.lastMessage ?? AppLocalizations.of(context)!.startConversation,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          const SizedBox(height: 4),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle),
              child: Text('$unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        ToobaRoute.to(
            ChatScreen(chatId: chat.id, title: chat.otherName(uid))),
      ),
    );
  }
}
