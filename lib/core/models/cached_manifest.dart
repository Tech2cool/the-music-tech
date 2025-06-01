import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class CachedManifest {
  final StreamManifest manifest;
  final DateTime cacheTime;

  CachedManifest(this.manifest, this.cacheTime);
}
