// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class AppUpdate {
  final String? description;
  final String? version;
  final String? downloadLink;

  AppUpdate({
    required this.description,
    required this.version,
    required this.downloadLink,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'description': description,
      'version': version,
      'downloadLink': downloadLink,
    };
  }

  factory AppUpdate.fromMap(Map<String, dynamic> map) {
    return AppUpdate(
      description:
          map['description'] != null ? map['description'] as String : null,
      version: map['version'] != null ? map['version'] as String : null,
      downloadLink:
          map['downloadLink'] != null ? map['downloadLink'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppUpdate.fromJson(String source) =>
      AppUpdate.fromMap(json.decode(source) as Map<String, dynamic>);
}
