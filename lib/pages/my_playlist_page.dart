import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_music_tech/components/horizontal_slider.dart';
import 'package:the_music_tech/components/vertical_card.dart';
import 'package:the_music_tech/core/models/models/search_model.dart';
import 'package:the_music_tech/core/providers/my_provider.dart';
import 'package:the_music_tech/core/services/shared_pref_service.dart';
import 'package:the_music_tech/pages/album_info_page.dart';
import 'package:the_music_tech/pages/artist_info_page.dart';
import 'package:the_music_tech/pages/music_player_page.dart';
import 'package:the_music_tech/pages/my_history_page.dart';
import 'package:the_music_tech/pages/my_saved_playlist_page.dart';
import 'package:the_music_tech/pages/playlist_info_page.dart';
import 'package:toastification/toastification.dart';

class MyPlaylistPage extends StatefulWidget {
  const MyPlaylistPage({super.key});

  @override
  State<MyPlaylistPage> createState() => _MyPlaylistPageState();
}

class _MyPlaylistPageState extends State<MyPlaylistPage> {
  bool isLoading = false;
  Future<void> onRefresh() async {
    final myProvider = Provider.of<MyProvider>(
      context,
      listen: false,
    );
    setState(() {
      isLoading = true;
    });

    try {
      //
      await Future.wait([
        myProvider.getMyPlayList(),
        myProvider.getMyHistory(),
      ]);
    } catch (e) {
      //
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final myProvider = Provider.of<MyProvider>(context);
    final currentPlaylist = myProvider.currentPlayList;
    final history = myProvider.history;
    final activePlaylist = myProvider.myPlayList;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Library"),
        actions: [
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(),
            ),
          IconButton(
            onPressed: () {
              onRefresh();
            },
            icon: Icon(
              Icons.replay_outlined,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            HorizontalSlider(
              title: "Played Songs",
              headers: [
                Spacer(),
                GestureDetector(
                  onTap: () {
                    //TODO: See all
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MyHistoryPage(),
                      ),
                    );
                  },
                  child: Text(
                    "See all",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.deepOrange.withAlpha(220),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 5),
              ],
              childrens: [
                ...List.generate(history.length, (i2) {
                  final record2 = history[i2];

                  return VerticalCard(
                    item: record2,
                    list: history,
                  );
                }),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 10.0,
                right: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Playlist",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      //TODO: See all
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MySavedPlaylistPage(),
                        ),
                      );
                    },
                    child: Text(
                      "See all",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.deepOrange.withAlpha(220),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // SizedBox(width: 5),

                  // GestureDetector(
                  //   onTap: () {},
                  //   child: Icon(
                  //     Icons.play_circle,
                  //     size: 25,
                  //   ),
                  // ),
                ],
              ),
            ),
            if (activePlaylist.isNotEmpty) ...[
              ...List.generate(
                activePlaylist.length,
                (index) {
                  final song = activePlaylist[index];
                  return ListTile(
                    // minVerticalPadding: 10,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            song.name ?? "NA",
                            maxLines: 2,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          song.type,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                    trailing: PopupMenuButton(
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem(
                            onTap: () async {
                              final newList = activePlaylist
                                  .where((ele) => ele.videoId != song.videoId)
                                  .toList();

                              final updatedlist =
                                  newList.map((ele) => ele.toMap()).toList();

                              myProvider.updateMyList(newList);

                              await SharedPrefService.storeJsonArray(
                                "play_list",
                                updatedlist,
                              );
                              toastification.show(
                                context: context,
                                title: Text('Remove from playList'),
                                autoCloseDuration: const Duration(seconds: 5),
                              );
                            },
                            child: Text("Remove from list"),
                          ),
                        ];
                      },
                    ),
                    onTap: () {
                      if (song.type == "PLAYLIST") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayListInfoPage(
                              music: song,
                            ),
                          ),
                        );
                      } else if (song.type == "ARTIST") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArtistInfoPage(
                              music: song,
                            ),
                          ),
                        );
                      } else if (song.type == "ALBUM") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlbumInfoPage(
                              music: song,
                            ),
                          ),
                        );
                      } else {
                        myProvider.playlist = activePlaylist;
                        myProvider.currentIndex = index;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MusicPlayerPage(
                              music: song,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
            if (activePlaylist.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text(
                    "Checkout some Playlist or songs, it will be added here...",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            if (currentPlaylist != null) ...[
              ListTile(
                minVerticalPadding: 10,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        currentPlaylist.name ?? "NA",
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  maxLines: 1,
                  currentPlaylist.album?.name ??
                      currentPlaylist.artist?.name ??
                      "NA",
                ),
                leading: SizedBox(
                  width: 80,
                  height: 80,
                  child: CachedNetworkImage(
                    imageUrl: (currentPlaylist.thumbnails.isNotEmpty
                        ? currentPlaylist.thumbnails.length > 1
                            ? currentPlaylist.thumbnails[1].url ?? ""
                            : currentPlaylist.thumbnails[0].url ?? ""
                        : "https://static-00.iconduck.com/assets.00/no-image-icon-512x512-lfoanl0w.png"),
                    errorWidget: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
                  ),
                ),
                trailing: const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Active PlayList',
                      style: TextStyle(
                        fontSize: 9,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.play_circle_fill_rounded,
                      size: 40,
                    )
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayListInfoPage(
                        music: currentPlaylist,
                      ),
                    ),
                  );
                },
              ),
            ],
            SafeArea(
              child: SizedBox(
                height: 80,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
