import 'package:equatable/equatable.dart';

/// 📝 HINT AR: إحصائيات مسيرة اللاعب — تُكتب من Cloud Functions حصراً (تُجمَّع
/// من أحداث المباريات). لا يعدّلها الكابتن ولا اللاعب (حماية من التلاعب).
class CareerStats extends Equatable {
  final int matches;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final double rating;

  const CareerStats({
    this.matches = 0,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.rating = 0.0,
  });

  factory CareerStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CareerStats();
    return CareerStats(
      matches: json['matches'] ?? 0,
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      yellowCards: json['yellowCards'] ?? 0,
      redCards: json['redCards'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'matches': matches,
        'goals': goals,
        'assists': assists,
        'yellowCards': yellowCards,
        'redCards': redCards,
        'rating': rating,
      };

  @override
  List<Object?> get props =>
      [matches, goals, assists, yellowCards, redCards, rating];
}

/// 📝 HINT AR: سجل اللاعب (الهوية الكروية/البطاقة). يديره الكابتن، وقد يُربط
/// بحساب مستخدم عبر [claimedByUid] (المطالبة برابط دعوة).
class PlayerModel extends Equatable {
  final String id;
  final String name;
  final String? photoUrl;
  final DateTime? birthDate;
  final String position; // حارس / مدافع / خط وسط / مهاجم
  final int? shirtNumber;
  final String? preferredFoot; // right | left | both
  final int? height;
  final int? weight;
  final String? bio; // نبذة شخصية (يكتبها اللاعب صاحب السجل)
  final List<String> gallery; // معرض صور اللاعب (حتى 5) — يديره اللاعب
  final String status; // active | injured | suspended
  final bool isStarter; // أساسي (true) أو احتياط (false) في التشكيلة
  final String currentTeamId;
  final CareerStats careerStats;
  final String? claimedByUid; // حساب اللاعب المرتبط (إن وُجد)
  final String? createdByUid; // الكابتن المنشئ
  final String? teamToken; // 📝 HINT AR: توكن عضوية الفريق الحالي (يُجدَّد عند الانتقال)

  const PlayerModel({
    required this.id,
    required this.name,
    this.photoUrl,
    this.birthDate,
    this.position = 'غير محدد',
    this.shirtNumber,
    this.preferredFoot,
    this.height,
    this.weight,
    this.bio,
    this.gallery = const [],
    this.status = 'active',
    this.isStarter = true,
    required this.currentTeamId,
    this.careerStats = const CareerStats(),
    this.claimedByUid,
    this.createdByUid,
    this.teamToken,
  });

  // 📝 HINT AR: العمر محسوب من تاريخ الميلاد (للعرض في البطاقة).
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    var a = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      a--;
    }
    return a < 0 ? null : a;
  }

  bool get isClaimed => claimedByUid != null && claimedByUid!.isNotEmpty;

  factory PlayerModel.fromJson(Map<String, dynamic> json, String id) {
    return PlayerModel(
      id: id,
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'],
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'].toString())
          : null,
      position: json['position'] ?? 'غير محدد',
      shirtNumber: json['shirtNumber'],
      preferredFoot: json['preferredFoot'],
      height: json['height'],
      weight: json['weight'],
      bio: json['bio'],
      gallery: List<String>.from(json['gallery'] ?? const []),
      status: json['status'] ?? 'active',
      isStarter: json['isStarter'] ?? true,
      currentTeamId: json['currentTeamId'] ?? '',
      careerStats: CareerStats.fromJson(json['careerStats']),
      claimedByUid: json['claimedByUid'],
      createdByUid: json['createdByUid'],
      teamToken: json['teamToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'birthDate': birthDate?.toIso8601String(),
      'position': position,
      'shirtNumber': shirtNumber,
      'preferredFoot': preferredFoot,
      'height': height,
      'weight': weight,
      if (bio != null) 'bio': bio,
      'gallery': gallery,
      'status': status,
      'isStarter': isStarter,
      'currentTeamId': currentTeamId,
      'careerStats': careerStats.toJson(),
      'claimedByUid': claimedByUid,
      'createdByUid': createdByUid,
      if (teamToken != null) 'teamToken': teamToken,
    };
  }

  PlayerModel copyWith({
    String? name,
    String? photoUrl,
    DateTime? birthDate,
    String? position,
    int? shirtNumber,
    String? preferredFoot,
    int? height,
    int? weight,
    String? bio,
    List<String>? gallery,
    String? status,
    bool? isStarter,
    String? currentTeamId,
    CareerStats? careerStats,
    String? claimedByUid,
    String? createdByUid,
    String? teamToken,
  }) {
    return PlayerModel(
      id: id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      birthDate: birthDate ?? this.birthDate,
      position: position ?? this.position,
      shirtNumber: shirtNumber ?? this.shirtNumber,
      preferredFoot: preferredFoot ?? this.preferredFoot,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bio: bio ?? this.bio,
      gallery: gallery ?? this.gallery,
      status: status ?? this.status,
      isStarter: isStarter ?? this.isStarter,
      currentTeamId: currentTeamId ?? this.currentTeamId,
      careerStats: careerStats ?? this.careerStats,
      claimedByUid: claimedByUid ?? this.claimedByUid,
      createdByUid: createdByUid ?? this.createdByUid,
      teamToken: teamToken ?? this.teamToken,
    );
  }

  @override
  List<Object?> get props => [
        id, name, photoUrl, birthDate, position, shirtNumber, preferredFoot,
        height, weight, bio, gallery, status, isStarter, currentTeamId,
        careerStats, claimedByUid, createdByUid, teamToken,
      ];
}
