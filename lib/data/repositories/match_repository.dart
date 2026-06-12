import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';

class MatchRepository {
  final FirebaseFirestore _firestore;
  
  MatchRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createMatch(MatchModel match) async {
    await _firestore.collection('matches').doc(match.id).set(match.toJson());
  }

  Future<List<MatchModel>> getMatchesByTournament(String tournamentId) async {
    final snapshot = await _firestore.collection('matches').where('tournamentId', isEqualTo: tournamentId).get();
    return snapshot.docs.map((doc) => MatchModel.fromJson(doc.data(), doc.id)).toList();
  }
  
  Future<void> updateMatchResult(String matchId, int homeScore, int awayScore) async {
    await _firestore.collection('matches').doc(matchId).update({
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': 'finished',
      'resultConfirmed': true,
    });
  }
}
