import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/banner_model.dart';
import '../../../data/models/news_model.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../data/services/notification_service.dart';
import '../../widgets/core/tooba_shimmer.dart';
import '../notifications/notifications_screen.dart';
import '../../../app/router/tooba_route.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: الشاشة الرئيسية — ترويسة (اسم + شعار + جرس) + سلايدر إعلانات
/// (يديره الأدمن) + قسم الأخبار (إعجاب/مشاركة لأي مستخدم).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<BannerModel>> _banners;
  late Future<List<NewsModel>> _news;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<HomeRepository>();
    _banners = repo.getActiveBanners();
    _news = repo.getPublishedNews();
  }

  Future<void> _reload() async {
    setState(_load);
    await Future.wait([_banners, _news]);
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
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
        centerTitle: true,
        flexibleSpace: SafeArea(
          child: Center(
            child: Image.asset('assets/images/logo.png', height: 36),
          ),
        ),
        actions: [_notificationBell(context)],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            _bannerSection(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('آخر الأخبار',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            _newsSection(),
            const SizedBox(height: 24),
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

  // ── قسم الأخبار ───────────────────────────────────────────────────────
  Widget _newsSection() {
    return FutureBuilder<List<NewsModel>>(
      future: _news,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const ToobaShimmerList(count: 3, tileHeight: 200);
        }
        final news = snap.data ?? [];
        if (news.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            child: Center(
              child: Text('لا توجد أخبار حالياً',
                  style: TextStyle(color: Colors.grey[600])),
            ),
          );
        }
        return Column(
          children: news
              .map((n) => _NewsCard(
                    news: n,
                    onChanged: () => setState(() {}),
                  ))
              .toList(),
        );
      },
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              return Padding(
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

/// 📝 HINT AR: بطاقة خبر — صورة + عنوان + مقال + إعجاب + مشاركة.
class _NewsCard extends StatefulWidget {
  final NewsModel news;
  final VoidCallback onChanged;
  const _NewsCard({required this.news, required this.onChanged});

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  late NewsModel _news = widget.news;
  bool _busy = false;

  Future<void> _toggleLike() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      ToobaSnackBar.info(context, 'سجّل الدخول للإعجاب');
      return;
    }
    if (_busy) return;
    final uid = authState.user.id;
    final liked = _news.likedBy(uid);
    // تحديث متفائل
    setState(() {
      _busy = true;
      final newLikes = List<String>.from(_news.likes);
      liked ? newLikes.remove(uid) : newLikes.add(uid);
      _news = _news.copyWith(likes: newLikes);
    });
    try {
      await context
          .read<HomeRepository>()
          .toggleLike(_news.id, uid, !liked);
    } catch (_) {
      // تراجع عند الفشل
      setState(() {
        final revert = List<String>.from(_news.likes);
        liked ? revert.add(uid) : revert.remove(uid);
        _news = _news.copyWith(likes: revert);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final repo = context.read<HomeRepository>();
    final text = '${_news.title}\n\n${_news.body}\n\n📲 عبر تطبيق طوبة';
    await Share.share(text);
    try {
      await repo.incrementShare(_news.id);
      if (mounted) {
        setState(() =>
            _news = _news.copyWith(shareCount: _news.shareCount + 1));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final uid = (context.read<AuthCubit>().state is AuthAuthenticated)
        ? (context.read<AuthCubit>().state as AuthAuthenticated).user.id
        : null;
    final liked = _news.likedBy(uid);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_news.imageUrl != null && _news.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: _news.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(
                    height: 180, color: Colors.grey.shade200),
                errorWidget: (c, u, e) => Container(
                  height: 180,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_news.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                if (_news.body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(_news.body,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.5)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: _toggleLike,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              liked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: liked ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text('${_news.likeCount}',
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _share,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.share_outlined,
                                color: Colors.grey, size: 19),
                            const SizedBox(width: 4),
                            Text('${_news.shareCount}',
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_news.createdAt != null)
                      Text(_relativeTime(_news.createdAt!),
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'قبل ${diff.inHours} ساعة';
    if (diff.inDays < 30) return 'قبل ${diff.inDays} يوم';
    return 'قبل ${(diff.inDays / 30).floor()} شهر';
  }
}
