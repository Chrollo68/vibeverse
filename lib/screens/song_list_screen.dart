import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'player_screen.dart';

enum SortOption { recentlyAdded, alphabetical }

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> songs = [];
  SortOption _currentSort = SortOption.recentlyAdded;

  @override
  void initState() {
    super.initState();
    requestPermissionsAndLoadSongs();
  }

  Future<void> requestPermissionsAndLoadSongs() async {
    bool granted = false;

    if (await Permission.audio.request().isGranted) {
      granted = true;
    } else if (await Permission.storage.request().isGranted) {
      granted = true;
    }

    if (!mounted) return;

    if (granted) {
      loadSongs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied. Closing app...')),
      );
      Future.delayed(const Duration(seconds: 2), () {
        SystemNavigator.pop();
      });
    }
  }

  Future<void> loadSongs() async {
    final fetchedSongs = await _audioQuery.querySongs(
      sortType: _currentSort == SortOption.recentlyAdded
          ? SongSortType.DATE_ADDED
          : SongSortType.TITLE,
      orderType: _currentSort == SortOption.recentlyAdded
          ? OrderType.DESC_OR_GREATER
          : OrderType.ASC_OR_SMALLER,
    );

    setState(() => songs = fetchedSongs);
  }

  void toggleSort() {
    setState(() {
      _currentSort = _currentSort == SortOption.recentlyAdded
          ? SortOption.alphabetical
          : SortOption.recentlyAdded;
    });
    loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentSort == SortOption.recentlyAdded
              ? "Songs (Recently Added)"
              : "Songs (A–Z)",
        ),
        actions: [
          IconButton(
            icon: Icon(_currentSort == SortOption.recentlyAdded
                ? Icons.sort_by_alpha
                : Icons.access_time),
            tooltip: "Toggle Sort",
            onPressed: toggleSort,
          )
        ],
      ),
      body: songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  leading: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    nullArtworkWidget: const Icon(Icons.music_note, size: 40),
                  ),
                  title: Text(song.title, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist ?? "Unknown Artist"),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        songs: songs,
                        currentIndex: index,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
