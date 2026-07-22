import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/banner_model.dart';
import '../../../core/utils/tooba_snack_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: تفاصيل الإعلان — صورة رئيسية + صور إضافية + عنوان/منطقة/محافظة
/// + وصف + روابط تواصل (هاتف/واتساب/فيسبوك/إنستغرام).
class BannerDetailsScreen extends StatelessWidget {
  final BannerModel banner;
  const BannerDetailsScreen({super.key, required this.banner});

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ToobaSnackBar.error(context, AppLocalizations.of(context)!.errorOpeningLink);
      }
    } catch (_) {
      if (context.mounted) ToobaSnackBar.error(context, AppLocalizations.of(context)!.errorOpeningLink);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = [banner.imageUrl, ...banner.extraImages]
        .where((e) => e.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(banner.title ?? AppLocalizations.of(context)!.bannerDetails),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // الصورة الرئيسية + الإضافية (تمرير أفقي).
          SizedBox(
            height: 220,
            child: PageView(
              children: images
                  .map((url) => CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (c, u) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (c, u, e) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (banner.title != null && banner.title!.isNotEmpty)
                  Text(banner.title!,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                if ((banner.city != null && banner.city!.isNotEmpty) ||
                    (banner.area != null && banner.area!.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        [banner.city, banner.area]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' • '),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
                if (banner.description != null &&
                    banner.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(banner.description!,
                      style: const TextStyle(fontSize: 14, height: 1.6)),
                ],
                const SizedBox(height: 20),
                // روابط التواصل.
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (banner.phone != null && banner.phone!.isNotEmpty)
                      _contactBtn(context, Icons.phone, AppLocalizations.of(context)!.contactCall,
                          Colors.green, 'tel:${banner.phone}'),
                    if (banner.whatsapp != null &&
                        banner.whatsapp!.isNotEmpty)
                      _contactBtn(
                          context,
                          Icons.chat,
                          AppLocalizations.of(context)!.contactWhatsapp,
                          Colors.teal,
                          'https://wa.me/${banner.whatsapp!.replaceAll('+', '')}'),
                    if (banner.facebook != null &&
                        banner.facebook!.isNotEmpty)
                      _contactBtn(context, Icons.facebook, AppLocalizations.of(context)!.contactFacebook,
                          Colors.blue, banner.facebook!),
                    if (banner.instagram != null &&
                        banner.instagram!.isNotEmpty)
                      _contactBtn(context, Icons.camera_alt, AppLocalizations.of(context)!.contactInstagram,
                          Colors.purple, banner.instagram!),
                    if (banner.targetUrl != null &&
                        banner.targetUrl!.isNotEmpty)
                      _contactBtn(context, Icons.link, AppLocalizations.of(context)!.contactWebsite,
                          Colors.indigo, banner.targetUrl!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactBtn(BuildContext context, IconData icon, String label,
      Color color, String url) {
    return ElevatedButton.icon(
      onPressed: () => _open(context, url),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
