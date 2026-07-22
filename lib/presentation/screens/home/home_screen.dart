
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/models/news_model.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../data/services/notification_service.dart';
import '../../widgets/core/tooba_shimmer.dart';
import '../notifications/notifications_screen.dart';
import '../tournaments/tournaments_screen.dart';
import '../matches/matches_screen.dart';
import 'banner_details_screen.dart';
import 'news_screen.dart';
import '../../../app/router/tooba_route.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/repositories/player_repository.dart';
import '../players/player_detail_screen.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: الشاشة الرئيسية — تصميم جديد عصري مستوحى من تطبيق FotMob
/// يحتوي على:
/// - شريط علوي مخصص (مرحباً + جرس الإشعارات)
/// - إعلانات متغيرة (Banners Carousel)
/// - أزرار الإجراءات السريعة (Quick Action Chips)
/// - قسم آخر الأخبار بشكل أفقي
/// - البطولات الجارية ككروت أنيقة
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<BannerModel>> _banners;
  late Future<List<NewsModel>> _news;
  late Future<bool> _tournamentsEnabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _banners = context.read<HomeRepository>().getActiveBanners();
    _news = context.read<HomeRepository>().getPublishedNews(limit: 5);
    _tournamentsEnabled = _fetchTournamentsEnabled();
  }

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
    await Future.wait([_banners, _news, _tournamentsEnabled]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = context.watch<AuthCubit>().state;
    final userName =
        authState is AuthAuthenticated ? authState.user.name : AppLocalizations.of(context)!.visitor;

    // 📝 HINT AR: خلفية الشاشة تستخدم ألوان التصميم الجديد
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _reload,
          color: context.primaryColor,
          backgroundColor: context.cardColor,
          child: CustomScrollView(
            slivers: [
              // 📝 HINT AR: الشريط العلوي الثابت والمخصص
              SliverToBoxAdapter(
                child: _buildHeader(context, userName, isDark),
              ),
              
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100), // مساحة لشريط التنقل العائم
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _bannerSection(),
                    const SizedBox(height: 16),
                    _quickActionsSection(isDark),
                    const SizedBox(height: 24),
                    _newsTickerSection(isDark),
                    const SizedBox(height: 24),
                    _tournamentsSection(isDark),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── الشريط العلوي ───────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, String userName, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'طوبة', // Brand name
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: context.primaryColor,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('⚽', style: TextStyle(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.welcomeUser(userName),
                style: TextStyle(
                  fontSize: 13,
                  color: context.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          _notificationBell(context, isDark),
        ],
      ),
    );
  }

  // ── سلايدر الإعلانات ──────────────────────────────────────────────────
  Widget _bannerSection() {
    return FutureBuilder<List<BannerModel>>(
      future: _banners,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ToobaShimmerBanner(height: 168),
          );
        }
        final banners = snap.data ?? [];
        if (banners.isEmpty) return const SizedBox.shrink();
        return _BannerSlider(banners: banners);
      },
    );
  }

  // ── أزرار الإجراءات السريعة ─────────────────────────────────────────────
  Widget _quickActionsSection(bool isDark) {
    return FutureBuilder<bool>(
      future: _tournamentsEnabled,
      builder: (context, snap) {
        final showTournaments = snap.data ?? true;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _quickActionChip(
                title: AppLocalizations.of(context)!.matches,
                icon: '⚽',
                isDark: isDark,
                onTap: () => Navigator.push(context, ToobaRoute.to(const MatchesScreen())),
              ),
              if (showTournaments)
                _quickActionChip(
                  title: AppLocalizations.of(context)!.tournaments,
                  icon: '🏆',
                  isDark: isDark,
                  onTap: () => Navigator.push(context, ToobaRoute.to(const TournamentsScreen())),
                ),
              _quickActionChip(
                title: AppLocalizations.of(context)!.news,
                icon: '📰',
                isDark: isDark,
                onTap: () => Navigator.push(context, ToobaRoute.to(const NewsScreen())),
              ),
              _quickActionChip(
                title: AppLocalizations.of(context)!.myCard,
                icon: '🃏',
                isDark: isDark,
                onTap: () async {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is! AuthAuthenticated) {
                    ToobaSnackBar.info(context, AppLocalizations.of(context)!.mustLoginFirst);
                    return;
                  }
                  final pid = authState.user.linkedPlayerId;
                  if (pid == null || pid.isEmpty) {
                    ToobaSnackBar.info(context, AppLocalizations.of(context)!.noPlayerCardCurrently);
                    return;
                  }
                  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                  try {
                    final pModel = await context.read<PlayerRepository>().getPlayerById(pid);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    Navigator.push(context, ToobaRoute.to(PlayerDetailScreen(player: pModel)));
                  } catch (e) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ToobaSnackBar.error(context, AppLocalizations.of(context)!.errorFetchingCard);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickActionChip({
    required String title,
    required String icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── شريط الأخبار المتحرك ───────────────────────────────────────────────
  Widget _newsTickerSection(bool isDark) {
    return FutureBuilder<bool>(
      future: Future.value(true), // We don't have a toggle for news yet, but to maintain structure
      builder: (context, _) {
        return StreamBuilder<List<NewsModel>>(
          stream: context.read<HomeRepository>().getPublishedNewsStream(limit: 5),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 48);
            }
            final newsList = snap.data ?? [];
            if (newsList.isEmpty) return const SizedBox.shrink();

            final newsText = newsList.map((n) => '📰 ${n.title}').join('   •   ');

            return GestureDetector(
              onTap: () => Navigator.push(context, ToobaRoute.to(const NewsScreen())),
              child: Container(
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D1826) : Colors.white,
                  border: Border.all(color: context.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                      ),
                      alignment: Alignment.center,
                      child: Text(AppLocalizations.of(context)!.urgent, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    Expanded(
                      child: Marquee(
                        text: newsText,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textColor),
                        scrollAxis: Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        blankSpace: 50.0,
                        velocity: -35.0, // سرعة سالبة لكي يمرر من اليسار لليمين (يناسب العربية)
                        startPadding: 10.0,
                        pauseAfterRound: const Duration(seconds: 1),
                        accelerationDuration: const Duration(seconds: 1),
                        accelerationCurve: Curves.linear,
                        decelerationDuration: const Duration(milliseconds: 500),
                        decelerationCurve: Curves.easeOut,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  // ── قسم البطولات الجارية ─────────────────────────────────────────────────
  Widget _tournamentsSection(bool isDark) {
    return FutureBuilder<bool>(
      future: _tournamentsEnabled,
      builder: (context, snap) {
        final showTournaments = snap.data ?? true;
        if (!showTournaments) return const SizedBox.shrink();

        // 📝 HINT AR: بيانات ثابتة كعينة مبدئية للبطولات لتطبيق التصميم
        final mockTourneys = [
          {'title': AppLocalizations.of(context)!.baghdadMajorTournament, 'subtitle': AppLocalizations.of(context)!.round3of4_8teams, 'status': AppLocalizations.of(context)!.ongoing, 'icon': '🏆', 'color': context.primaryColor},
          {'title': AppLocalizations.of(context)!.localYouthLeague, 'subtitle': AppLocalizations.of(context)!.round1of6_6teams, 'status': AppLocalizations.of(context)!.comingSoon, 'icon': '⭐', 'color': Colors.amber},
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.ongoingTournaments,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textColor),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, ToobaRoute.to(const TournamentsScreen())),
                      child: Text(
                        AppLocalizations.of(context)!.viewAll,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              ...mockTourneys.map((t) {
                final color = t['color'] as Color;
                return GestureDetector(
                  onTap: () => Navigator.push(context, ToobaRoute.to(const TournamentsScreen())),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(t['icon'] as String, style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['title'] as String,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textColor),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t['subtitle'] as String,
                                style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
                              ),
                              const SizedBox(height: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  border: Border.all(color: color.withValues(alpha: 0.2)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  t['status'] as String,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_left, color: context.secondaryTextColor),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── زر الإشعارات ────────────────────────────────────────────────────────
  Widget _notificationBell(BuildContext context, bool isDark) {
    return StreamBuilder<int>(
      stream: NotificationService.instance.unreadCountStream,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(context, ToobaRoute.to(const NotificationsScreen())),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: context.borderColor),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text('🔔', style: TextStyle(fontSize: 20)),
                if (count > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.cardColor, width: 2),
                      ),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 📝 HINT AR: سلايدر صور تلقائي بـ PageView مع نقاط تنقل عصرية
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
    return Column(
      children: [
        SizedBox(
          height: 168, // نفس ارتفاع التصميم (168px)
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
                    borderRadius: BorderRadius.circular(22), // انحناء أكثر سلاسة
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: b.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(color: context.cardColor),
                          errorWidget: (c, u, e) => Container(
                            color: context.cardColor,
                            child: Icon(Icons.image_not_supported, color: context.secondaryTextColor),
                          ),
                        ),
                        // تدرج لوني أسفل الصورة لتوضيح النص
                        if (b.title != null && b.title!.isNotEmpty)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Text(
                                b.title!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                                maxLines: 2,
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              final active = i == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? context.primaryColor : context.secondaryTextColor.withValues(alpha: 0.3),
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
