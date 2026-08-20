import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/news_model.dart';
import '../../../data/repositories/home_repository.dart';
import '../../widgets/core/decorated_background.dart';
import '../../widgets/core/tooba_shimmer.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../app/router/tooba_route.dart';
import 'news_detail_screen.dart';
import '../../../l10n/app_localizations.dart';

/// شاشة الأخبار المحسّنة (Stunning UI)
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBackground(
        showOrbs: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  AppLocalizations.of(context)!.latestNews,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
            ),
          StreamBuilder<List<NewsModel>>(
            stream: context.read<HomeRepository>().getPublishedNewsStream(limit: 30),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: ToobaShimmerList(count: 4, tileHeight: 250),
                  ),
                );
              }

              final news = snap.data ?? [];
              if (news.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.newspaper_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noNewsCurrently,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final n = news[index];
                      final isFeatured = index == 0; // أول خبر نعطيه تصميم مميز (Featured)
                      return _NewsCard(news: n, isFeatured: isFeatured);
                    },
                    childCount: news.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}

class _NewsCard extends StatefulWidget {
  final NewsModel news;
  final bool isFeatured;
  const _NewsCard({required this.news, this.isFeatured = false});

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _busy = false;

  Future<void> _toggleLike() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      ToobaSnackBar.info(context, AppLocalizations.of(context)!.loginToLike);
      return;
    }
    if (_busy) return;
    
    final uid = authState.user.id;
    final liked = widget.news.likedBy(uid);
    
    setState(() => _busy = true);
    
    try {
      // Optimitistic update happens via Stream rebuilding, but toggle triggers the backend.
      await context.read<HomeRepository>().toggleLike(widget.news.id, uid, !liked);
    } catch (_) {
      if (!mounted) return;
      ToobaSnackBar.error(context, AppLocalizations.of(context)!.errorLiking);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final repo = context.read<HomeRepository>();
    final text = '📰 ${widget.news.title}\n\n${widget.news.body}\n\n📲 ${AppLocalizations.of(context)!.viaToobaApp}';
    try {
      await Share.share(text);
      await repo.incrementShare(widget.news.id);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final uid = (context.read<AuthCubit>().state is AuthAuthenticated)
        ? (context.read<AuthCubit>().state as AuthAuthenticated).user.id
        : null;
    final liked = widget.news.likedBy(uid);

    if (widget.isFeatured) {
      return _buildFeaturedCard(context, isDark, liked);
    }
    return _buildStandardCard(context, isDark, liked);
  }

  Widget _buildFeaturedCard(BuildContext context, bool isDark, bool liked) {
    return GestureDetector(
      onTap: () => Navigator.push(context, ToobaRoute.to(NewsDetailScreen(news: widget.news))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // صورة الخبر المميز كاملة كخلفية
              if (widget.news.imageUrl != null && widget.news.imageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: widget.news.imageUrl!,
                  height: 320,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(height: 320, color: Colors.grey.shade300),
                  errorWidget: (c, u, e) => Container(height: 320, color: Colors.grey.shade300),
                )
              else
                Container(
                  height: 320,
                  width: double.infinity,
                  color: Theme.of(context).primaryColor,
                  child: const Icon(Icons.newspaper, size: 60, color: Colors.white54),
                ),
              
              // تدرج لوني للنص
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                      stops: const [0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              
              // محتوى الخبر
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(AppLocalizations.of(context)!.featured, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.news.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.news.body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.news.body,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildInteractionsRow(isDark: true, liked: liked, isFeatured: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardCard(BuildContext context, bool isDark, bool liked) {
    return GestureDetector(
      onTap: () => Navigator.push(context, ToobaRoute.to(NewsDetailScreen(news: widget.news))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1E2A38) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.news.imageUrl != null && widget.news.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: widget.news.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(height: 180, color: isDark ? Colors.grey[800] : Colors.grey.shade200),
                  errorWidget: (c, u, e) => Container(height: 180, color: isDark ? Colors.grey[800] : Colors.grey.shade200),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.news.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (widget.news.body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.news.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 12),
                  _buildInteractionsRow(isDark: isDark, liked: liked, isFeatured: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionsRow({required bool isDark, required bool liked, required bool isFeatured}) {
    final textColor = isFeatured ? Colors.white70 : (isDark ? Colors.grey[400]! : Colors.grey[600]!);
    final iconColor = isFeatured ? Colors.white : (isDark ? Colors.grey[400]! : Colors.grey[500]!);

    return Row(
      children: [
        _InteractionButton(
          icon: liked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          iconColor: liked ? Colors.redAccent : iconColor,
          label: '${widget.news.likeCount}',
          textColor: textColor,
          onTap: _toggleLike,
        ),
        const SizedBox(width: 16),
        _InteractionButton(
          icon: Icons.share_rounded,
          iconColor: iconColor,
          label: '${widget.news.shareCount}',
          textColor: textColor,
          onTap: _share,
        ),
        const Spacer(),
        if (widget.news.createdAt != null)
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: textColor.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(
                _formatDate(context, widget.news.createdAt!),
                style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? AppLocalizations.of(context)!.justNow : AppLocalizations.of(context)!.minutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? AppLocalizations.of(context)!.oneHourAgo : AppLocalizations.of(context)!.hoursAgo(diff.inHours);
    }
    if (diff.inDays < 7) {
      return diff.inDays == 1 ? AppLocalizations.of(context)!.oneDayAgo : AppLocalizations.of(context)!.daysAgo(diff.inDays);
    }
    // عرض التاريخ الفعلي إذا مر عليه أكثر من أسبوع
    return DateFormat('yyyy/MM/dd', 'en').format(dt);
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  const _InteractionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
