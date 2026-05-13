class Candidate {
  final int id;
  final String name;
  int votes;
  final String imageUrl;

  Candidate({
    required this.id,
    required this.name,
    this.votes = 0,
    this.imageUrl = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'votes': votes,
    'imageUrl': imageUrl,
  };

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'] as int,
      name: json['name'] as String,
      votes: json['votes'] is int
          ? json['votes'] as int
          : int.tryParse('${json['votes']}') ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Candidate copyWith({String? name, int? votes, String? imageUrl}) {
    return Candidate(
      id: id,
      name: name ?? this.name,
      votes: votes ?? this.votes,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}