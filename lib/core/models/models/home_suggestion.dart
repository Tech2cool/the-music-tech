import 'dart:convert';
import 'package:the_music_tech/core/models/models/search_model.dart';

class HomeSuggestion {
  final String? title;
  final List<SearchModel> contents;

  HomeSuggestion({this.title, this.contents = const []});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'contents': contents.map((x) => x.toMap()).toList(),
    };
  }

  factory HomeSuggestion.fromMap(Map<String, dynamic> map) {
    return HomeSuggestion(
      title: map['title'] != null ? map['title'] as String : null,
      contents: map['contents'] != null
          ? List<SearchModel>.from(
              (map['contents'] as List<dynamic>).map<SearchModel>(
                (x) => SearchModel.fromMap(x),
              ),
            )
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory HomeSuggestion.fromJson(String source) =>
      HomeSuggestion.fromMap(json.decode(source) as Map<String, dynamic>);
}
