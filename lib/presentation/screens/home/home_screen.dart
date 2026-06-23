import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../data/services/notification_service.dart';
import '../../widgets/core/tooba_shimmer.dart';
import '../notifications/notifications_screen.dart';
import '../tournaments/tournaments_screen.dart';
import '../matches/matches_screen.dart';
import 'banner_details_screen.dart';
import 'news_screen.dart';
import '../../../app/router/tooba_route.dart';

/// 📝 HINT AR: الشاشة الرئيسية — ترويسة (اسم + شعار + جرس) + سلايدر إعلانات
/// (يديره الأدمن) + كروت تنقّل: الأخبار، البطولات (يتحكّم الأدمن بإظهارها)،
/// المباريات. كل كارت يفتح شاشته بصيغتها الحالية.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<BannerModel>> _banners;
  late Future<bool> _tournamentsEnabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _banners = context.read<HomeRepository>().getActiveBanners();
    _tournamentsEnabled = _fetchTournamentsEnabled();
  }

  // 📝 HINT AR: علم إظهار «كارت البطولات» (يضبطه الأدمن من لوحة التحكم).
  // قراءة لمرة واحدة (ترشيد الاستهلاك) — تُحدَّث عند سحب التحديث.
  Future<bool> _fetchTournamentsEnabled() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('features')
          .get();
      return doc.data()?['tournamentsEnabled'] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _reload() async {
    setState(_load);
    await Future.wait([_banners, _tournamentsEnabled]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthCubit>().state;
    final userName =
        authState is AuthAuthenticated ? authState.user.name : 'زائر';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هلا بيك 👋',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(userName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        centerTitle: false,
        flexibleSpace: SafeArea(
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset('assets/images/logo.png', height: 38),
            ),
          ),
        ),
        actions: [_notificationBell(context)],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          children: [
            _bannerSection(),
            const SizedBox(height: 20),
            _navCardsSection(),
          ],
        ),
      ),
    );
  }

  // ── سلايدر الإعلانات ──────────────────────────────────────────────────
  Widget _bannerSection() {
    return FutureBuilder<List<BannerModel>>(
      future: _banners,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ToobaShimmerBanner(height: 160);
        }
        final banners = snap.data ?? [];
        if (banners.isEmpty) return const SizedBox.shrink();
        return _BannerSlider(banners: banners);
      },
    );
  }

  // ── كروت التنقّل (الأخبار / البطولات / المباريات) ──────────────────────
  Widget _navCardsSection() {
    return FutureBuilder<bool>(
      future: _tournamentsEnabled,
      builder: (context, snap) {
        final showTournaments = snap.data ?? true;
        return Column(
          children: [
            _navCard(
              icon: Icons.newspaper_rounded,
              color: Colors.blue,
              title: 'الأخبار',
              subtitle: 'آخر أخبار وفعّاليات المنصّة',
              onTap: () => Navigator.push(
                  context, ToobaRoute.to(const NewsScreen())),
            ),
            if (showTournaments)
              _navCard(
                icon: Icons.emoji_events_rounded,
                color: Colors.amber.shade800,
                title: 'البطولات',
                subtitle: 'البطولات الحالية والسابقة',
                onTap: () => Navigator.push(
                    context, ToobaRoute.to(const TournamentsScreen())),
              ),
            _navCard(
              icon: Icons.sports_soccer_rounded,
              color: Colors.green,
              title: 'المباريات',
              subtitle: 'جدول ونتائج المباريات',
              onTap: () => Navigator.push(
                  context, ToobaRoute.to(const MatchesScreen())),
            ),
          ],
        );
      },
    );
  }

  Widget _navCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationBell(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService.instance.unreadCountStream,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'الإشعارات',
              onPressed: () => Navigator.push(
                  context, ToobaRoute.to(const NotificationsScreen())),
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 📝 HINT AR: سلايدر صور تلقائي بـ PageView (بلا اعتمادية إضافية) + نقاط.
class _BannerSlider extends StatefulWidget {
  final List<BannerModel> banners;
  const _BannerSlider({required this.banners});

  @override
  State<_BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<_BannerSlider> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoplay();
  }

  // 📝 HINT AR: تقليب تلقائي كل 5 ثوانٍ (يلتفّ للبداية بعد آخر إعلان).
  void _startAutoplay() {
    if (widget.banners.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_current + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _openBanner(BannerModel b) {
    if (!b.hasDetails) return;
    Navigator.push(
      context,
      ToobaRoute.to(BannerDetailsScreen(banner: b)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) {
              final b = widget.banners[i];
              return GestureDetector(
                onTap: () => _openBanner(b),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: b.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (c, u) =>
                              Container(color: Colors.grey.shade200),
                          errorWidget: (c, u, e) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          ),
                        ),
                        if (b.title != null && b.title!.isNotEmpty)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.65),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Text(
                                b.title!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              final active = i == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? theme.colorScheme.primary
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
