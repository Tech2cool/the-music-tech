import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_music_tech/core/providers/my_provider.dart';
import 'package:the_music_tech/core/services/shared_pref_service.dart';
import 'package:the_music_tech/pages/album_info_page.dart';
import 'package:the_music_tech/pages/artist_info_page.dart';
import 'package:the_music_tech/pages/music_player_page.dart';
import 'package:the_music_tech/pages/playlist_info_page.dart';
import 'package:toastification/toastification.dart';

class MySaveLaterPlaylistPage extends StatefulWidget {
  const MySaveLaterPlaylistPage({super.key});

  @override
  State<MySaveLaterPlaylistPage> createState() =>
      _MySaveLaterPlaylistPageState();
}

class _MySaveLaterPlaylistPageState extends State<MySaveLaterPlaylistPage> {
  final TextEditingController _controller = TextEditingController();
  // List<SearchModel> _suggestions = [];
  Timer? _debounce;
  String query = "";
  bool isLoading = false;
  FocusNode focusNode = FocusNode();

  Future<void> onRefresh() async {
    final myProvider = Provider.of<MyProvider>(
      context,
      listen: false,
    );

    try {
      //
      await Future.wait([
        myProvider.getMySavedPlayList(),
      ]);
    } catch (e) {
      //
    }
  }

  @override
  void initState() {
    super.initState();
    onRefresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String typedQuery) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        query = typedQuery;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final myProvider = Provider.of<MyProvider>(context);
    final history = myProvider.saveLaterPlayList.where((ele) {
      final name = ele.name ?? "";

      return name.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Playlist 🎶"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              focusNode: focusNode,
              onTapOutside: (event) {
                focusNode.unfocus();
              },
              decoration: InputDecoration(
                hintText: 'Search...',
                contentPadding: EdgeInsets.all(0),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(10),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (history.isNotEmpty) ...[
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final song = history[index];
                    return ListTile(
                      // minVerticalPadding: 10,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
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
                                final newList = history
                                    .where((ele) => ele.videoId != song.videoId)
                                    .toList();

                                final updatedlist =
                                    newList.map((ele) => ele.toMap()).toList();

                                myProvider.updateMySaveLaterPlayList(newList);

                                await SharedPrefService.storeJsonArray(
                                  "save_later_playlist",
                                  updatedlist,
                                );
                                toastification.show(
                                  context: context,
                                  title: Text('Remove from list'),
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
                          myProvider.playlist = history;
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
              ),
            ),
          ],
          if (history.isEmpty) ...[
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
          SafeArea(
            child: SizedBox(
              height: 80,
            ),
          ),
        ],
      ),
    );
  }
}
