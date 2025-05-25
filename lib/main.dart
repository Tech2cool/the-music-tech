import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:the_music_tech/core/providers/my_provider.dart';
import 'package:the_music_tech/wrapper/home_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final myProvider = MyProvider();
  await myProvider.init(myProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: myProvider),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // final AudioHandler audioHandler;

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeWrapper(),
      theme: ThemeData(
        primarySwatch: Colors.orange,
        brightness: Brightness.dark,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myProvider = Provider.of<MyProvider>(context);
    final audioHandler = myProvider.audioHandler;

    return Scaffold(
      appBar: AppBar(title: const Text("Music App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final playing = state?.playing ?? false;
                return IconButton(
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    playing ? audioHandler.pause() : audioHandler.play();
                  },
                  iconSize: 64,
                );
              },
            ),
            ElevatedButton(
              onPressed: () async {
                // Call your handler's method to load the playlist
                await audioHandler.loadPlaylist([]);
                await audioHandler.play();
              },
              child: const Text("Load & Play"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Call your handler's method to load the playlist
                await audioHandler.addToPlaylist(
                  AudioSource.uri(
                    Uri.parse(
                        "https://github.com/ShivamJoker/sample-songs/blob/master/Bad%20Liar.mp3"),
                    tag: MediaItem(
                      id: "3",
                      title: "Bar Liar",
                      artist: "Artist 3",
                      artUri: Uri.parse(
                          "https://i.pinimg.com/236x/5c/05/ae/5c05ae623ade949fb687423608f6ba45.jpg"),
                    ),
                  ),
                );
              },
              child: const Text("add new Song to list"),
            ),
          ],
        ),
      ),
    );
  }
}
