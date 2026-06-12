import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_model.dart';

class PlayerRepository {
  final FirebaseFirestore _firestore;
  
  PlayerRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createPlayer(PlayerModel player) async {
    await _firestore.collection('players').doc(player.id).set(player.toJson());
  }

  Future<List<PlayerModel>> getPlayersByTeam(String teamId) async {
    final snapshot = await _firestore.collection('players').where('currentTeamId', isEqualTo: teamId).get();
    return snapshot.docs.map((doc) => PlayerModel.fromJson(doc.data(), doc.id)).toList();
  }
}
