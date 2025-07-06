import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_music_tech/core/models/models/search_model.dart';
import 'package:the_music_tech/core/providers/my_provider.dart';
import 'package:the_music_tech/core/services/shared_pref_service.dart';
import 'package:the_music_tech/pages/album_info_page.dart';
import 'package:the_music_tech/pages/artist_info_page.dart';
import 'package:the_music_tech/pages/music_player_page.dart';
import 'package:toastification/toastification.dart';

class PlayListInfoPage extends StatefulWidget {
  final SearchModel music;
  const PlayListInfoPage({super.key, required this.music});

  @override
  State<PlayListInfoPage> createState() => _PlayListInfoPageState();
}

class _PlayListInfoPageState extends State<PlayListInfoPage> {
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    fetchPlayList();
  }

  fetchPlayList() async {
    final myProvider = Provider.of<MyProvider>(context, listen: false);
    try {
      setState(() {
        isLoading = true;
      });
      await myProvider.getPlayListByid(widget.music);
    } catch (e) {
      //
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myProvider = Provider.of<MyProvider>(context);
    final playlist = myProvider.playlist;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text("Playlist")),
          body: ListView(
            children: [
              if (widget.music.thumbnails.isNotEmpty) ...[
                CarouselSlider.builder(
                  itemCount: widget.music.thumbnails.length,
                  options: CarouselOptions(aspectRatio: 9 / 5, autoPlay: true),
                  itemBuilder: (
                    BuildContext context,
                    int itemIndex,
                    int pageViewIndex,
                  ) {
                    final thumbnail = widget.music.thumbnails[itemIndex];
                    return CachedNetworkImage(
                      imageUrl: thumbnail.url ?? "",
                      // height: 200,
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              Text(
                widget.music.name ?? "NA",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Artist: ${widget.music.artist?.name ?? "NA"}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Album: ${widget.music.album?.name ?? "NA"}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Year: ${widget.music.year ?? "NA"}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Divider(color: Colors.grey.withOpacity(0.3)),
              if (playlist.isNotEmpty)
                ...List.generate(playlist.length, (index) {
                  final song = playlist[index];
                  return ListTile(
                    minVerticalPadding: 10,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                    title: Text(
                      song.name ?? "NA",
                      maxLines: 2,
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      maxLines: 1,
                      song.album?.name ?? song.artist?.name ?? "NA",
                    ),
                    leading: SizedBox(
                      width: 80,
                      height: 80,
                      child: CachedNetworkImage(
                        imageUrl: (song.thumbnails.isNotEmpty
                            ? song.thumbnails.length > 1
                                ? song.thumbnails[1].url ?? ""
                                : song.thumbnails[0].url ?? ""
                            : "https://static-00.iconduck.com/assets.00/no-image-icon-512x512-lfoanl0w.png"),
                        errorWidget: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                    // trailing: const Icon(
                    //   Icons.play_circle_fill_rounded,
                    //   size: 40,
                    // ),
                    trailing: (song.type == 'SONG' || song.type == 'VIDEO')
                        ? PopupMenuButton(
                            itemBuilder: (context) {
                              return [
                                if (song.type == 'SONG' || song.type == 'VIDEO')
                                  PopupMenuItem(
                                    onTap: () async {
                                      //TODO: add to play list
                                      final foundList =
                                          await myProvider.getMyPlayList();
                                      final list = [...foundList, song];
                                      final savedList = list
                                          .map((ele) => ele.toMap())
                                          .toList();

                                      await SharedPrefService.storeJsonArray(
                                        "play_list",
                                        savedList,
                                      );
                                      toastification.show(
                                        context: context,
                                        title: Text('Added to playlist'),
                                        autoCloseDuration:
                                            const Duration(seconds: 5),
                                      );
                                    },
                                    child: Text("Add To Playlist"),
                                  ),
                              ];
                            },
                          )
                        : null,

                    onTap: () {
                      if (song.type == "PLAYLIST") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayListInfoPage(music: song),
                          ),
                        );
                      } else if (song.type == "ARTIST") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArtistInfoPage(music: song),
                          ),
                        );
                      } else if (song.type == "ALBUM") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlbumInfoPage(music: song),
                          ),
                        );
                      } else {
                        bool sameList =
                            myProvider.currentPlayList?.playlistId ==
                                widget.music.playlistId;

                        myProvider.playlist = playlist;
                        myProvider.currentIndex = index;
                        myProvider.currentPlayList = widget.music;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MusicPlayerPage(
                              music: song,
                              isSameList: sameList,
                            ),
                          ),
                        );
                      }
                    },
                  );
                })
              else ...[
                const Text(
                  "Playlist is Empty",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
