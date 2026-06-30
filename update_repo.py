import re

with open('lib/data/repositories/home_repository.dart', 'r') as f:
    c = f.read()

# Add getPublishedNewsStream
if "getPublishedNewsStream" not in c:
    new_method = """
  // 📝 HINT AR: جلب الأخبار كـ Stream لتحديث شريط الأخبار المتحرك تلقائياً
  Stream<List<NewsModel>> getPublishedNewsStream({int limit = 10}) {
    return _firestore
        .collection('news')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => NewsModel.fromJson(d.data(), d.id)).toList());
  }
"""
    c = c.replace("Future<List<NewsModel>> getPublishedNews({int limit = 20}) async {", new_method + "\n  Future<List<NewsModel>> getPublishedNews({int limit = 20}) async {")

with open('lib/data/repositories/home_repository.dart', 'w') as f:
    f.write(c)

