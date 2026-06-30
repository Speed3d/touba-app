import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../../data/models/news_model.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../core/utils/tooba_snack_bar.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsModel news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late NewsModel _news;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _news = widget.news;
  }

  Future<void> _toggleLike() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      ToobaSnackBar.info(context, 'سجّل الدخول لتتمكن من الإعجاب');
      return;
    }
    if (_busy) return;
    
    final uid = authState.user.id;
    final liked = _news.likedBy(uid);
    
    setState(() {
      _busy = true;
      final newLikes = List<String>.from(_news.likes);
      if (liked) {
        newLikes.remove(uid);
      } else {
        newLikes.add(uid);
      }
      _news = _news.copyWith(likes: newLikes);
    });
    
    try {
      await context.read<HomeRepository>().toggleLike(_news.id, uid, !liked);
    } catch (_) {
      if (!mounted) return;
      ToobaSnackBar.error(context, 'حدث خطأ أثناء الإعجاب');
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
    final text = '📰 ${_news.title}\n\n${_news.body}\n\n📲 عبر تطبيق طوبة للمحترفين';
    try {
      await Share.share(text);
      await repo.incrementShare(_news.id);
      if (mounted) {
        setState(() {
          _news = _news.copyWith(shareCount: _news.shareCount + 1);
        });
      }
    } catch (_) {}
  }

  String _formatDate(DateTime dt) {
    return DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final uid = (context.read<AuthCubit>().state is AuthAuthenticated)
        ? (context.read<AuthCubit>().state as AuthAuthenticated).user.id
        : null;
    final liked = _news.likedBy(uid);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            stretch: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_news.imageUrl != null && _news.imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: _news.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: isDark ? Colors.grey[800] : Colors.grey.shade300),
                      errorWidget: (c, u, e) => Container(color: isDark ? Colors.grey[800] : Colors.grey.shade300),
                    )
                  else
                    Container(color: theme.primaryColor, child: const Icon(Icons.newspaper, size: 80, color: Colors.white54)),
                  
                  // تدرج لوني لتوضيح أيقونة الرجوع والنص
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                          theme.scaffoldBackgroundColor,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_news.createdAt != null)
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(_news.createdAt!),
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _news.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // شريط التفاعل
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionBtn(
                          icon: liked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          color: liked ? Colors.redAccent : (isDark ? Colors.grey[300]! : Colors.grey[700]!),
                          label: 'إعجاب (${_news.likeCount})',
                          onTap: _toggleLike,
                        ),
                        Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                        _buildActionBtn(
                          icon: Icons.share_rounded,
                          color: isDark ? Colors.grey[300]! : Colors.grey[700]!,
                          label: 'مشاركة (${_news.shareCount})',
                          onTap: _share,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    _news.body,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 60), // Space at bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
