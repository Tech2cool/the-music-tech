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
      description: map['desc'] != null ? map['desc'] as String : null,
      version: map['app_version'] != null ? map['app_version'] as String : null,
      downloadLink: map['app_url'] != null ? map['app_url'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppUpdate.fromJson(String source) =>
      AppUpdate.fromMap(json.decode(source) as Map<String, dynamic>);
}
