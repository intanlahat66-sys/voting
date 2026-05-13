import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/candidate.dart';

class StorageService {
  static const String _candidatesKey = 'candidates';
  static const String _userVotesKey = 'user_votes';

  Future<void> saveCandidates(List<Candidate> candidates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> candidatesMap = candidates.map((c) => c.toJson()).toList();
      final String jsonString = jsonEncode(candidatesMap);
      await prefs.setString(_candidatesKey, jsonString);
    } catch (e) {
      print('Error saving candidates: $e');
      rethrow;
    }
  }

  Future<List<Candidate>> loadCandidates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_candidatesKey);
      
      if (jsonString == null) {
        // Data default
        return _getDefaultCandidates();
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      // Validasi data
      if (jsonList.isEmpty) {
        return _getDefaultCandidates();
      }
      
      return jsonList.map((json) {
        // Validasi setiap item memiliki field yang diperlukan
        if (json['id'] == null || json['name'] == null) {
          throw Exception('Invalid candidate data');
        }
        return Candidate.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error loading candidates: $e');
      // Return default data if error occurs
      return _getDefaultCandidates();
    }
  }

  Future<void> resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Hapus data yang ada
      await prefs.remove(_candidatesKey);
      // Simpan data default
      final defaultCandidates = _getDefaultCandidates();
      await saveCandidates(defaultCandidates);
    } catch (e) {
      print('Error resetting all data: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> _loadUserVoteMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userVotesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) => MapEntry(key, value is int ? value : int.tryParse('$value') ?? 0));
    } catch (e) {
      print('Error loading user votes: $e');
      return {};
    }
  }

  Future<void> _saveUserVoteMap(Map<String, int> voteMap) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userVotesKey, jsonEncode(voteMap));
    } catch (e) {
      print('Error saving user votes: $e');
      rethrow;
    }
  }

  Future<void> setUserVote(String userName, int candidateId) async {
    try {
      final voteMap = await _loadUserVoteMap();
      voteMap[userName] = candidateId;
      await _saveUserVoteMap(voteMap);
    } catch (e) {
      print('Error setting user vote: $e');
      rethrow;
    }
  }

  Future<int?> getUserVote(String userName) async {
    try {
      final voteMap = await _loadUserVoteMap();
      return voteMap[userName];
    } catch (e) {
      print('Error getting user vote: $e');
      return null;
    }
  }

  Future<bool> hasUserVoted(String userName) async {
    return await getUserVote(userName) != null;
  }

  Future<void> resetVotesOnly() async {
    try {
      final candidates = await loadCandidates();
      // Reset votes ke 0 untuk semua kandidat
      final resetCandidates = candidates.map((c) => 
        Candidate(id: c.id, name: c.name, votes: 0)
      ).toList();
      await saveCandidates(resetCandidates);
    } catch (e) {
      print('Error resetting votes: $e');
      rethrow;
    }
  }

  Future<void> addCandidate(String name) async {
    try {
      final candidates = await loadCandidates();
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newCandidate = Candidate(id: newId, name: name, votes: 0);
      candidates.add(newCandidate);
      await saveCandidates(candidates);
    } catch (e) {
      print('Error adding candidate: $e');
      rethrow;
    }
  }

  Future<void> deleteCandidate(int id) async {
    try {
      final candidates = await loadCandidates();
      candidates.removeWhere((c) => c.id == id);
      await saveCandidates(candidates);
    } catch (e) {
      print('Error deleting candidate: $e');
      rethrow;
    }
  }

  Future<void> voteCandidate(int id) async {
    try {
      final candidates = await loadCandidates();
      final index = candidates.indexWhere((c) => c.id == id);
      if (index != -1) {
        final updatedCandidate = Candidate(
          id: candidates[index].id,
          name: candidates[index].name,
          votes: candidates[index].votes + 1,
        );
        candidates[index] = updatedCandidate;
        await saveCandidates(candidates);
      }
    } catch (e) {
      print('Error voting candidate: $e');
      rethrow;
    }
  }

  Future<Candidate?> getCandidate(int id) async {
    try {
      final candidates = await loadCandidates();
      return candidates.firstWhere((c) => c.id == id);
    } catch (e) {
      print('Error getting candidate: $e');
      return null;
    }
  }

  Future<int> getTotalVotes() async {
    try {
      final candidates = await loadCandidates();
      return candidates.fold<int>(0, (int sum, Candidate c) => sum + c.votes);
    } catch (e) {
      print('Error getting total votes: $e');
      return 0;
    }
  }

  Future<bool> hasData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_candidatesKey);
    } catch (e) {
      print('Error checking data existence: $e');
      return false;
    }
  }

  // Helper method untuk mendapatkan data default
  List<Candidate> _getDefaultCandidates() {
    return []; // Tidak ada kandidat default, harus diinput oleh admin terlebih dahulu
  }
}