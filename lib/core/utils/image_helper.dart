import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageHelper {
  static const String defaultAvatarPath = 'assets/images/defaults/avatars/default_avatar.png';

  static ImageProvider getProvider(String path) {
    if (path.isEmpty) {
      return const AssetImage(defaultAvatarPath);
    }
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    return CachedNetworkImageProvider(path);
  }
}
