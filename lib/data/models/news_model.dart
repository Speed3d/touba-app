import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 📝 HINT AR: خبر يُنشر في الرئيسية (صورة + عنوان + مقال). يكتبه الأدمن.
/// أي مستخدم (لاعب/كابتن/زائر مسجّل) يستطيع الإعجاب والمشاركة.
/// `likes` قائمة UIDs (تجميع مسبق لعدد الإعجابات بطولها). `shareCount` عدّاد.
class NewsModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final List<String> likes;
  final int shareCount;
  final bool isPublished;
  final DateTime? createdAt;

  const NewsModel({
    required this.id,
    required this.title,
    this.body = '',
    this.imageUrl,
    this.likes = const [],
    this.shareCount = 0,
    this.isPublished = true,
    this.createdAt,
  });

  int get likeCount => likes.length;
  bool likedBy(String? uid) => uid != null && likes.contains(uid);

  factory NewsModel.fromJson(Map<String, dynamic> json, String id) {
    return NewsModel(
      id: id,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imageUrl: json['imageUrl'],
      likes: List<String>.from(json['likes'] ?? const []),
      shareCount: json['shareCount'] ?? 0,
      isPublished: json['isPublished'] ?? true,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'likes': likes,
        'shareCount': shareCount,
        'isPublished': isPublished,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };

  NewsModel copyWith({
    String? title,
    String? body,
    String? imageUrl,
    List<String>? likes,
    int? shareCount,
    bool? isPublished,
  }) {
    return NewsModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      likes: likes ?? this.likes,
      shareCount: shareCount ?? this.shareCount,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, body, imageUrl, likes, shareCount, isPublished, createdAt];
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
