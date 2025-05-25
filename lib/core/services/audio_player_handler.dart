import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioPlayerHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  // Playlist of audio sources
  late final List<AudioSource> _playlist;

  List<AudioSource> get playlist => _playlist;

  AudioPlayerHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());

    // Listen to playback events and pipe them to playbackState
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Update current media item on index change
    _player.currentIndexStream.listen((index) {
      if (index != null && index < _playlist.length) {
        final tag = (_playlist[index] as ProgressiveAudioSource).tag;
        if (tag is MediaItem) {
          mediaItem.add(tag);
        }
      }
    });

    _player.durationStream.listen((duration) {
      final index = _player.currentIndex;
      if (duration != null && index != null && index < _playlist.length) {
        final source = _playlist[index] as ProgressiveAudioSource;
        final tag = source.tag;
        if (tag is MediaItem) {
          final updated = tag.copyWith(duration: duration);
          mediaItem.add(updated); // This will trigger the MediaItem stream.
        }
      }
    });

    // Initialize queue with empty list
    queue.add([]);
  }

  // Load playlist of songs
  Future<void> loadPlaylist(List<AudioSource> list) async {
    _playlist =
        list; /* [
      AudioSource.uri(
        Uri.parse(
            "https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3"),
        tag: MediaItem(
          id: "1",
          title: "Kalimba",
          artist: "Artist 1",
          artUri: Uri.parse(
              "https://i.pinimg.com/236x/5c/05/ae/5c05ae623ade949fb687423608f6ba45.jpg"),
        ),
      ),
      AudioSource.uri(
        Uri.parse("https://www.sample-videos.com/audio/mp3/crowd-cheering.mp3"),
        tag: MediaItem(
          id: "2",
          title: "Crowd Cheering",
          artist: "Artist 2",
          artUri: Uri.parse(
              "https://i.pinimg.com/236x/5c/05/ae/5c05ae623ade949fb687423608f6ba45.jpg"),
        ),
      ),
    ];
*/
    await _player.setAudioSources(_playlist);

    // Update queue with media items extracted from playlist
    queue.add(
      _playlist
          .map((source) => (source as ProgressiveAudioSource).tag as MediaItem)
          .toList(),
    );

    // Set current mediaItem initially
    if (_playlist.isNotEmpty) {
      mediaItem.add((_playlist[0] as ProgressiveAudioSource).tag as MediaItem);
    }
  }

  Future<void> addToPlaylist(AudioSource newSource) async {
    _playlist.add(newSource);

    // Add to the player sequence (assuming you initialized the player with setAudioSources)
    await _player.insertAudioSource(_player.sequence.length, newSource);

    // Add corresponding MediaItem to the queue stream
    final mediaItemTag = (newSource as ProgressiveAudioSource).tag as MediaItem;
    final updatedQueue = List<MediaItem>.from(queue.value)..add(mediaItemTag);
    queue.add(updatedQueue);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: [0, 1, 3],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex, // Important for notification buttons!
    );
  }

  @override
  Future<void> play() {
    print('play() called');
    return _player.play();
  }

  @override
  Future<void> pause() {
    print('pause() called');
    return _player.pause();
  }

  @override
  Future<void> stop() {
    print('stop() called');
    return _player.stop();
  }

  @override
  Future<void> seek(Duration position) {
    print('seek() called: $position');
    return _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    print('skipToNext() called');
    final sequence = _player.sequence;
    final currentIndex = _player.currentIndex ?? 0;
    final nextIndex = currentIndex + 1;
    if (sequence != null && nextIndex < sequence.length) {
      await _player.seek(Duration.zero, index: nextIndex);
      await play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    print('skipToPrevious() called');
    final sequence = _player.sequence;
    final currentIndex = _player.currentIndex ?? 0;
    final prevIndex = currentIndex - 1;
    if (sequence != null && prevIndex >= 0) {
      await _player.seek(Duration.zero, index: prevIndex);
      await play();
    }
  }

  Future<void> setAudioSource(AudioSource source) async {
    print('setAudioSource() called');
    await _player.setAudioSource(source);
  }
}
