import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_music_tech/components/horizontal_slider.dart';
import 'package:the_music_tech/components/vertical_card.dart';
import 'package:the_music_tech/core/providers/my_provider.dart';

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
                    child: SizedBox(
                      height: 80,
                    ),
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
