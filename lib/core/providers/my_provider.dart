import 'package:audio_service/audio_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:the_music_tech/core/models/models/home_suggestion.dart';
import 'package:the_music_tech/core/models/models/search_model.dart';
import 'package:the_music_tech/core/services/api_service.dart';
import 'package:the_music_tech/core/services/audio_player_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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
  // SearchModel? get currentMedia => _currentMedia;
  // SearchModel? get currentAlbum => _currentAlbum;
  // SearchModel? get currentArtist => _currentArtist;
  // SearchModel? get currentPlayList => _currentPlayList;

  List<SearchModel> playlist = [];
  List<SearchModel> albumList = [];
  List<SearchModel> searchResult = [];
  List<HomeSuggestion> homeResults = [];

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

  // yt calls
  Future<void> playAudioFromYouTube(String videoId, SearchModel music) async {
    try {
      // Check if the audio is already playing
      // if (currentMedia?.videoId == videoId) {
      //   // If the audio is already playing, just resume or toggle play/pause
      //   await audioHandler.play();
      //   return;
      // }
      isLoading = true;
      Future.microtask(() => notifyListeners());

      // setState(() {
      //   isLoading = true;
      // });

      StreamManifest? manifest;
      try {
        manifest = await youtubeExp.videos.streamsClient.getManifest(videoId);
      } catch (e) {
        print(e);
      }
      if (manifest != null) {
        var audioStreamInfo = manifest.audioOnly.withHighestBitrate();
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
        await audioHandler.loadPlaylist([src]);
        try {
          // await audioHandler.player.play();
          loadPlayListInBackground();
        } catch (e) {
          //
          print(e);
        }
      } else {
        final nextSong = playlist[currentIndex + 1];
        if (nextSong != null) {
          currentIndex += 1;
          currentMedia = nextSong;
          Future.microtask(() => notifyListeners());
          await playAudioFromYouTube(nextSong.videoId!, nextSong);
        }
      }
      // await loadAndPlay(
      //   audioStreamInfo.url.toString(),
      //   music.name ?? "NA",
      //   music.artist?.name ?? 'Unknown Artist',
      //   music.album?.name ?? 'Unknown Album',
      //   music.thumbnails.isNotEmpty ? music.thumbnails[0].url : null,
      //   music,
      // );
    } catch (e) {
      // Helper.showCustomSnackBar("Error Loading Music");
    } finally {
      //
    }
    isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  Future<void> loadPlayListInBackground() async {
    print("pass 0");

    if (playlist.isEmpty) {
      return;
    }
    print("pass 1");
    try {
      // Check if the audio is already playing
      // setState(() {
      //   isLoading = true;
      // });
      final filtedList = playlist
          .where((ele) => ele.videoId != currentMedia?.videoId)
          .toList();

      for (var pl in filtedList) {
        // final foundInList = audioHandler.playlist.firstWhereOrNull(
        //   (ele) =>
        //       ((ele as ProgressiveAudioSource).tag as MediaItem).id ==
        //       pl.videoId,
        // );
        // if (foundInList != null) {
        //   return;
        // }
        print("pass 2");
        StreamManifest? manifest;
        try {
          manifest = await youtubeExp.videos.streamsClient.getManifest(
            pl.videoId ?? "",
          );
        } catch (e) {
          print(e);
        }
        if (manifest != null) {
          var audioStreamInfo = manifest.audioOnly.withHighestBitrate();
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
          print("${pl.videoId} added to play list");
        }
      }
      // await audioHandler.loadPlaylist([src]);
      // await loadAndPlay(
      //   audioStreamInfo.url.toString(),
      //   music.name ?? "NA",
      //   music.artist?.name ?? 'Unknown Artist',
      //   music.album?.name ?? 'Unknown Album',
      //   music.thumbnails.isNotEmpty ? music.thumbnails[0].url : null,
      //   music,
      // );
    } catch (e) {
      print(e);

      // Helper.showCustomSnackBar("Error Loading Music");
    } finally {
      //
    }
    // isLoading = false;
    Future.microtask(() => notifyListeners());
  }
}
