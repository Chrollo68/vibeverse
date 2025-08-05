import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';

class PlayerScreen extends StatefulWidget {
  final List<SongModel> songs;
  final int currentIndex;

  const PlayerScreen({
    super.key,
    required this.songs,
    required this.currentIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  late int _currentIndex;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _player = AudioPlayer();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 1.0,
      upperBound: 1.3,
    )..repeat(reverse: true);
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        nextSong();
      }
    });
    playSong();
  }

  void playSong() async {
    final song = widget.songs[_currentIndex];

    if (song.uri == null) {
      debugPrint("Invalid song URI");
      return;
    }

    try {
      await _player.stop();
      await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
      await _player.play();
      setState(() {});
    } catch (e) {
      debugPrint("Error playing song: $e");
    }
  }

  void nextSong() {
    if (_currentIndex < widget.songs.length - 1) {
      _currentIndex++;
      playSong();
    }
  }

  void previousSong() {
    if (_currentIndex > 0) {
      _currentIndex--;
      playSong();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.songs[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSong.title),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _glowController.value,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Colors.orange, Colors.deepPurple],
                          center: Alignment.center,
                          radius: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withValues(),
                            blurRadius: 30 * _glowController.value,
                            spreadRadius: 10 * _glowController.value,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: QueryArtworkWidget(
                    id: currentSong.id,
                    type: ArtworkType.AUDIO,
                    artworkHeight: 250,
                    artworkWidth: 250,
                    artworkFit: BoxFit.cover,
                    nullArtworkWidget: const Icon(Icons.music_note, size: 150),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                currentSong.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                currentSong.artist ?? "Unknown Artist",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  controlButton(Icons.skip_previous, previousSong),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing ?? false;
                      return controlButton(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        () => isPlaying ? _player.pause() : _player.play(),
                        size: 64,
                      );
                    },
                  ),
                  controlButton(Icons.skip_next, nextSong),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget controlButton(IconData icon, VoidCallback onPressed,
      {double size = 48}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        iconSize: size,
        color: Colors.white,
      ),
    );
  }
}
