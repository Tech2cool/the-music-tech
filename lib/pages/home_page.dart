import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_music_tech/components/horizontal_slider.dart';
import 'package:the_music_tech/components/vertical_card.dart';
import 'package:the_music_tech/core/models/models/search_model.dart';
import 'package:the_music_tech/core/providers/my_provider.dart';

List<List<SearchModel>> chunkList(List<SearchModel> list, int chunkSize) {
  List<List<SearchModel>> chunks = [];
  for (var i = 0; i < list.length; i += chunkSize) {
    int end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
    chunks.add(list.sublist(i, end));
  }
  return chunks;
}

const List<String> suggestionHeadings = [
  "Suggested for You",
  "Recommended for You",
  "Just for You",
  "Top Picks",
  "Based on Your Taste",
  "You Might Like",
  "Because You Listened To...",
  "Your Personalized Mix",
  "Inspired by Your History",
  "For Your Ears Only",
  "Today's Picks",
  "Discover Something New",
  "Curated for You",
  "Fresh Recommendations",
  "Listen Again",
  "Keep the Vibe Going",
  "Handpicked for You",
  "Your Daily Picks",
  "Up Next",
  "Don't Miss These",
  "New Beats for You",
  "Trending in Your Genre",
  "From Artists You Follow",
  "Your Audio Feed",
  "Songs You Might Love",
  "Explore More Like This",
  "What’s Hot Right Now",
  "Start Here",
  "You May Have Missed",
  "Keep Exploring",
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;

  Future<void> onRefresh() async {
    try {
      setState(() {
        isLoading = true;
      });
      final myProvider = Provider.of<MyProvider>(
        context,
        listen: false,
      );
      await Future.wait([
        myProvider.getHomeSuggestion(),
        myProvider.getMyPlayList(),
        myProvider.getAllSuggestedList(),
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
    super.initState();
    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final myProvider = Provider.of<MyProvider>(context);
    final homeData = myProvider.homeResults;
    final suggested = myProvider.suggestedAll;
    final splicedSuggested = chunkList(suggested, 10);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Home"),
          ),
          body: RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...List.generate(splicedSuggested.length, (i) {
                    final record = splicedSuggested[i];
                    return HorizontalSlider(
                      title: suggestionHeadings[i],
                      childrens: [
                        ...List.generate(record.length, (i2) {
                          final record2 = record[i2];

                          return VerticalCard(
                            item: record2,
                            list: record,
                          );
                        }),
                      ],
                    );
                  }),
                  ...List.generate(homeData.length, (i) {
                    final record = homeData[i];
                    return HorizontalSlider(
                      title: record.title ?? "NA",
                      childrens: [
                        ...List.generate(record.contents.length, (i2) {
                          final record2 = record.contents[i2];

                          return VerticalCard(
                            item: record2,
                            list: record.contents,
                          );
                        }),
                      ],
                    );
                  }),
                  SafeArea(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withAlpha(100),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}
