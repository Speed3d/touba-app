import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament_model.dart';

class TournamentRepository {
  final FirebaseFirestore _firestore;
  
  TournamentRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createTournament(TournamentModel tournament) async {
    await _firestore.collection('tournaments').doc(tournament.id).set(tournament.toJson());
  }

  Future<List<TournamentModel>> getAllTournaments() async {
    final snapshot = await _firestore.collection('tournaments').get();
    return snapshot.docs.map((doc) => TournamentModel.fromJson(doc.data(), doc.id)).toList();
  }
}
