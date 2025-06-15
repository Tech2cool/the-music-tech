import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_music_tech/components/horizontal_slider.dart';
import 'package:the_music_tech/components/vertical_card.dart';
import 'package:the_music_tech/core/models/models/search_model.dart';
import 'package:the_music_tech/core/providers/my_provider.dart';
import 'package:the_music_tech/core/services/shared_pref_service.dart';
import 'package:toastification/toastification.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:collection/collection.dart';

class MusicPlayerPage extends StatefulWidget {
  final SearchModel? music;
  final int index;

  const MusicPlayerPage({
    super.key,
    this.music,
    this.index = 0,
  });

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  // bool isLoading = false;
  // late SearchModel music;

  @override
  void initState() {
    super.initState();
    final myProvider = Provider.of<MyProvider>(
      context,
      listen: false,
    );
    if (widget.music != null) {
      myProvider.currentMedia = widget.music;
    }
    final music = myProvider.currentMedia ?? widget.music;
    if (widget.music != null) {
      _playAudioFromYouTube(music?.videoId ?? "");
    }
  }

  Future<void> _playAudioFromYouTube(String videoId) async {
    try {
      final myProvider = Provider.of<MyProvider>(
        context,
        listen: false,
      );

      final music = myProvider.currentMedia ?? widget.music;
      if (music == null) {
        // print("musc not provided");
        toastification.show(
          context: context,
          title: Text(
            'Music your looking for not available at moment, please try again',
          ),
          autoCloseDuration: const Duration(seconds: 5),
        );

        return;
      }
      await myProvider.playAudioFromYouTube(videoId, music);
    } catch (e) {
      //
    }
  }

  @override
  void dispose() {
    // _audioPlayer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myProvider = Provider.of<MyProvider>(context);
    final suggested = myProvider.suggested;

    final audioHandler = myProvider.audioHandler;
    final playlist = myProvider.playlist;
    final music = myProvider.currentMedia ?? widget.music;
    final isLoading = myProvider.isLoading;
    final cItem = audioHandler.mediaItem;
    // final cItem = audioHandler.mediaItem;
    final newMedia =
        playlist.firstWhereOrNull((ele) => ele.videoId == cItem.value?.id);

    final isLikedMusic = myProvider.myPlayList
        .firstWhereOrNull((ele) => ele.videoId == cItem.value?.id);

    final thumbnails = newMedia != null
        ? newMedia.thumbnails.map((ele) => ele.url).toList()
        : music?.thumbnails.map((ele) => ele.url).toList() ?? [];

    final mName = newMedia?.name ?? music?.name;
    final mArtistName = newMedia?.artist?.name ?? music?.artist?.name;
    final mAlbumName = newMedia?.album?.name ?? music?.album?.name;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Now Playing'),
            actions: [
              IconButton(
                onPressed: () async {
                  if (newMedia == null) {
                    return;
                  }
                  if (isLikedMusic != null) {
                    final newList = myProvider.myPlayList
                        .where((ele) => ele.videoId != newMedia.videoId)
                        .toList();

                    final updatedlist =
                        newList.map((ele) => ele.toMap()).toList();

                    myProvider.updateMyList(newList);

                    await SharedPrefService.storeJsonArray(
                      "play_list",
                      updatedlist,
                    );
                    // if (context.mounted) {
                    //   toastification.show(
                    //     context: context,
                    //     title: Text('Remove from playlist'),
                    //     autoCloseDuration: const Duration(seconds: 5),
                    //   );
                    // }
                  } else {
                    final foundList = myProvider.myPlayList;
                    final list = [...foundList, newMedia];
                    final savedList = list.map((ele) => ele.toMap()).toList();

                    myProvider.updateMyList(list);

                    await SharedPrefService.storeJsonArray(
                      "play_list",
                      savedList,
                    );
                    if (context.mounted) {
                      toastification.show(
                        context: context,
                        title: Text('added to playlist'),
                        autoCloseDuration: const Duration(seconds: 5),
                      );
                    }
                  }
                  myProvider.getMyPlayList();
                  myProvider.addToSuggestedIdList(newMedia);
                  myProvider.getSuggestedSongs(newMedia.videoId!);
                },
                icon: Icon(
                  FluentIcons.heart_12_filled,
                  size: 30,
                  color: isLikedMusic != null
                      ? Colors.pink
                      : Colors.grey.withAlpha(150),
                ),
              ),
              SizedBox(width: 10),
            ],
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
                HorizontalSlider(
                  title: "Suggested For you",
                  childrens: [
                    ...List.generate(
                      suggested.length,
                      (i2) {
                        final record2 = suggested[i2];

                        return Stack(
                          children: [
                            Positioned(
                              right: 0,
                              top: 0,
                              child: PopupMenuButton(
                                itemBuilder: (context) {
                                  return [
                                    PopupMenuItem(
                                      onTap: () {
                                        myProvider.loadSingleItemInBackground(
                                          record2,
                                        );
                                        if (context.mounted) {
                                          toastification.show(
                                            context: context,
                                            title: Text('added to queue'),
                                            autoCloseDuration:
                                                const Duration(seconds: 5),
                                          );
                                        }
                                      },
                                      child: Text("add to queue"),
                                    ),
                                  ];
                                },
                              ),
                            ),
                            VerticalCard(
                              item: record2,
                              list: suggested,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
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
                          color: (audioHandler.player.currentIndex ?? 0) > 0
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 30,
                        ),
                        onPressed: () {
                          audioHandler.skipToPrevious();
                          setState(() {});
                        }),
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
                            setState(() {});
                          },
                        );
                      },
                    ),
                    //skip next
                    IconButton(
                      icon: Icon(
                        Icons.skip_next_rounded,
                        color: (audioHandler.player.currentIndex ?? 0) <=
                                audioHandler.playlist.length - 1
                            ? Colors.white
                            : Colors.grey.shade600,
                        size: 30,
                      ),
                      onPressed: () {
                        audioHandler.skipToNext();
                        setState(() {});
                      },
                    ),
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
