import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/candidate.dart';
import '../services/storage_service.dart';
import '../widgets/candidate_card.dart';
import '../widgets/leaderboard.dart';
import 'admin_screen.dart';

class VotingScreen extends StatefulWidget {
  final String userName;
  final String userRole;

  const VotingScreen({super.key, required this.userName, required this.userRole});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  final StorageService _storage = StorageService();
  List<Candidate> _candidates = [];
  bool _isLoading = true;
  bool _hasVoted = false;
  int? _userVotedCandidateId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final candidates = await _storage.loadCandidates();
    final votedCandidateId = await _storage.getUserVote(widget.userName);
    if (!mounted) return;
    setState(() {
      _candidates = candidates;
      _userVotedCandidateId = votedCandidateId;
      _hasVoted = votedCandidateId != null;
      _isLoading = false;
    });
  }

  Future<void> _voteCandidate(Candidate candidate) async {
    if (_isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin tidak dapat melakukan voting.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_hasVoted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda sudah memilih, hanya satu suara per user.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    final index = _candidates.indexWhere((c) => c.id == candidate.id);
    if (index != -1) {
      final updatedCandidate = candidate.copyWith(votes: candidate.votes + 1);
      setState(() {
        _candidates[index] = updatedCandidate;
        _userVotedCandidateId = candidate.id;
        _hasVoted = true;
      });
      await _storage.saveCandidates(_candidates);
      await _storage.setUserVote(widget.userName, candidate.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terima kasih! Suara untuk ${candidate.name} tercatat'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  bool get _isAdmin => widget.userRole == 'admin';

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_name');
      await prefs.remove('user_role');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/login',
          arguments: null,
        );
      }
    }
  }

  LinearGradient get _pageGradient => const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF4338CA), Color(0xFF8B5CF6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  LinearGradient get _appBarGradient => const LinearGradient(
        colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('🗳️ E-Voting Dosen Favorit Informatika'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: _appBarGradient)),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                );
                _loadData();
              },
              tooltip: 'Panel Admin',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: _pageGradient),
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${widget.userName}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _isAdmin ? 'Peran Anda: Admin' : 'Peran Anda: Mahasiswa',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isAdmin
                            ? 'Anda dapat mengelola kandidat dan melihat statistik. Voting dinonaktifkan untuk akun admin.'
                            : _hasVoted
                                ? 'Anda sudah memilih satu kandidat. Anda tidak dapat memilih lagi.'
                                : 'Pilih kandidat dan berikan suara Anda dengan aman.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      if (!_isAdmin && _hasVoted)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade800.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            _candidates.firstWhere(
                              (c) => c.id == _userVotedCandidateId,
                              orElse: () => Candidate(id: -1, name: 'Tidak diketahui'),
                            ).name == 'Tidak diketahui'
                                ? 'Suara Anda tercatat.'
                                : 'Anda sudah memilih: ${_candidates.firstWhere((c) => c.id == _userVotedCandidateId).name}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      if (!_isAdmin && _hasVoted) const SizedBox(height: 16),
                      Leaderboard(candidates: _candidates),
                      const SizedBox(height: 24),
                      const Text(
                        'Daftar Kandidat Dosen',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      if (_candidates.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade800.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.white, size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum Ada Kandidat',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isAdmin
                                    ? 'Silakan tambahkan nama kandidat terlebih dahulu di panel admin.'
                                    : 'Tunggu admin menambahkan daftar kandidat terlebih dahulu.',
                                style: const TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                              if (_isAdmin)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Ke Panel Admin'),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const AdminScreen()),
                                      );
                                      _loadData();
                                    },
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _candidates.length,
                          itemBuilder: (context, index) {
                            final candidate = _candidates[index];
                            final isSelected = _userVotedCandidateId == candidate.id;
                            final canVote = !_isAdmin && !_hasVoted;
                            return CandidateCard(
                              candidate: candidate,
                              enabled: canVote,
                              isSelected: isSelected,
                              onVote: canVote
                                  ? () => _voteCandidate(candidate)
                                  : () {
                                      if (_isAdmin) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Admin tidak dapat melakukan voting.'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}