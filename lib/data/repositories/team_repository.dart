import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';

class TeamRepository {
  final FirebaseFirestore _firestore;
  
  TeamRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> createTeam(TeamModel team) async {
    await _firestore.collection('teams').doc(team.id).set(team.toJson());
  }

  Future<TeamModel?> getTeam(String id) async {
    final doc = await _firestore.collection('teams').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return TeamModel.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  Future<List<TeamModel>> getAllTeams() async {
    final snapshot = await _firestore.collection('teams').get();
    return snapshot.docs.map((doc) => TeamModel.fromJson(doc.data(), doc.id)).toList();
  }
}
