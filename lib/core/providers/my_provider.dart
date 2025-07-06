import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';

import 'package:the_music_tech/components/update_checker.dart';

import 'package:the_music_tech/core/models/app_update.dart';

import 'package:the_music_tech/core/models/cached_manifest.dart';

import 'package:the_music_tech/core/models/models/home_suggestion.dart';

import 'package:the_music_tech/core/models/models/search_model.dart';

import 'package:the_music_tech/core/models/suggestion_id.dart';

import 'package:the_music_tech/core/services/api_service.dart';

import 'package:the_music_tech/core/services/audio_player_handler.dart';

import 'package:the_music_tech/core/services/shared_pref_service.dart';

import 'package:toastification/toastification.dart';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:package_info_plus/package_info_plus.dart';

class MyProvider with ChangeNotifier {
  late final AudioPlayerHandler _audioHandler;

  bool isLoading = false;

  final ApiService apiService = ApiService();

  final YoutubeExplode youtubeExp = YoutubeExplode();

  // Performance optimization: Debounce timer for state updates

  Timer? _debounceTimer;

  Timer? _cacheCleanupTimer;

  // Performance optimization: Processing flags

  bool _isLoadingPlaylist = false;

  bool _isLoadingSuggested = false;

  int currentIndex = 0;

  SearchModel? currentAlbum;

  SearchModel? currentArtist;

  SearchModel? currentPlayList;

  SearchModel? currentMedia;

  RelatedVideosList? relatedVideos;

  List<SearchModel> suggested = [];

  List<SearchModel> suggestedAll = [];

  List<SuggestionId> suggestedIds = [];

  AudioPlayerHandler get audioHandler => _audioHandler;

  MediaItem? _currentMusic;

  MediaItem? get currentMusic => _currentMusic;

  set currentMusic(MediaItem? item) {
    _currentMusic = item;

    _debouncedNotify();
  }

  List<SearchModel> playlist = [];

  List<SearchModel> albumList = [];

  List<SearchModel> searchResult = [];

  List<SearchModel> myPlayList = [];

  List<SearchModel> history = [];

  List<SearchModel> saveLaterPlayList = [];

  List<HomeSuggestion> homeResults = [];

  // Performance optimization: Enhanced cache management

  final Map<String, CachedManifest> _manifestCache = {};

  final Duration cacheDuration = Duration(minutes: 45);

  static const int maxCacheSize = 50;

  static const int maxHistorySize = 300;

  static const int maxSLPlaylistSize = 300;

  static const int batchSize = 3;

  AppUpdate? appUpdate;

  // Performance optimization: Debounced notify

