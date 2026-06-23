import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/news_model.dart';
import '../../../data/repositories/home_repository.dart';
import '../../widgets/core/tooba_shimmer.dart';
import '../../../core/utils/tooba_snack_bar.dart';

/// 📝 HINT AR: شاشة الأخبار — تُفتح من «كارت الأخبار» في الرئيسية. تعرض الأخبار
/// المنشورة بنفس الصيغة (صورة + عنوان + تفاصيل + إعجاب + مشاركة + مدّة النشر).
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<NewsModel>> _news;

  @override
  void initState() {
    super.initState();
    _news = context.read<HomeRepository>().getPublishedNews();
  }

  Future<void> _reload() async {
    setState(() {
      _news = context.read<HomeRepository>().getPublishedNews();
    });
    await _news;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('الأخبار'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<NewsModel>>(
          future: _news,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const ToobaShimmerList(count: 4, tileHeight: 200);
            }
            final news = snap.data ?? [];
            if (news.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.newspaper_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('لا توجد أخبار حالياً',
                        style: TextStyle(color: Colors.grey[600])),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: news
                  .map((n) =>
                      _NewsCard(news: n, onChanged: () => setState(() {})))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

/// 📝 HINT AR: بطاقة خبر — صورة + عنوان + مقال + إعجاب (متفائل) + مشاركة.
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
    setState(() {
      _busy = true;
      final newLikes = List<String>.from(_news.likes);
      liked ? newLikes.remove(uid) : newLikes.add(uid);
      _news = _news.copyWith(likes: newLikes);
    });
    try {
      await context.read<HomeRepository>().toggleLike(_news.id, uid, !liked);
    } catch (_) {
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
        setState(
            () => _news = _news.copyWith(shareCount: _news.shareCount + 1));
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
                placeholder: (c, u) =>
                    Container(height: 180, color: Colors.grey.shade200),
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
