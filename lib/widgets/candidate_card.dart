import 'dart:io';

import 'package:flutter/material.dart';
import '../models/candidate.dart';

class CandidateCard extends StatelessWidget {
  final Candidate candidate;
  final VoidCallback onVote;
  final bool enabled;
  final bool isSelected;

  const CandidateCard({
    super.key,
    required this.candidate,
    required this.onVote,
    this.enabled = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple.shade50,
              ),
              child: ClipOval(
                child: candidate.imageUrl.isNotEmpty
                    ? (candidate.imageUrl.startsWith('http')
                        ? Image.network(
                            candidate.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            },
                          )
                        : Image.file(
                            File(candidate.imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                          ))
                    : Center(
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              candidate.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${candidate.votes} suara',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: enabled ? onVote : null,
              icon: const Icon(Icons.thumb_up),
              label: Text(isSelected ? 'SUDAH DIPILIH' : 'VOTE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled ? const Color(0xFF5B21B6) : Colors.grey.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pilihan Anda',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}