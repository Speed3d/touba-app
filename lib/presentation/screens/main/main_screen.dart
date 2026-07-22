import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../widgets/core/tooba_bottom_nav.dart';
import '../home/home_screen.dart';
import '../teams/teams_screen.dart';
import '../chat/chats_list_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: الشاشة الجذر بشريط تنقّل سفلي «عائم» بـ4 أزرار:
/// الرئيسية / الفريق / المحادثات / الإعدادات.
/// (البطولات والمباريات انتقلتا ككروت داخل الشاشة الرئيسية، بتحكّم الأدمن
/// بإظهار البطولات عبر `settings/features.tournamentsEnabled`.)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 📝 HINT AR: الصفحات ثابتة (IndexedStack يحفظ حالتها عند التنقّل بينها).
  static const List<Widget> _pages = [
    HomeScreen(),
    TeamsScreen(),
    ChatsListScreen(),
    SettingsScreen(),
  ];

  List<ToobaNavItem> _getItems(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      ToobaNavItem(Icons.home_outlined, Icons.home, loc.navHome),
      ToobaNavItem(Icons.shield_outlined, Icons.shield, loc.navTeam),
      ToobaNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, loc.navChats),
      ToobaNavItem(Icons.settings_outlined, Icons.settings, loc.settings),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AuthCubit>().state;
    final uid = st is AuthAuthenticated ? st.user.id : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBackground(
        showOrbs: _currentIndex == 0, // اظهر الدوائر فقط في الرئيسية
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: uid == null
          ? _nav(const {})
          : StreamBuilder<int>(
              stream: context.read<ChatRepository>().streamUnreadCount(uid),
              builder: (context, snap) {
                final unread = snap.data ?? 0;
                return _nav(unread > 0 ? {2: unread} : const {});
              },
            ),
    );
  }

  Widget _nav(Map<int, int> badges) {
    return ToobaBottomNav(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      items: _getItems(context),
      badges: badges,
    );
  }
}
