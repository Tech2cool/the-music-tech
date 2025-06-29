import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_music_tech/components/skeleton_horizontal.dart';
import 'package:the_music_tech/core/providers/my_provider.dart';
import 'package:the_music_tech/core/services/shared_pref_service.dart';
import 'package:the_music_tech/pages/album_info_page.dart';
import 'package:the_music_tech/pages/artist_info_page.dart';
import 'package:the_music_tech/pages/music_player_page.dart';
import 'package:the_music_tech/pages/playlist_info_page.dart';
import 'package:toastification/toastification.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  // List<SearchModel> _suggestions = [];
  Timer? _debounce;
  String? selectedFilter = "ALL";
  bool isLoading = false;
  FocusNode focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final myProvider = Provider.of<MyProvider>(
        context,
        listen: false,
      );

      if (query.isNotEmpty) {
        _fetchSuggestions(query);
      } else {
        myProvider.resetSearch();
      }
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final myProvider = Provider.of<MyProvider>(
        context,
        listen: false,
      );

      setState(() {
        isLoading = true;
      });
      await myProvider.searchMusic(query, selectedFilter!);
    } catch (e) {
      // print("Error fetching suggestions: $e");
      // Helper.showCustomSnackBar("$e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myProvider = Provider.of<MyProvider>(context);
    final searchResult = myProvider.searchResult;
    const dropDownItems = [
      DropdownMenuItem(
        value: "ALL",
        child: Text("All"),
      ),
      DropdownMenuItem(
        value: "SONG",
        child: Text("Songs"),
      ),
      DropdownMenuItem(
        value: "VIDEO",
        child: Text("Video"),
      ),
      DropdownMenuItem(
        value: "ALBUM",
        child: Text("Album"),
      ),
      DropdownMenuItem(
        value: "ARTIST",
        child: Text("Artist"),
      ),
      DropdownMenuItem(
        value: "PLAYLIST",
        child: Text("Playlist"),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Search Music",
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        actions: [
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 100,
              child: DropdownButtonFormField(
                isExpanded: true,
                padding: const EdgeInsets.all(0),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.transparent,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.transparent,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                value: selectedFilter,
                items: dropDownItems,
                onChanged: (value) {
                  setState(() {
                    selectedFilter = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              focusNode: focusNode,
              onTapOutside: (event) {
                focusNode.unfocus();
              },
              decoration: InputDecoration(
                hintText: 'Search for music',
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
            if (isLoading) ...[
              SizedBox(height: 10),
              Expanded(
                child: SkeletonHorizontal(isLoading: isLoading, length: 5),
              ),
            ] else
              Expanded(
                child: ListView.builder(
                  itemCount: searchResult.length,
                  itemBuilder: (context, index) {
                    final song = searchResult[index];
                    final isLikedMusic = myProvider.myPlayList
                        .firstWhereOrNull((ele) => ele.videoId == song.videoId);

                    return ListTile(
                      minVerticalPadding: 10,
                      contentPadding: EdgeInsets.only(
                        top: 10,
                        bottom: index == searchResult.length - 1 ? 80 : 10,
                        left: 5,
                        right: 5,
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
                            if (song.type == 'SONG' ||
                                song.type == 'VIDEO') ...[
                              PopupMenuItem(
                                onTap: () async {
                                  if (isLikedMusic != null) {
                                    final newList = myProvider.myPlayList
                                        .where((ele) =>
                                            ele.videoId != song.videoId)
                                        .toList();

                                    final updatedlist = newList
                                        .map((ele) => ele.toMap())
                                        .toList();

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
                                    final list = [...foundList, song];
                                    final savedList =
                                        list.map((ele) => ele.toMap()).toList();

                                    myProvider.updateMyList(list);

                                    await SharedPrefService.storeJsonArray(
                                      "play_list",
                                      savedList,
                                    );
                                    if (context.mounted) {
                                      toastification.show(
                                        context: context,
                                        title: Text('added to playlist'),
                                        autoCloseDuration:
                                            const Duration(seconds: 5),
                                      );
                                    }
                                  }
                                  myProvider.getMyPlayList();
                                },
                                child: Text("Add To Playlist"),
                              ),
                              PopupMenuItem(
                                onTap: () {
                                  myProvider.getSuggestedSongs(song.videoId!);
                                  myProvider.addToSuggestedIdList(song);
                                  if (context.mounted) {
                                    toastification.show(
                                      context: context,
                                      title: Text(
                                          'we will suggest more like this'),
                                      autoCloseDuration:
                                          const Duration(seconds: 5),
                                    );
                                  }
                                },
                                child: Text("Suggest more"),
                              ),
                            ],
                            if (song.type == 'PLAYLIST') ...[
                              PopupMenuItem(
                                onTap: () {
                                  myProvider.addToSaveLaterPlayList(song);
                                  if (context.mounted) {
                                    toastification.show(
                                      context: context,
                                      title: Text('Playlist saved 💖'),
                                      autoCloseDuration:
                                          const Duration(seconds: 5),
                                    );
                                  }
                                },
                                child: Text("Save for Later"),
                              ),
                            ],
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
                          myProvider.playlist = [];
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
          ],
        ),
      ),
    );
  }
}
