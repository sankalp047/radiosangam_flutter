import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'podcasts_page.dart';
import 'package:radiosangam_flutter/src/services/radio_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final radio = RadioService.instance;

  void _openFullPlayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _FullPlayerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).padding;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radio Sangam', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: 'Podcasts',
            icon: const Icon(Icons.podcasts),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PodcastsPage())),
          )
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 120 + inset.bottom),
            children: [
              const _AnnouncementBox(
                message: 'New shows live this week! Tap to view schedule.',
                urlHint: 'https://radiosangam.example/schedule',
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Suggested Playlists',
                onAction: () {}, // hook later if needed
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 170,
                child: _PlaylistRow(
                  items: _demoPlaylists,
                  onTap: (p) {
                    // navigate to a playlist screen later
                  },
                ),
              ),
              const SizedBox(height: 20),
              _SectionHeader(
                title: 'Back to Favorites',
                onAction: () {},
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 170,
                child: _PlaylistRow(
                  items: _demoPlaylistsFavs,
                  onTap: (p) {},
                ),
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Recommended For You',
                actionIcon: Icons.play_circle_rounded,
                onAction: () async {
                  try {
                    await radio.playLive();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Playing recommendations… (live)')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Playback error: $e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              ..._demoTracks.mapIndexed((i, t) => _SongRow(
                title: t.title,
                subtitle: t.artist,
                leadingAsset: t.artAsset,
                isFirst: i == 0,
                isLast: i == _demoTracks.length - 1,
                onPlay: () async {
                  try {
                    await radio.playEpisode(
                      id: 'rec-$i',
                      title: t.title,
                      url: t.demoUrl,
                      artAsset: t.artAsset,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Playback error: $e')),
                      );
                    }
                  }
                },
              )),
            ],
          ),
          // Mini player stuck to bottom — tap or swipe up arrow to expand
          Align(
            alignment: Alignment.bottomCenter,
            child: _MiniPlayer(onExpand: _openFullPlayer),
          ),
        ],
      ),
    );
  }
}

/* ---------- Widgets (clean-room, no GPL code) ---------- */

class _AnnouncementBox extends StatelessWidget {
  final String message;
  final String? urlHint;
  const _AnnouncementBox({required this.message, this.urlHint});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: urlHint == null ? null : () {/* open url later */},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.campaign_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              if (urlHint != null) const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionIcon, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (onAction != null)
          IconButton(
            icon: Icon(actionIcon ?? Icons.chevron_right_rounded),
            onPressed: onAction,
          ),
      ],
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  final List<_Playlist> items;
  final void Function(_Playlist) onTap;
  const _PlaylistRow({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (_, i) {
        final p = items[i];
        return InkWell(
          onTap: () => onTap(p),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.asset(p.artAsset, width: 150, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemCount: items.length,
    );
  }
}

class _SongRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String leadingAsset;
  final bool isFirst, isLast;
  final VoidCallback onPlay;
  const _SongRow({
    required this.title,
    required this.subtitle,
    required this.leadingAsset,
    required this.onPlay,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(isFirst ? 12 : 0),
        bottom: Radius.circular(isLast ? 12 : 0),
      ),
      side: const BorderSide(color: Colors.black12),
    );
    return Material(
      shape: shape,
      color: Colors.white,
      child: InkWell(
        onTap: onPlay,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(leadingAsset, width: 48, height: 48, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.play_arrow_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

/* Mini player + full player */

class _MiniPlayer extends StatelessWidget {
  final VoidCallback onExpand;
  const _MiniPlayer({required this.onExpand});

  @override
  Widget build(BuildContext context) {
    final radio = RadioService.instance;
    return Material(
      elevation: 14,
      color: Colors.white,
      child: InkWell(
        onTap: onExpand,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            height: 68,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/images/logo.png', width: 46, height: 46, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Radio Sangam – Live',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                StreamBuilder<PlayerState>(
                  stream: radio.playerStateStream,
                  builder: (context, snap) {
                    final playing = snap.data?.playing ?? false;
                    final processing = snap.data?.processingState;
                    final busy = processing == ProcessingState.loading ||
                        processing == ProcessingState.buffering;
                    return Row(
                      children: [
                        IconButton(
                          tooltip: 'Expand',
                          icon: const Icon(Icons.keyboard_arrow_up_rounded),
                          onPressed: onExpand,
                        ),
                        IconButton(
                          tooltip: playing ? 'Pause' : 'Play',
                          icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill),
                          onPressed: busy ? null : () async {
                            try { await (playing ? radio.pause() : radio.playLive()); }
                            catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playback error: $e'))); }
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullPlayerSheet extends StatelessWidget {
  const _FullPlayerSheet();

  @override
  Widget build(BuildContext context) {
    final radio = RadioService.instance;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            Center(
              child: Container(width: 52, height: 5,
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(99))),
            ),
            const SizedBox(height: 16),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/images/logo.png', width: 280, height: 280, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Radio Sangam – Live',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Streaming now',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            StreamBuilder<PlayerState>(
              stream: radio.playerStateStream,
              builder: (context, snap) {
                final playing = snap.data?.playing ?? false;
                final processing = snap.data?.processingState;
                final busy = processing == ProcessingState.loading ||
                    processing == ProcessingState.buffering;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Stop',
                      iconSize: 34,
                      icon: const Icon(Icons.stop_circle_outlined),
                      onPressed: () async { try { await radio.stop(); } catch (_) {} },
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton.icon(
                      onPressed: busy ? null : () async {
                        try { await (playing ? radio.pause() : radio.playLive()); }
                        catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playback error: $e'))); }
                      },
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      label: Text(playing ? 'Pause' : 'Play'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      tooltip: 'Close',
                      iconSize: 34,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/* ---------- demo data (replace with real API later) ---------- */

class _Playlist {
  final String title;
  final String artAsset;
  const _Playlist(this.title, this.artAsset);
}

class _Track {
  final String title;
  final String artist;
  final String artAsset;
  final String demoUrl;
  const _Track(this.title, this.artist, this.artAsset, this.demoUrl);
}

// Put matching images under assets/images/ and register in pubspec.yaml
const _demoPlaylists = <_Playlist>[
  _Playlist('Morning Drive', 'assets/images/logo.png'),
  _Playlist('Retro Rewind', 'assets/images/logo.png'),
  _Playlist('Punjabi Party', 'assets/images/logo.png'),
  _Playlist('Indie Hour', 'assets/images/logo.png'),
];

const _demoPlaylistsFavs = <_Playlist>[
  _Playlist('Your Likes', 'assets/images/logo.png'),
  _Playlist('Chillout', 'assets/images/logo.png'),
  _Playlist('Top Bollywood', 'assets/images/logo.png'),
];

extension _MapIndexed<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int i, E e) f) {
    var i = 0; return map((e) => f(i++, e));
  }
}

const _demoTracks = <_Track>[
  _Track('Top Bollywood Hits – Sep 1', 'RJ Anuj', 'assets/images/logo.png',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
  _Track('Retro Rewind – Sep 3', 'RJ Neha', 'assets/images/logo.png',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'),
  _Track('Weekend Chill – Aug 26', 'RJ Neha', 'assets/images/logo.png',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3'),
];