  void _debouncedNotify() {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      notifyListeners();
    });
  }

  // Performance optimization: Immediate notify for critical updates

  void _immediateNotify() {
    _debounceTimer?.cancel();

    notifyListeners();
  }

  // Performance optimization: Cache cleanup

  void _cleanupCache() {
    final now = DateTime.now();

    // Remove expired entries

    _manifestCache.removeWhere(
        (key, cached) => now.difference(cached.cacheTime) > cacheDuration);

    // Limit cache size

    if (_manifestCache.length > maxCacheSize) {
      final sortedEntries = _manifestCache.entries.toList()
        ..sort((a, b) => a.value.cacheTime.compareTo(b.value.cacheTime));

      // Remove oldest entries

      final entriesToRemove = _manifestCache.length - (maxCacheSize - 10);

      for (int i = 0; i < entriesToRemove; i++) {
        _manifestCache.remove(sortedEntries[i].key);
      }
    }
  }

  // Performance optimization: Memory management for lists

  void _limitListSize<T>(List<T> list, int maxSize) {
    if (list.length > maxSize) {
      final itemsToRemove = list.length - maxSize;

      list.removeRange(0, itemsToRemove);
    }
  }

  // Init services with performance optimizations
  Future<void> init(MyProvider provider) async {
    _audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.app.channel.audio',
        androidNotificationChannelName: 'Audio Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );

    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        _currentMusic = mediaItem;
      }

      _debouncedNotify();
    });

    // Start periodic cache cleanup

    _cacheCleanupTimer = Timer.periodic(Duration(minutes: 10), (_) {
      _cleanupCache();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();

    _cacheCleanupTimer?.cancel();

    youtubeExp.close();

    super.dispose();
  }

  // Calls

  Stream<Duration> get positionStream => _audioHandler.player.positionStream;

  Stream<Duration?> get durationStream => _audioHandler.player.durationStream;

  // Method to reset audio player and stop background loading

  Future<void> resetAudioPlayerAndPlaylist() async {
    try {
      // Stop any ongoing background loading
      _isLoadingPlaylist = false;
      _isLoadingSuggested = false;

      // Clear the current playlist in audio handler
      await _audioHandler.stop();
      await _audioHandler.clearPlaylist();

      // Reset current states
      currentIndex = 0;
      currentMedia = null;
      _currentMusic = null;

      // Clear playlist and related data
      // playlist.clear();
      suggested.clear();
      relatedVideos = null;

      // Clear cache if needed (optional - you might want to keep some cache)
      // _manifestCache.clear();

      _immediateNotify();

      print('🔄 Audio player and playlist reset successfully');
    } catch (e) {
      print('❌ Error resetting audio player: $e');
    }
  }

  // Method to check if a song is from current playlist
  bool isSongFromCurrentPlaylist(SearchModel song) {
    if (playlist.isEmpty) return false;
    return playlist.any((item) => item.videoId == song.videoId);
  }

  // Convenience method to play a completely new song
  Future<void> playNewSong(String videoId, SearchModel music) async {
    await playAudioFromYouTube(videoId, music, isNewSong: true);
  }

  // Method to stop all background loading
  void stopAllBackgroundLoading() {
    _isLoadingPlaylist = false;
    _isLoadingSuggested = false;
    print('🛑 All background loading stopped');
    _debouncedNotify();
  }

  // API calls with performance optimization

  Future<void> searchMusic(String query, String selectedFilter) async {
    try {
      final results = await apiService.searchSongs(query, selectedFilter);

      searchResult = results;

      _debouncedNotify();
    } catch (e) {
      // print("Search error: $e");
    }
  }

  // Home suggestions with error handling

  Future<void> getHomeSuggestion() async {
    try {
      final results = await apiService.getHomeData();

      homeResults = results;

      _debouncedNotify();
    } catch (e) {
      // print("Home suggestion error: $e");
    }
  }

  void updateMyList(List<SearchModel> list) {
    myPlayList = list;

    _debouncedNotify();
  }

  void updateMySaveLaterPlayList(List<SearchModel> list) {
    saveLaterPlayList = list;

    _debouncedNotify();
  }

  // Performance optimization: Enhanced history management

  Future<void> addToHistory([SearchModel? song]) async {
    try {
      final foundList = await SharedPrefService.getJsonArray('history');

      if (foundList != null) {
        final list = foundList.map((ele) => SearchModel.fromMap(ele)).toList();

        history = list;
      }

      if (song != null) {
        // Remove duplicates

        history.removeWhere((item) => item.videoId == song.videoId);

        history.add(song);
      }

      // Limit history size for performance

      _limitListSize(history, maxHistorySize);

      final savedList = history.map((ele) => ele.toMap()).toList();

      await SharedPrefService.storeJsonArray("history", savedList);

      _debouncedNotify();
    } catch (e) {
      // print("Add to history error: $e");
    }
  }

  Future<List<SearchModel>> getMyHistory() async {
    try {
      final foundList = await SharedPrefService.getJsonArray('history');

      if (foundList != null) {
        final list = foundList.map((ele) => SearchModel.fromMap(ele)).toList();

        history = list;
      }

      _debouncedNotify();

      return history;
    } catch (e) {
      // print("Get history error: $e");

      return [];
    }
  }

  Future<List<SearchModel>> getMyPlayList() async {
    try {
      final foundList = await SharedPrefService.getJsonArray('play_list');

      if (foundList != null) {
        final list = foundList.map((ele) => SearchModel.fromMap(ele)).toList();

        myPlayList = list;
      }

      _debouncedNotify();

      return myPlayList;
    } catch (e) {
      // print("Get playlist error: $e");

      return [];
    }
  }

  Future<void> getPlayListByid(SearchModel music) async {
    try {
      final resp = await apiService.getPlayListById(music.playlistId!);

      playlist = resp;

      _debouncedNotify();
    } catch (e) {
      // print("Get playlist by ID error: $e");
    }
  }

  Future<void> getArtistByid(SearchModel music) async {
    try {
      final resp = await apiService.getArtistById(music.artistId!);

      currentArtist = resp;

      _debouncedNotify();
    } catch (e) {
      // print("Get artist by ID error: $e");
    }
  }

  Future<void> getAlbumById(SearchModel music) async {
    try {
      final resp = await apiService.getAlbumById(music.albumId!);

      currentAlbum = resp;

      _debouncedNotify();
    } catch (e) {
      // print("Get album by ID error: $e");
    }
  }

  void resetSearch() {
    searchResult = [];

    _debouncedNotify();
  }

  void setLoading(bool value) {
    if (isLoading != value) {
      isLoading = value;

      _immediateNotify(); // Loading state needs immediate update
    }
  }

  // Performance optimization: Single track processing

  Future<AudioSource?> _processSingleTrack(SearchModel track) async {
    try {
      StreamManifest? manifest;

      final now = DateTime.now();

      final cached = _manifestCache[track.videoId];

      if (cached != null && now.difference(cached.cacheTime) < cacheDuration) {
        manifest = cached.manifest;
      } else {
        manifest = await youtubeExp.videos.streamsClient
            .getManifest(track.videoId ?? "")
            .timeout(Duration(seconds: 10));

        if (manifest != null) {
          _manifestCache[track.videoId ?? ""] = CachedManifest(manifest, now);
        }
      }

      if (manifest != null && manifest.audioOnly.isNotEmpty) {
        final audioStreamInfo = manifest.audioOnly.first;

        final img =
            track.thumbnails.isNotEmpty ? track.thumbnails[0].url : null;

        return AudioSource.uri(
          audioStreamInfo.url,
          tag: MediaItem(
            id: track.videoId!,
            title: track.name ?? "NA",
            artist: track.artist?.name ?? 'Unknown Artist',
            artUri: img != null ? Uri.parse(img) : null,
            album: track.album?.name ?? 'Unknown Album',
          ),
        );
      }
    } catch (e) {
      // print('Failed to process ${track.videoId}: $e');
    }

    return null;
  }

  // Updated playAudioFromYouTube method with reset functionality
  Future<void> playAudioFromYouTube(
    String videoId,
    SearchModel music, {
    bool isNewSong = false,
  }) async {
    setLoading(true);

    // If this is a new song not from current playlist, reset everything
    if (isNewSong) {
      await resetAudioPlayerAndPlaylist();
    }

    // Non-blocking history addition

    addToHistory(music).catchError((e) => {});

    StreamManifest? manifest;

    final now = DateTime.now();

    final cached = _manifestCache[videoId];

    if (cached != null && now.difference(cached.cacheTime) < cacheDuration) {
      manifest = cached.manifest;

      // print('Using cached manifest for $videoId');
    } else {
      try {
        manifest = await youtubeExp.videos.streamsClient
            .getManifest(videoId)
            .timeout(Duration(seconds: 10));

        if (manifest != null) {
          _manifestCache[videoId] = CachedManifest(manifest, now);
        }
      } catch (e) {
        // print("Manifest error: $e");
      }
    }

    setLoading(false);

    if (manifest != null && manifest.audioOnly.isNotEmpty) {
      final audioStreamInfo = manifest.audioOnly.first;

      final img = music.thumbnails.isNotEmpty ? music.thumbnails[0].url : null;

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

      try {
        await audioHandler.loadPlaylist([src]);

        // Update current media
        currentMedia = music;

        getSuggestedSongs(videoId);

        // Start background loading without blocking (only if not a new song)
        if (!isNewSong) {
          _loadPlayListInBackground();
        }
      } catch (e) {
        // print("Audio load error: $e");
      }
    } else {
      // Fallback to next available song

      await _tryNextSong();
    }
  }

  // Performance optimization: Fallback mechanism

  Future<void> _tryNextSong() async {
    while (currentIndex + 1 < playlist.length) {
      currentIndex += 1;

      final nextSong = playlist[currentIndex];

      currentMedia = nextSong;

      _immediateNotify();

      return await playAudioFromYouTube(nextSong.videoId!, nextSong);
    }

    toastification.show(
      title: Text('Sorry, no playable music found'),
      autoCloseDuration: Duration(seconds: 5),
    );
  }

  // Updated _loadPlayListInBackground with cancellation support
  Future<void> _loadPlayListInBackground() async {
    if (playlist.isEmpty || _isLoadingPlaylist) return;

    _isLoadingPlaylist = true;

    try {
      int indexOfcurr =
          currentMedia != null ? playlist.indexOf(currentMedia!) : 0;

      if (indexOfcurr < 0) indexOfcurr = 0;

      final skipedBeforeList = playlist.sublist(indexOfcurr, playlist.length);

      final filteredList = skipedBeforeList
          .where((ele) => ele.videoId != currentMedia?.videoId)
          .toList();

      // Add to history without blocking

      final uniqueHistory = <String, SearchModel>{};

      for (final item in [...history, ...filteredList]) {
        if (item.videoId != null) {
          uniqueHistory[item.videoId!] = item;

          // Save history in background

          addToHistory(item).catchError((e) => {});
        }
      }

      history = uniqueHistory.values.toList();

      _limitListSize(history, maxHistorySize);

      // Process in batches with cancellation check
      for (int i = 0; i < filteredList.length; i += batchSize) {
        // Check if loading was cancelled
        if (!_isLoadingPlaylist) {
          print('🛑 Background playlist loading cancelled');
          return;
        }

        final batch = filteredList.skip(i).take(batchSize).toList();

        final futures = batch.map((track) => _processSingleTrack(track));

        final results = await Future.wait(futures);

        // Add successful results to playlist

        for (final audioSource in results) {
          if (audioSource != null && _isLoadingPlaylist) {
            try {
              await audioHandler.addToPlaylist(audioSource);
            } catch (e) {
              // print('Failed to add to playlist: $e');
            }
          }
        }

        // Small delay between batches

        if (i + batchSize < filteredList.length && _isLoadingPlaylist) {
          await Future.delayed(Duration(milliseconds: 200));
        }
      }

      // Cleanup cache periodically

      _cleanupCache();
    } catch (e) {
      // print("loadPlayListInBackground error: $e");
    } finally {
      _isLoadingPlaylist = false;

      _debouncedNotify();
    }
  }

  // Performance optimization: Load single item in background

  Future<void> loadSingleItemInBackground(SearchModel item) async {
    if (item.videoId == null || item.videoId!.isEmpty) {
      // print('Invalid video ID for item: ${item.name}');

      return;
    }

    try {
      // print('🔄 Loading single item in background: ${item.name}');

      // Add to history without blocking

      final uniqueHistory = <String, SearchModel>{};

      for (final historyItem in [...history, item]) {
        if (historyItem.videoId != null) {
          uniqueHistory[historyItem.videoId!] = historyItem;
        }
      }

      history = uniqueHistory.values.toList();

      _limitListSize(history, maxHistorySize);

      // Process the single track

      final audioSource = await _processSingleTrack(item);

      // Add to playlist if successful

      if (audioSource != null) {
        try {
          await audioHandler.addToPlaylist(audioSource);

          // print('✅ Successfully added ${item.name} to playlist');
        } catch (e) {
          // print('❌ Failed to add ${item.name} to playlist: $e');
        }
      } else {
        // print('❌ Failed to process ${item.name} - no audio source created');
      }

      // Cleanup cache periodically (every 10th call)

      if (DateTime.now().millisecondsSinceEpoch % 10 == 0) {
        _cleanupCache();
      }

      _debouncedNotify();
    } catch (e) {
      // print("loadSingleItemInBackground error for ${item.name}: $e");
    }
  }

  // Performance optimization: Batched suggested loading

  Future<void> _loadSuggestedInBackground() async {
    if (suggested.isEmpty || _isLoadingSuggested) return;

    _isLoadingSuggested = true;

    try {
      final filteredList = suggested
          .where((ele) => ele.videoId != currentMedia?.videoId)
          .toList();

      // Add to history without blocking

      final uniqueHistory = <String, SearchModel>{};

      for (final item in [...history, ...filteredList]) {
        if (item.videoId != null) {
          uniqueHistory[item.videoId!] = item;
        }
      }

      history = uniqueHistory.values.toList();

      _limitListSize(history, maxHistorySize);

      // Save history in background

      // addToHistory().catchError((e) => print("Add to history failed: $e"));

      // Process in smaller batches for suggestions

      const suggestedBatchSize = 2;

      for (int i = 0; i < filteredList.length; i += suggestedBatchSize) {
        final batch = filteredList.skip(i).take(suggestedBatchSize).toList();

        final futures = batch.map((track) => _processSingleTrack(track));

        final results = await Future.wait(futures);

        // Add successful results to playlist

        for (final audioSource in results) {
          if (audioSource != null) {
            try {
              await audioHandler.addToPlaylist(audioSource);
            } catch (e) {
              // print('Failed to add suggested to playlist: $e');
            }
          }
        }

        // Longer delay for suggestions to not interfere with main playlist

        if (i + suggestedBatchSize < filteredList.length) {
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      // print("loadSuggestedInBackground error: $e");
    } finally {
      _isLoadingSuggested = false;

      _debouncedNotify();
    }
  }

  bool _isUpdateAvailable(String currentVersion, String latestVersion) {
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

    try {
      final appUpdateResp = await apiService.checkAppUpdate();

      // print(appUpdateResp?.toJson());

      if (appUpdateResp != null) {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();

        String currentVersion = packageInfo.version;

        // print(currentVersion);

        if (_isUpdateAvailable(currentVersion, appUpdateResp.version ?? "")) {
          // print("yes update");

          // Handle update logic here

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UpdateChecker(),
            ),
          );
        }

        appUpdate = appUpdateResp;
      }

      _debouncedNotify();
    } catch (e) {
      // print("App update check error: $e");
    }
  }

  Future<void> addToSuggestedIdList(SearchModel music) async {
    try {
      final uniqueLeads = <String, SuggestionId>{};

      // Add existing suggestions

      for (final suggestion in suggestedIds) {
        if (suggestion.videoId.isNotEmpty) {
          uniqueLeads[suggestion.videoId] = suggestion;
        }
      }

      // Add new suggestion

      if (music.videoId?.isNotEmpty == true) {
        uniqueLeads[music.videoId!] = SuggestionId(
          videoId: music.videoId!,
          name: music.name ?? "",
          date: DateTime.now(),
        );
      }

      suggestedIds = uniqueLeads.values.toList();

      // Limit suggestions list size

      _limitListSize(suggestedIds, 50);

      final savedList = suggestedIds.map((ele) => ele.toMap()).toList();

      await SharedPrefService.storeJsonArray("suggestedIds", savedList);

      _debouncedNotify();
    } catch (e) {
      print("Add to suggested IDs error: $e");
    }
  }

  // Performance optimization: Optimized suggested songs with chunking

  Future<void> getSuggestedSongs(String videoId) async {
    try {
      final video = await youtubeExp.videos.get(
        'https://youtube.com/watch?v=$videoId',
      );

      final relatedVideosResp = await youtubeExp.videos.getRelatedVideos(video);

      relatedVideos = relatedVideosResp;

      if (relatedVideosResp != null && relatedVideosResp.isNotEmpty) {
        // Process suggestions more efficiently

        final newSuggested = <SearchModel>[];

        for (final ele in relatedVideosResp.take(20)) {
          final thumbnails = <ThumbnailModel>[];

          // Build thumbnails list more efficiently

          final thumbnailUrls = [
            (ele.thumbnails.highResUrl, 1920, 1080),
            (ele.thumbnails.mediumResUrl, 1280, 720),
            (ele.thumbnails.standardResUrl, 854, 420),
            (ele.thumbnails.lowResUrl, 480, 360),
          ];

          for (final (url, width, height) in thumbnailUrls) {
            if (url.isNotEmpty) {
              thumbnails.add(ThumbnailModel(
                url: url,
                width: width,
                height: height,
              ));
            }
          }

          newSuggested.add(SearchModel(
            type: 'VIDEO',
            videoId: ele.id.value,
            artistId: ele.channelId.value,
            name: ele.title,
            thumbnails: thumbnails,
            artist: Artist(
              name: ele.author,
              artistId: ele.channelId.value,
            ),
          ));
        }

        // Update current suggestions

        suggested = newSuggested;

        // Efficiently merge with suggestedAll using Map for O(1) lookup

        final uniqueSuggestions = <String, SearchModel>{};

        // Add existing suggestions

        for (final suggestion in suggestedAll) {
          if (suggestion.videoId != null) {
            uniqueSuggestions[suggestion.videoId!] = suggestion;
          }
        }

        // Add new suggestions

        for (final suggestion in newSuggested) {
          if (suggestion.videoId != null) {
            uniqueSuggestions[suggestion.videoId!] = suggestion;
          }
        }

        suggestedAll = uniqueSuggestions.values.toList();

        // Limit size to prevent memory issues

        _limitListSize(suggestedAll, 100); // Adjust limit as needed

        _debouncedNotify();
      }
    } catch (e) {
      print('getSuggestedSongs error: $e');
    }
  }

  // Method to clear all suggestions if needed

  void clearAllSuggestions() {
    suggested.clear();

    suggestedAll.clear();

    _debouncedNotify();
  }

  Future<void> getAllSuggestedList() async {
    //

    try {
      final foundList = await SharedPrefService.getJsonArray('suggestedIds');

      if (foundList != null) {
        final list = foundList.map((ele) => SuggestionId.fromMap(ele)).toList();

        suggestedIds = list;
      }

      if (suggestedIds.isNotEmpty) {
        for (var id in suggestedIds) {
          //

          getSuggestedSongs(id.videoId);
        }
      }

      // _debouncedNotify();
    } catch (e) {
      // print("Get suggested Id error: $e");
    }
  }

  Future<void> addToSaveLaterPlayList(SearchModel song) async {
    try {
      final foundList =
          await SharedPrefService.getJsonArray('save_later_playlist');

      if (foundList != null) {
        final list = foundList.map((ele) => SearchModel.fromMap(ele)).toList();

        saveLaterPlayList = list;
      }

      if (song != null) {
        // Remove duplicates

        saveLaterPlayList
            .removeWhere((item) => item.playlistId == song.playlistId);

        saveLaterPlayList.add(song);
      }

      // Limit history size for performance

      _limitListSize(saveLaterPlayList, maxSLPlaylistSize);

      final savedList = saveLaterPlayList.map((ele) => ele.toMap()).toList();

      await SharedPrefService.storeJsonArray("save_later_playlist", savedList);

      _debouncedNotify();
    } catch (e) {
      // print("Add to history error: $e");
    }
  }

  Future<List<SearchModel>> getMySavedPlayList() async {
    try {
      final foundList =
          await SharedPrefService.getJsonArray('save_later_playlist');

      if (foundList != null) {
        final list = foundList.map((ele) => SearchModel.fromMap(ele)).toList();

        saveLaterPlayList = list;
      }

      _debouncedNotify();

      return saveLaterPlayList;
    } catch (e) {
      // print("Get history error: $e");

      return [];
    }
  }
}
