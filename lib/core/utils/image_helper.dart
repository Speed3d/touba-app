import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageHelper {
  static ImageProvider getProvider(String path) {
    if (path.isEmpty) {
      return const AssetImage('assets/images/defaults/avatars/craftsman_108.png');
    }
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    return CachedNetworkImageProvider(path);
  }
}
