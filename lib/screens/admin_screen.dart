import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/candidate.dart';
import '../services/storage_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final StorageService _storage = StorageService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  String? _selectedImagePath;
  List<Candidate> _candidates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<String?> _saveImageToLocalDirectory(String sourcePath) async {
    try {
      final original = File(sourcePath);
      if (!await original.exists()) return null;
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${sourcePath.split(Platform.pathSeparator).last}';
      final savedFile = await original.copy('${directory.path}/$fileName');
      return savedFile.path;
    } catch (e) {
      print('Error saving image locally: $e');
      return null;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final candidates = await _storage.loadCandidates();
    if (!mounted) return;
    setState(() {
      _candidates = candidates;
      _isLoading = false;
    });
  }

  Future<void> _addCandidate() async {
    final name = _nameController.text.trim();
    final imageUrl = _selectedImagePath ?? _imageController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dosen tidak boleh kosong!')),
      );
      return;
    }

    final newCandidate = Candidate(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      imageUrl: imageUrl,
    );
    setState(() {
      _candidates.add(newCandidate);
      _selectedImagePath = null;
    });
    await _storage.saveCandidates(_candidates);
    if (!mounted) return;
    _nameController.clear();
    _imageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ $name berhasil ditambahkan')),
    );
  }

  Future<void> _editCandidate(Candidate candidate) async {
    final nameController = TextEditingController(text: candidate.name);
    final imageController = TextEditingController(text: candidate.imageUrl);
    final updatedCandidate = await showDialog<Candidate>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Kandidat'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kandidat',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar atau path lokal',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pilih Foto dari Galeri'),
                        onPressed: () async {
                          final picked = await _picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 1024,
                            maxHeight: 1024,
                          );
                          if (picked != null) {
                            imageController.text = picked.path;
                            setStateDialog(() {});
                          }
                        },
                      ),
                    ),
                    if (imageController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _buildImagePreview(imageController.text),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final imageUrl = imageController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama kandidat tidak boleh kosong')),
                      );
                      return;
                    }
                    Navigator.pop(
                      context,
                      candidate.copyWith(name: name, imageUrl: imageUrl),
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    imageController.dispose();

    if (updatedCandidate != null) {
      setState(() {
        final index = _candidates.indexWhere((c) => c.id == candidate.id);
        if (index != -1) {
          _candidates[index] = updatedCandidate;
        }
      });
      await _storage.saveCandidates(_candidates);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Data kandidat berhasil diperbarui')),
      );
    }
  }

  Future<void> _changeCandidatePhoto(Candidate candidate) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked != null) {
      final savedPath = await _saveImageToLocalDirectory(picked.path) ?? picked.path;
      setState(() {
        final index = _candidates.indexWhere((c) => c.id == candidate.id);
        if (index != -1) {
          _candidates[index] = _candidates[index].copyWith(imageUrl: savedPath);
        }
      });
      await _storage.saveCandidates(_candidates);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Foto ${candidate.name} berhasil diubah')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked != null) {
      final savedPath = await _saveImageToLocalDirectory(picked.path) ?? picked.path;
      setState(() {
        _selectedImagePath = savedPath;
        _imageController.text = savedPath;
      });
    }
  }

  Future<void> _deleteCandidate(int id) async {
    final candidate = _candidates.firstWhere((c) => c.id == id);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kandidat'),
        content: Text('Hapus ${candidate.name} dari daftar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _candidates.removeWhere((c) => c.id == id);
      });
      await _storage.saveCandidates(_candidates);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ ${candidate.name} dihapus')),
      );
    }
  }

  Future<void> _resetVotesOnly() async {
    final confirm = await _showConfirmDialog('Reset Suara', 'Reset semua suara ke 0?');
    if (confirm == true) {
      setState(() {
        _candidates = _candidates.map((c) => c.copyWith(votes: 0)).toList();
      });
      await _storage.saveCandidates(_candidates);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua suara telah direset')),
      );
    }
  }

  Future<void> _resetAllData() async {
    final confirm = await _showConfirmDialog(
      'Reset Semua Data',
      'Hapus semua kandidat dan suara? Tindakan ini tidak bisa dibatalkan!',
    );
    if (confirm == true) {
      await _storage.resetAllData();
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua data telah direset ke default')),
      );
    }
  }

  bool _isValidImagePath(String imagePath) {
    if (imagePath.isEmpty) return false;
    if (imagePath.startsWith('http')) return true;
    try {
      return File(imagePath).existsSync();
    } catch (_) {
      return false;
    }
  }

  Widget _buildImagePreview(String imagePath) {
    if (!_isValidImagePath(imagePath)) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
          color: Colors.white10,
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 40, color: Colors.white70),
        ),
      );
    }

    final imageProvider = imagePath.startsWith('http')
        ? NetworkImage(imagePath)
        : FileImage(File(imagePath)) as ImageProvider;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image(
          image: imageProvider,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image, size: 40, color: Colors.white70),
          ),
        ),
      ),
    );
  }

  int get _totalVotes => _candidates.fold<int>(0, (sum, candidate) => sum + candidate.votes);

  Candidate? get _winnerCandidate {
    if (_candidates.isEmpty) return null;
    Candidate winner = _candidates.first;
    for (final candidate in _candidates) {
      if (candidate.votes > winner.votes) {
        winner = candidate;
      }
    }
    return winner.votes > 0 ? winner : null;
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  LinearGradient get _pageGradient => const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF4338CA), Color(0xFF8B5CF6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('🔧 Admin Panel'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: _pageGradient),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: _pageGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tambah Kandidat Dosen',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan nama dosen',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _imageController,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan URL gambar atau path lokal',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Pilih Foto'),
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedImagePath != null || _imageController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _buildImagePreview(_imageController.text),
                              ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _addCandidate,
                                icon: const Icon(Icons.add),
                                label: const Text('Tambah Kandidat'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daftar Kandidat Saat Ini',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            if (_candidates.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.blue.shade300),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_add_alt_1, color: Colors.blue, size: 40),
                                    SizedBox(height: 12),
                                    Text(
                                      'Belum Ada Kandidat',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tambahkan nama dosen di atas untuk memulai voting.',
                                      style: TextStyle(color: Colors.blue),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _candidates.length,
                                itemBuilder: (context, index) {
                                  final candidate = _candidates[index];
                                  final ImageProvider? avatarImage = candidate.imageUrl.isNotEmpty
                                      ? (candidate.imageUrl.startsWith('http')
                                          ? NetworkImage(candidate.imageUrl)
                                          : FileImage(File(candidate.imageUrl)) as ImageProvider)
                                      : null;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.indigo.shade50,
                                      backgroundImage: avatarImage,
                                      child: avatarImage == null ? Text('${candidate.votes}') : null,
                                    ),
                                    title: Text(candidate.name),
                                    subtitle: candidate.imageUrl.isNotEmpty ? const Text('Gambar sudah diatur') : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.photo_camera, color: Colors.deepPurple),
                                          tooltip: 'Ubah foto',
                                          onPressed: () => _changeCandidatePhoto(candidate),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _editCandidate(candidate),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteCandidate(candidate.id),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rekap Suara',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade900,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Total Suara',
                                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$_totalVotes',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('Suara masuk', style: TextStyle(color: Colors.white60)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Pemenang', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              _winnerCandidate == null ? 'Belum ada' : _winnerCandidate!.name,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _winnerCandidate == null ? '-' : '${_winnerCandidate!.votes} suara',
                                              style: const TextStyle(color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text('Detail Suara per Kandidat', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Column(
                              children: _candidates
                                  .map(
                                    (candidate) {
                                      final voteFraction = _totalVotes > 0 ? candidate.votes / _totalVotes : 0.0;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(child: Text(candidate.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                                Text('${candidate.votes} suara', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: LinearProgressIndicator(
                                                value: voteFraction,
                                                minHeight: 10,
                                                backgroundColor: Colors.white10,
                                                valueColor: AlwaysStoppedAnimation<Color>(candidate == _winnerCandidate ? Colors.greenAccent : Colors.deepPurpleAccent),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚠️ Reset Data',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _resetVotesOnly,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Reset Suara Saja'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _resetAllData,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Reset Semua Data'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        label: const Text('Kembali ke Halaman Voting', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
