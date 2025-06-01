import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_music_tech/core/models/models/search_model.dart';
import 'package:the_music_tech/core/providers/my_provider.dart';
import 'package:the_music_tech/pages/album_info_page.dart';
import 'package:the_music_tech/pages/artist_info_page.dart';
import 'package:the_music_tech/pages/music_player_page.dart';
import 'package:the_music_tech/pages/playlist_info_page.dart';

class VerticalCard extends StatelessWidget {
  final SearchModel item;
  final List<SearchModel> list;

  const VerticalCard({
    super.key,
    required this.item,
    required this.list,
  });

  @override
  Widget build(BuildContext context) {
    final myProvider = Provider.of<MyProvider>(context);

    final thumbnail = item.thumbnails.isNotEmpty
        ? item.thumbnails.length > 1
            ? item.thumbnails[1].url
            : item.thumbnails[0].url
        : null;
    return GestureDetector(
      onTap: () {
        if (item.type == "PLAYLIST") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayListInfoPage(
                music: item,
              ),
            ),
          );
        } else if (item.type == "ARTIST") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistInfoPage(
                music: item,
              ),
            ),
          );
        } else if (item.type == "ALBUM") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlbumInfoPage(
                music: item,
              ),
            ),
          );
        } else {
          myProvider.playlist = list;
          // myProvider.currentIndex = index;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MusicPlayerPage(
                music: item,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10, top: 5, bottom: 5),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: thumbnail ?? "",
              width: 120,
              fit: BoxFit.fitHeight,
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(100)),
                  ],
                ),
                child: Text(
                  item.type,
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
