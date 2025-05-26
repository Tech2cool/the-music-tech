import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_music_tech/core/models/models/search_model.dart';
import 'package:the_music_tech/core/providers/my_provider.dart';
import 'package:the_music_tech/pages/album_info_page.dart';
import 'package:the_music_tech/pages/music_player_page.dart';
import 'package:the_music_tech/pages/playlist_info_page.dart';

class ArtistInfoPage extends StatefulWidget {
  final SearchModel music;
  const ArtistInfoPage({super.key, required this.music});

  @override
  State<ArtistInfoPage> createState() => _ArtistInfoPageState();
}

class _ArtistInfoPageState extends State<ArtistInfoPage> {
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    fetchPlayList();
  }

  fetchPlayList() async {
    final myProvider = Provider.of<MyProvider>(
      context,
      listen: false,
    );
    try {
      setState(() {
        isLoading = true;
      });
      await myProvider.getArtistByid(widget.music);
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
    final artistInfo = myProvider.currentArtist;

    return DefaultTabController(
      length: 5,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text("Playlist"),
            ),
            body: ListView(
              primary: true,
              children: [
                if (widget.music.thumbnails.isNotEmpty) ...[
                  CarouselSlider.builder(
                    itemCount: widget.music.thumbnails.length,
                    options: CarouselOptions(
                      aspectRatio: 9 / 5,
                      autoPlay: true,
                    ),
                    itemBuilder: (context, itemIndex, pageViewIndex) {
                      final thumbnail = widget.music.thumbnails[itemIndex];
                      return CachedNetworkImage(
                        imageUrl: thumbnail.url ?? "",
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
                  "Artist: ${widget.music.artist?.name ?? artistInfo?.name ?? "NA"}",
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
                Divider(
                  color: Colors.grey.withOpacity(0.3),
                ),
                // Tab bar placed below the divider
                const TabBar(
                  indicatorColor: Colors.orange,
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Top Songs'),
                    Tab(text: 'Top Albums'),
                    Tab(text: 'Top Mix'),
                    Tab(text: 'Featured'),
                    Tab(text: 'Similar Artist'),
                  ],
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: TabBarView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      TopSongsTab(myProvider: myProvider),
                      TopAlbumsTab(myProvider: myProvider),
                      TopMix(
                        myProvider: myProvider,
                      ),
                      FeaturedTab(myProvider: myProvider),
                      SimilarArtistTab(
                        myProvider: myProvider,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

// Example tab content widgets
class TopSongsTab extends StatelessWidget {
  final MyProvider myProvider;
  const TopSongsTab({super.key, required this.myProvider});
  @override
  Widget build(BuildContext context) {
    final artistInfo = myProvider.currentArtist;
    return SingleChildScrollView(
      child: Column(
        children: [
          if (artistInfo!.topSongs.isNotEmpty)
            ...List.generate(
              artistInfo.topSongs.length,
              (index) {
                final song = artistInfo.topSongs[index];
                return ListTile(
                  minVerticalPadding: 10,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  title: Text(
                    song.name ?? "NA",
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
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
                  trailing: const Icon(
                    Icons.play_circle_fill_rounded,
                    size: 40,
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
                      myProvider.playlist = artistInfo.topSongs;
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
            )
          else ...[
            const Text(
              "Top Songs is Empty",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ],
      ),
    );
  }
}

class TopAlbumsTab extends StatelessWidget {
  const TopAlbumsTab({super.key, required this.myProvider});
  final MyProvider myProvider;

  @override
  Widget build(BuildContext context) {
    final artistInfo = myProvider.currentArtist;
    return SingleChildScrollView(
      child: Column(
        children: [
          if (artistInfo!.topAlbums.isNotEmpty)
            ...List.generate(
              artistInfo.topAlbums.length,
              (index) {
                final song = artistInfo.topAlbums[index];
                return ListTile(
                  minVerticalPadding: 10,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  title: Text(
                    song.name ?? "NA",
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
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
                  trailing: const Icon(
                    Icons.album_rounded,
                    size: 40,
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
            )
          else ...[
            const Text(
              "Album is Empty",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ],
      ),
    );
  }
}

class TopMix extends StatelessWidget {
  final MyProvider myProvider;

  const TopMix({super.key, required this.myProvider});

  @override
  Widget build(BuildContext context) {
    final artistInfo = myProvider.currentArtist;
    return SingleChildScrollView(
      child: Column(
        children: [
          if (artistInfo!.topVideos.isNotEmpty)
            ...List.generate(
              artistInfo.topVideos.length,
              (index) {
                final song = artistInfo.topVideos[index];
                return ListTile(
                  minVerticalPadding: 10,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  title: Text(
                    song.name ?? "NA",
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
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
                  trailing: const Icon(
                    Icons.play_circle_fill_rounded,
                    size: 40,
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
            )
          else ...[
            const Text(
              "Playlist is Empty",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ],
      ),
    );
  }
}

class FeaturedTab extends StatelessWidget {
  const FeaturedTab({super.key, required this.myProvider});
  final MyProvider myProvider;

  @override
  Widget build(BuildContext context) {
    final artistInfo = myProvider.currentArtist;
    return SingleChildScrollView(
      child: Column(
        children: [
          if (artistInfo!.featuredOn.isNotEmpty)
            ...List.generate(
              artistInfo.featuredOn.length,
              (index) {
                final song = artistInfo.featuredOn[index];
                return ListTile(
                  minVerticalPadding: 10,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  title: Text(
                    song.name ?? "NA",
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
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
                  trailing: const Icon(
                    Icons.play_circle_fill_rounded,
                    size: 40,
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
            )
          else ...[
            const Text(
              "Featured is Empty",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ],
      ),
    );
  }
}

class SimilarArtistTab extends StatelessWidget {
  const SimilarArtistTab({super.key, required this.myProvider});
  final MyProvider myProvider;

  @override
  Widget build(BuildContext context) {
    final artistInfo = myProvider.currentArtist;
    return SingleChildScrollView(
      child: Column(
        children: [
          if (artistInfo!.similarArtists.isNotEmpty)
            ...List.generate(
              artistInfo.similarArtists.length,
              (index) {
                final song = artistInfo.similarArtists[index];
                return ListTile(
                  minVerticalPadding: 10,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  title: Text(
                    song.name ?? "NA",
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
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
                  trailing: const Icon(
                    Icons.music_video,
                    size: 40,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArtistInfoPage(
                            music: song,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            )
          else ...[
            const Text(
              "No Similar Artist",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ],
      ),
    );
  }
}
