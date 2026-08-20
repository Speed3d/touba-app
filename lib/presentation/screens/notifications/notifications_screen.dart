import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/team_repository.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../cubits/notifications/notifications_cubit.dart';
import '../../cubits/notifications/notifications_state.dart';
import '../../cubits/team/team_cubit.dart';
import '../../cubits/tournament/tournament_cubit.dart';
import '../../widgets/core/decorated_background.dart';
import '../teams/team_details_screen.dart';
import '../tournaments/tournament_details_screen.dart';
import '../chat/chat_screen.dart';
import '../challenges/challenges_screen.dart';
import '../../../app/router/tooba_route.dart';
import '../../../l10n/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit()..startListening(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notifications),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              final hasUnread = state is NotificationsLoaded &&
                  state.notifications.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllAsRead(),
                child: Text(AppLocalizations.of(context)!.readAll),
              );
            },
          ),
        ],
      ),
      body: DecoratedBackground(
        showOrbs: false,
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NotificationsError) {
              return Center(child: Text(AppLocalizations.of(context)!.errorPrefix(state.message)));
            }
            if (state is NotificationsLoaded) {
              if (state.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.noNotificationsYet,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark ? Colors.white54 : Colors.black45,
                          )),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.notifications.length,
                itemBuilder: (context, i) {
                  final n = state.notifications[i];
                  return _NotificationTile(notification: n);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) =>
          context.read<NotificationsCubit>().deleteNotification(notification.id),
      child: InkWell(
        onTap: () {
          if (isUnread) {
            context.read<NotificationsCubit>().markAsRead(notification.id);
          }
          _navigate(context);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isUnread
                ? (isDark
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.primary.withValues(alpha: 0.06))
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
            ),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  notification.type.icon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(notification.body,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(context, notification.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            trailing: isUnread
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // 📝 HINT AR: يفتح الشاشة المناسبة حسب محتوى الإشعار (data): بطولة → تفاصيلها،
  // فريق → تفاصيله (حيث يجد الكابتن زر الإدارة والطلبات).
  void _navigate(BuildContext context) {
    final data = notification.data;
    if (data == null) return;
    final tournamentId = (data['tournamentId'] as String?) ?? '';
    final teamId = (data['teamId'] as String?) ?? '';
    final chatId = (data['chatId'] as String?) ?? '';
    final challengeId = (data['challengeId'] as String?) ?? '';

    if (chatId.isNotEmpty) {
      Navigator.push(
        context,
        ToobaRoute.to(ChatScreen(chatId: chatId, title: AppLocalizations.of(context)!.challengeChat)),
      );
    } else if (challengeId.isNotEmpty) {
      Navigator.push(context, ToobaRoute.to(const ChallengesScreen()));
    } else if (tournamentId.isNotEmpty) {
      Navigator.push(
        context,
        ToobaRoute.to(BlocProvider(
          create: (ctx) => TournamentCubit(
            ctx.read<TournamentRepository>(),
            ctx.read<MatchRepository>(),
            ctx.read<TeamRepository>(),
          )..fetchDetails(tournamentId),
          child: TournamentDetailsScreen(tournamentId: tournamentId),
        )),
      );
    } else if (teamId.isNotEmpty) {
      Navigator.push(
        context,
        ToobaRoute.to(BlocProvider(
          create: (ctx) => TeamCubit(
            ctx.read<TeamRepository>(),
            ctx.read<PlayerRepository>(),
          ),
          child: TeamDetailsScreen(teamId: teamId),
        )),
      );
    }
  }

  String _timeAgo(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return AppLocalizations.of(context)!.justNow;
    if (diff.inHours < 1) return AppLocalizations.of(context)!.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return diff.inHours == 1 ? AppLocalizations.of(context)!.oneHourAgo : AppLocalizations.of(context)!.hoursAgo(diff.inHours);
    if (diff.inDays == 1) return AppLocalizations.of(context)!.yesterday;
    return diff.inDays == 1 ? AppLocalizations.of(context)!.oneDayAgo : AppLocalizations.of(context)!.daysAgo(diff.inDays);
  }
}
