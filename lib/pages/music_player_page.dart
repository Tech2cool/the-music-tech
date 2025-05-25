import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_music_tech/core/models/models/search_model.dart';
import 'package:the_music_tech/core/providers/my_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:carousel_slider/carousel_slider.dart';

class MusicPlayerPage extends StatefulWidget {
  final SearchModel music;
  final int index;

  const MusicPlayerPage({
    super.key,
    required this.music,
    this.index = 0,
  });

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  final YoutubeExplode _yt = YoutubeExplode();
  // bool isLoading = false;
  // late SearchModel music;

  @override
  void initState() {
    super.initState();
    final myProvider = Provider.of<MyProvider>(
      context,
      listen: false,
    );

    myProvider.currentMedia = widget.music;
    final music = myProvider.currentMedia ?? widget.music;
    _playAudioFromYouTube(music.videoId ?? "");
  }

  Future<void> _playAudioFromYouTube(String videoId) async {
    try {
      final myProvider = Provider.of<MyProvider>(
        context,
        listen: false,
      );

      // setState(() {
      //   isLoading = true;
      // });
      final music = myProvider.currentMedia ?? widget.music;

      await myProvider.playAudioFromYouTube(videoId, music);
    } catch (e) {
      //
    }
    // setState(() {
    //   isLoading = false;
    // });

    //   // Check if the audio is already playing
    //   if (myProvider.currentMedia?.videoId == videoId) {
    //     // If the audio is already playing, just resume or toggle play/pause
    //     await myProvider.audioHandler.play();
    //     return;
    //   }

    //   setState(() {
    //     isLoading = true;
    //   });

    //   var manifest = await _yt.videos.streamsClient.getManifest(videoId);
    //   var audioStreamInfo = manifest.audioOnly.withHighestBitrate();

    //   await myProvider.loadAndPlay(
    //     audioStreamInfo.url.toString(),
    //     music.name ?? "NA",
    //     music.artist?.name ?? 'Unknown Artist',
    //     music.album?.name ?? 'Unknown Album',
    //     music.thumbnails.isNotEmpty ? music.thumbnails[0].url : null,
    //     music,
    //   );
    // } catch (e) {
    //   Helper.showCustomSnackBar("Error Loading Music");
    // } finally {
    //   setState(() {
    //     isLoading = false;
    //   });
    // }
  }

  @override
  void dispose() {
    // _audioPlayer.dispose();
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myProvider = Provider.of<MyProvider>(context);
    final audioHandler = myProvider.audioHandler;
    final playlist = myProvider.playlist;
    final music = myProvider.currentMedia ?? widget.music;
    final isLoading = myProvider.isLoading;
    final cItem = audioHandler.mediaItem;
    final thumbnails = cItem.value?.artUri != null
        ? [cItem.value?.artUri.toString()]
        : music.thumbnails.map((ele) => ele.url).toList();
    final mName = cItem.value?.title ?? music.name;
    final mArtistName = cItem.value?.artist ?? music.artist?.name;
    final mAlbumName = cItem.value?.album ?? music.album?.name;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Now Playing'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (thumbnails.isNotEmpty) ...[
                  CarouselSlider.builder(
                    itemCount: thumbnails.length,
                    options: CarouselOptions(),
                    itemBuilder: (
                      BuildContext context,
                      int itemIndex,
                      int pageViewIndex,
                    ) {
                      final thumbnail = thumbnails[itemIndex];
                      return CachedNetworkImage(
                        imageUrl: thumbnail ?? "",
                        // height: 200,
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  mName ?? "NA",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Artist: ${mArtistName ?? "NA"}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "Album: ${mAlbumName ?? "NA"}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                StreamBuilder<Duration?>(
                  stream: myProvider.durationStream,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;

                    return StreamBuilder<Duration>(
                      stream: myProvider.positionStream,
                      builder: (context, positionSnapshot) {
                        final position = positionSnapshot.data ?? Duration.zero;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Slider(
                              value: position.inSeconds.toDouble(),
                              min: 0.0,
                              max: duration.inSeconds.toDouble(),
                              onChanged: (value) {
                                myProvider.audioHandler
                                    .seek(Duration(seconds: value.toInt()));
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position)),
                                  Text(_formatDuration(duration)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //skip prev
                    IconButton(
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: (audioHandler.player.currentIndex ?? 0) > 1
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 30,
                        ),
                        onPressed: () {
                          audioHandler.skipToPrevious();
                        } // myProvider.onTapPrev,
                        // onPressed: () {
                        //   if (myProvider.currentIndex <= 0) return;
                        //   // setState(() {
                        //   //   music =
                        //   //       playlist[myProvider.currentIndex - 1];
                        //   // });
                        //   myProvider.updateCurrentMusic(
                        //       playlist[myProvider.currentIndex - 1]);

                        //   _playAudioFromYouTube(
                        //     playlist[myProvider.currentIndex - 1]
                        //         .videoId!,
                        //   );
                        //   myProvider.updateCurrentIndex(
                        //     myProvider.currentIndex - 1,
                        //   );
                        // },
                        ),
                    // play/pause
                    StreamBuilder<PlaybackState>(
                      stream: audioHandler.playbackState,
                      builder: (context, snapshot) {
                        final state = snapshot.data;
                        final isPlaying = state?.playing ?? false;
                        return IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 64,
                          ),
                          onPressed: () {
                            isPlaying
                                ? audioHandler.pause()
                                : audioHandler.play();
                          },
                        );
                      },
                    ),
                    //skip next
                    IconButton(
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: (audioHandler.player.currentIndex ?? 0) <=
                                  myProvider.playlist.length
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 30,
                        ),
                        onPressed: () {
                          audioHandler.skipToNext();
                        } //myProvider.onTapNext,
                        // onPressed: () {
                        //   if (myProvider.currentIndex >=
                        //       playlist.length) {
                        //     // Helper.showCustomSnackBar("no next song");
                        //     return;
                        //   }
                        //   myProvider.updateCurrentMusic(
                        //       playlist[myProvider.currentIndex + 1]);
                        //   // setState(() {
                        //   //   music =
                        //   //       playlist[myProvider.currentIndex + 1];
                        //   // });

                        //   _playAudioFromYouTube(
                        //     playlist[myProvider.currentIndex + 1]
                        //         .videoId!,
                        //   );
                        //   myProvider.updateCurrentIndex(
                        //     myProvider.currentIndex + 1,
                        //   );
                        // },
                        ),
                    // IconButton(
                    //   icon: const Icon(Icons.stop),
                    //   onPressed: myProvider.stop,
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isLoading) ...[
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
        ],
      ],
    );
  }

  // Format duration to a readable string
  String _formatDuration(Duration duration) {
    return duration.toString().split('.').first.padLeft(8, "0");
  }
}
