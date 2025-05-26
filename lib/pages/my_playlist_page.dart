import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_music_tech/core/providers/my_provider.dart';
import 'package:the_music_tech/pages/playlist_info_page.dart';

class MyPlaylistPage extends StatelessWidget {
  const MyPlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final myProvider = Provider.of<MyProvider>(context);
    final currentPlaylist = myProvider.currentPlayList;
    final activePlaylist = myProvider.playlist;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My PlayList"),
      ),
      body: Column(
        children: [
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
                      currentPlaylist?.name ?? "NA",
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
          ] else
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
      ),
    );
  }
}
