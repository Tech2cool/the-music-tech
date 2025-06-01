import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:the_music_tech/core/models/app_update.dart';
import 'package:the_music_tech/core/models/cached_manifest.dart';
import 'package:the_music_tech/core/models/models/home_suggestion.dart';
import 'package:the_music_tech/core/models/models/search_model.dart';
import 'package:the_music_tech/core/services/api_service.dart';
import 'package:the_music_tech/core/services/audio_player_handler.dart';
import 'package:the_music_tech/core/services/shared_pref_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MyProvider with ChangeNotifier {
  late final AudioPlayerHandler _audioHandler;
  bool isLoading = false;
  final ApiService apiService = ApiService();
  final YoutubeExplode youtubeExp = YoutubeExplode();

  int currentIndex = 0;
  SearchModel? currentAlbum;
  SearchModel? currentArtist;
  SearchModel? currentPlayList;
  SearchModel? currentMedia;

  AudioPlayerHandler get audioHandler => _audioHandler;
  MediaItem? _currentMusic;

  MediaItem? get currentMusic => _currentMusic;
  set currentMusic(MediaItem? item) {
    _currentMusic = item;
    notifyListeners();
  }

  // SearchModel? get currentMedia => _currentMedia;
  // SearchModel? get currentAlbum => _currentAlbum;
  // SearchModel? get currentArtist => _currentArtist;
  // SearchModel? get currentPlayList => _currentPlayList;

  List<SearchModel> playlist = [];
  List<SearchModel> albumList = [];
  List<SearchModel> searchResult = [];
  List<SearchModel> myPlayList = [];
  List<SearchModel> history = [];
  List<HomeSuggestion> homeResults = [];
  final Map<String, CachedManifest> _manifestCache = {};
  final Duration cacheDuration = Duration(minutes: 45);
  AppUpdate? appUpdate;

  // init services
  Future<void> init(MyProvider provider) async {
    _audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.app.channel.audio',
        androidNotificationChannelName: 'Audio Playback',
        androidNotificationOngoing: true,
      ),
    );
    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        _currentMusic = mediaItem;
      }
      notifyUser();
    });
  }

  // calls
  Stream<Duration> get positionStream => _audioHandler.player.positionStream;
  Stream<Duration?> get durationStream => _audioHandler.player.durationStream;

  //api calls
  Future<void> searchMusic(String query, String selectedFilter) async {
    final results = await apiService.searchSongs(query, selectedFilter);
    searchResult = results;
    notifyListeners();
  }

  // home suggestions
  Future<void> getHomeSuggestion() async {
    final results = await apiService.getHomeData();
    homeResults = results;
    notifyListeners();
  }

  void updateMyList(List<SearchModel> list) async {
    myPlayList = list;
    notifyListeners();
  }

  Future<void> addToHistory([SearchModel? song]) async {
    final foundList = await SharedPrefService.getJsonArray('history');
    if (foundList != null) {
      final list = foundList.map((ele) => SearchModel.fromMap(ele)).toList();
      history = list;
    }
    if (song != null) {
      history.add(song);
    }
    final savedList = history.map((ele) => ele.toMap()).toList();

    await SharedPrefService.storeJsonArray(
      "history",
      savedList,
    );

    notifyListeners();
  }

  Future<List<SearchModel>> getMyHistory() async {
    final foundList = await SharedPrefService.getJsonArray('history');
    if (foundList != null) {
      final list = foundList.map((ele) => SearchModel.fromMap(ele)).toList();
      history = list;
    }
    notifyListeners();
    return history;
  }

  Future<List<SearchModel>> getMyPlayList() async {
    final foundList = await SharedPrefService.getJsonArray('play_list');
    if (foundList != null) {
      final list = foundList.map((ele) => SearchModel.fromMap(ele)).toList();
      myPlayList = list;
    }
    notifyListeners();
    return myPlayList;
  }

  Future<void> getPlayListByid(SearchModel music) async {
    final resp = await apiService.getPlayListById(music.playlistId!);
    playlist = resp;
    // _currentArtist = music;
    notifyListeners();
  }

  Future<void> getArtistByid(SearchModel music) async {
    final resp = await apiService.getArtistById(music.artistId!);
    // _currentArtistInfo = resp;
    currentArtist = resp;
    notifyListeners();
  }

  Future<void> getAlbumById(SearchModel music) async {
    final resp = await apiService.getAlbumById(music.albumId!);
    // _currentAlbumInfo = resp;
    currentAlbum = resp;
    notifyListeners();
  }

  //reset values
  void resetSearch() {
    searchResult = [];
    notifyListeners();
  }

  void notifyUser() {
    Future.microtask(() => notifyListeners());
  }

  // yt calls
  Future<void> playAudioFromYouTube(String videoId, SearchModel music) async {
    try {
      isLoading = true;
      Future.microtask(() => notifyListeners());

      StreamManifest? manifest;
      // Check cache first
      try {
        await addToHistory(music);
      } catch (e) {
        //
      }

      final cached = _manifestCache[videoId];
      final now = DateTime.now();
      if (cached != null && now.difference(cached.cacheTime) < cacheDuration) {
        manifest = cached.manifest;
        // print('Using cached manifest for $videoId');
      } else {
        try {
          manifest = await youtubeExp.videos.streamsClient.getManifest(videoId);
        } catch (e) {
          // print(e);
        }
      }
      if (manifest != null) {
        var audioStreamInfo = manifest.audioOnly.first;
        _manifestCache[videoId] = CachedManifest(manifest, now);
        // print('Cached manifest for $videoId at $now');

        var img = music.thumbnails.isNotEmpty ? music.thumbnails[0].url : null;

        final src = AudioSource.uri(
          audioStreamInfo.url,
          tag: MediaItem(
            id: videoId,
            title: music.name ?? "NA",
            artist: music.artist?.name ?? 'Unknown Artist',
            artUri: img != null ? Uri.parse(img) : null,
            album: music.album?.name ?? 'Unknown Album',
          ),
        );
        isLoading = false;
        Future.microtask(() => notifyListeners());

        await audioHandler.loadPlaylist([src]);
        // notifyListeners();
        try {
          // await audioHandler.player.play();
          loadPlayListInBackground();
        } catch (e) {
          //
          isLoading = false;

          // print(e);
        }
      } else {
        final nextSong = playlist[currentIndex + 1];
        currentIndex += 1;
        currentMedia = nextSong;
        Future.microtask(() => notifyListeners());
        await playAudioFromYouTube(nextSong.videoId!, nextSong);
      }
    } catch (e) {
      // Helper.showCustomSnackBar("Error Loading Music");
    } finally {
      //
    }
    isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  Future<void> loadPlayListInBackground() async {
    // print("pass 0");

    if (playlist.isEmpty) {
      return;
    }
    // print("pass 1");
    try {
      final filtedList = playlist
          .where((ele) => ele.videoId != currentMedia?.videoId)
          .toList();
      Set<SearchModel> uniqueSongs = Set<SearchModel>.from(history);
      uniqueSongs.addAll(filtedList);
      history = uniqueSongs.toList();
      try {
        await addToHistory();
      } catch (e) {
        //
      }
      for (var pl in filtedList) {
        // final foundInList = audioHandler.playlist.firstWhereOrNull(
        //   (ele) =>
        //       ((ele as ProgressiveAudioSource).tag as MediaItem).id ==
        //       pl.videoId,
        // );
        // if (foundInList != null) {
        //   return;
        // }
        // print("pass 2");
        StreamManifest? manifest;
        final cached = _manifestCache[pl.videoId];
        final now = DateTime.now();
        if (cached != null &&
            now.difference(cached.cacheTime) < cacheDuration) {
          manifest = cached.manifest;
          // print('Using cached manifest for ${pl.videoId}');
        } else {
          //
          try {
            manifest = await youtubeExp.videos.streamsClient.getManifest(
              pl.videoId ?? "",
            );
          } catch (e) {
            // print(e);
          }
        }
        if (manifest != null) {
          var audioStreamInfo = manifest.audioOnly.first;
          _manifestCache[pl.videoId ?? ""] = CachedManifest(manifest, now);
          // print('Cached manifest for ${pl.videoId ?? ""} at $now');

          // var audioStreamInfo = manifest.audioOnly.withHighestBitrate();
          var img = pl.thumbnails.isNotEmpty ? pl.thumbnails[0].url : null;

          final src = AudioSource.uri(
            audioStreamInfo.url,
            tag: MediaItem(
              id: pl.videoId!,
              title: pl.name ?? "NA",
              artist: pl.artist?.name ?? 'Unknown Artist',
              artUri: img != null ? Uri.parse(img) : null,
              album: pl.album?.name ?? 'Unknown Album',
            ),
          );
          await audioHandler.addToPlaylist(src);
          // print("${pl.videoId} added to play list");
        }
      }
    } catch (e) {
      // print(e);

      // Helper.showCustomSnackBar("Error Loading Music");
    } finally {
      //
    }
    // isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    // Remove non-numeric characters (e.g., "-release") and parse as double
    List<int> parseVersion(String version) {
      return version
          .split('.')
          .map((part) =>
              int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
          .toList();
    }

    List<int> currentParts = parseVersion(currentVersion);
    List<int> latestParts = parseVersion(latestVersion);

    for (int i = 0; i < latestParts.length; i++) {
      if (latestParts[i] > (i < currentParts.length ? currentParts[i] : 0)) {
        return true;
      }
    }
    return false;
  }

  Future<void> checkForAppUpdate(BuildContext context) async {
    if (kIsWeb) return;
    final appUpdateResp = await apiService.checkAppUpdate();
    if (appUpdateResp != null) {
      // Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      String currentVersion = packageInfo.version;
      if (_isUpdateAvailable(currentVersion, appUpdateResp.version ?? "")) {
        // GoRouter.of(context).push("/udpate-checker");
      }
      appUpdate = appUpdateResp;
    }

    notifyListeners();
  }
}
