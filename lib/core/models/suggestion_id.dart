// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class SuggestionId {
  final String videoId;
  final String name;
  final DateTime date;

  SuggestionId({required this.videoId, required this.name, required this.date});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'videoId': videoId,
      'name': name,
      'date': date.toIso8601String(),
    };
  }

  factory SuggestionId.fromMap(Map<String, dynamic> map) {
    return SuggestionId(
      videoId: map['videoId'] as String,
      name: map['name'] as String,
      date: DateTime.parse(map['date']),
    );
  }

  String toJson() => json.encode(toMap());

  factory SuggestionId.fromJson(String source) =>
      SuggestionId.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuggestionId && other.videoId == videoId;
  }

  @override
  int get hashCode => videoId.hashCode;
}
