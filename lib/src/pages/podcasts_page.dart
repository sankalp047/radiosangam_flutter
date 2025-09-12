import 'package:flutter/material.dart';
import '../services/radio_service.dart';
import 'package:radiosangam_flutter/src/services/radio_service.dart';

class PodcastsPage extends StatelessWidget {
  const PodcastsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rjs = [
      RJ(
        name: 'Anuj',
        imageAsset: 'assets/images/rj_anuj.png',
        episodes: [
          Episode(
            id: 'anuj-01',
            title: 'Top Bollywood Hits – Sep 1',
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          ),
          Episode(
            id: 'anuj-02',
            title: 'Indie Hour – Aug 28',
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          ),
        ],
      ),
      RJ(
        name: 'Neha',
        imageAsset: 'assets/images/rj_neha.png',
        episodes: [
          Episode(
            id: 'neha-01',
            title: 'Retro Rewind – Sep 3',
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
          ),
          Episode(
            id: 'neha-02',
            title: 'Weekend Chill – Aug 26',
            url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
          ),
        ],
      ),
    ];

    final isWide = MediaQuery.of(context).size.width >= 700;
    final cross = isWide ? 3 : 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Podcasts')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rjs.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cross,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, i) => _RJTile(rj: rjs[i]),
      ),
    );
  }
}

class _RJTile extends StatelessWidget {
  final RJ rj;
  const _RJTile({required this.rj});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EpisodesPage(rj: rj)),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  rj.imageAsset,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                rj.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EpisodesPage extends StatelessWidget {
  final RJ rj;
  const EpisodesPage({super.key, required this.rj});

  @override
  Widget build(BuildContext context) {
    final radio = RadioService.instance;

    return Scaffold(
      appBar: AppBar(title: Text('${rj.name} • Episodes')),
      body: ListView.separated(
        itemCount: rj.episodes.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final ep = rj.episodes[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                rj.imageAsset,
                width: 56, height: 56, fit: BoxFit.cover,
              ),
            ),
            title: Text(ep.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Tap to play'),
            onTap: () async {
              await radio.playEpisode(
                id: ep.id,
                title: ep.title,
                url: ep.url,
                artAsset: rj.imageAsset,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Playing: ${ep.title}')),
                );
              }
            },
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () async {
                await radio.playEpisode(
                  id: ep.id,
                  title: ep.title,
                  url: ep.url,
                  artAsset: rj.imageAsset,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class RJ {
  final String name;
  final String imageAsset;
  final List<Episode> episodes;

  RJ({required this.name, required this.imageAsset, required this.episodes});
}

class Episode {
  final String id;
  final String title;
  final String url;

  Episode({required this.id, required this.title, required this.url});
}
