// lib/src/pages/rj_pages.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:radiosangam_flutter/src/services/radio_service.dart';

/// ====== FEED URLS (fill the rest later) ======
const _feedMadhurima =
    'https://funasia-rss.streamguys1.com/funasia/rj-madhu-morning-show.json';

const _feedHyma = 'https://funasia-rss.streamguys1.com/funasia/rj-hyma-show.json';
const _feedYashini = 'https://funasia-rss.streamguys1.com/funasia/rj-yashini-show.json';
const _feedShravanthi = 'https://funasia-rss.streamguys1.com/funasia/rj-saravanthi-show.json';

const _feedMythri = 'https://funasia-rss.streamguys1.com/funasia/rj-mythri-show.json';
const _feedMadhurya = 'https://funasia-rss.streamguys1.com/funasia/rj-madhu-telangana-show.json';
const _feedDnr = 'https://funasia-rss.streamguys1.com/funasia/rj-dnr-show.json';
const _feedNaveen = 'https://funasia-rss.streamguys1.com/funasia/rj-naveen.json';
const _feedAkarsh = 'https://funasia-rss.streamguys1.com/funasia/rj-akarsh-show.json';
const _feedShailaja = 'https://funasia-rss.streamguys1.com/funasia/rj-shailaja-show.json';

/// ====== DATA MODEL ======
class PodcastEpisode {
  final String id;
  final String title;
  final String url;
  final String? artUrl;
  final DateTime? pubDate;

  PodcastEpisode({
    required this.id,
    required this.title,
    required this.url,
    this.artUrl,
    this.pubDate,
  });

  factory PodcastEpisode.fromJson(
      Map<String, dynamic> m, {
        int index = 0,
        String? channelArt,
      }) {
    String pickS(List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    String? pickImage() {
      // common keys + itunes:image + image.url
      final itunesImg = m['itunes:image'];
      if (itunesImg is String && itunesImg.isNotEmpty) return itunesImg;
      if (m['image'] is String && (m['image'] as String).isNotEmpty) {
        return m['image'] as String;
      }
      if (m['image'] is Map && (m['image']['url'] is String)) {
        return m['image']['url'] as String;
      }
      return channelArt;
    }

    DateTime? parseDate() {
      final s = pickS(['pubDate', 'date', 'published_at']);
      if (s.isEmpty) return null;
      try {
        return DateTime.tryParse(s) ?? DateTime.tryParse(s.replaceAll(',', ''));
      } catch (_) {
        return null;
      }
    }

    final title = pickS(['title', 'name', 'episode_title']).isNotEmpty
        ? pickS(['title', 'name', 'episode_title'])
        : 'Episode ${index + 1}';
    final url = pickS(['audio', 'audio_url', 'mp3', 'enclosure_url', 'stream', 'url']);

    return PodcastEpisode(
      id: (m['guid']?.toString().trim().isNotEmpty ?? false)
          ? m['guid'].toString()
          : url.hashCode.toString(),
      title: title,
      url: url,
      artUrl: pickImage(),
      pubDate: parseDate(),
    );
  }
}

/// Extract list no matter if it’s root array, {items:[]}, or {channel:{items:[]}}
List<dynamic> _extractEpisodeArray(dynamic root) {
  if (root is List) return root;
  if (root is Map<String, dynamic>) {
    // direct keys
    for (final k in ['items', 'episodes', 'data', 'results', 'list', 'podcasts']) {
      final v = root[k];
      if (v is List) return v;
    }
    // nested channel
    final ch = root['channel'];
    if (ch is Map<String, dynamic>) {
      for (final k in ['items', 'episodes']) {
        final v = ch[k];
        if (v is List) return v;
      }
    }
  }
  return const [];
}

String? _channelArt(dynamic root) {
  if (root is Map<String, dynamic>) {
    final ch = root['channel'];
    final map = (ch is Map<String, dynamic>) ? ch : root;
    final iImg = map['itunes:image'];
    if (iImg is String && iImg.isNotEmpty) return iImg;
    final img = map['image'];
    if (img is String && img.isNotEmpty) return img;
    if (img is Map && img['url'] is String) return img['url'] as String;
  }
  return null;
}

/// ====== GENERIC PAGE ======
class RjShowPage extends StatefulWidget {
  final String title;
  final String? timeRange; // optional (weekend)
  final String imageAsset; // local profile image
  final String feedUrl; // JSON endpoint

  const RjShowPage({
    super.key,
    required this.title,
    required this.imageAsset,
    required this.feedUrl,
    this.timeRange,
  });

  @override
  State<RjShowPage> createState() => _RjShowPageState();
}

class _RjShowPageState extends State<RjShowPage> {
  late Future<List<PodcastEpisode>> _episodesFuture;

  @override
  void initState() {
    super.initState();
    _episodesFuture = _fetchEpisodes(widget.feedUrl);
  }

  Future<List<PodcastEpisode>> _fetchEpisodes(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Feed responded with ${res.statusCode}');
    }
    final decoded = json.decode(res.body);
    final fallbackArt = _channelArt(decoded);
    final list = _extractEpisodeArray(decoded);

    final episodes = <PodcastEpisode>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is Map<String, dynamic>) {
        final ep = PodcastEpisode.fromJson(item, index: i, channelArt: fallbackArt);
        if (ep.url.isNotEmpty) episodes.add(ep);
      }
    }
    return episodes;
  }

  @override
  Widget build(BuildContext context) {
    final radio = RadioService.instance;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: .5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header (white background)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.imageAsset,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      if (widget.timeRange != null) ...[
                        const SizedBox(height: 6),
                        Text(widget.timeRange!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(.6),
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.radio),
                        label: const Text('Play Live'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          try {
                            await radio.playLive();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Playing live…')));
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Playback error: $e')));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),

            const SizedBox(height: 16),
            const Text('Podcasts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),

            FutureBuilder<List<PodcastEpisode>>(
              future: _episodesFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return _ErrorBox(
                    message: 'Couldn’t load podcasts.\n${snap.error}',
                    onRetry: () => setState(
                          () => _episodesFuture = _fetchEpisodes(widget.feedUrl),
                    ),
                  );
                }
                final episodes = snap.data ?? const <PodcastEpisode>[];
                if (episodes.isEmpty) {
                  return const _EmptyBox(message: 'No episodes found yet. Check back soon!');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: episodes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final ep = episodes[i];
                    final subtitle = ep.pubDate != null
                        ? _formatDate(ep.pubDate!)
                        : 'Tap to play';
                    return _EpisodeTile(
                      title: ep.title,
                      subtitle: subtitle,
                      artUrl: ep.artUrl,
                      onPlay: () async {
                        try {
                          await radio.playEpisode(
                            id: ep.id,
                            title: ep.title,
                            url: ep.url,
                            artUrl: ep.artUrl,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Playing: ${ep.title}')));
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Playback error: $e')));
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    // Simple readable date, e.g. "Fri, Sep 12, 2025"
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const m = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final wd = w[(d.weekday + 6) % 7];
    return '$wd, ${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

/// ====== UI bits ======
class _EpisodeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? artUrl;
  final VoidCallback onPlay;

  const _EpisodeTile({
    required this.title,
    required this.subtitle,
    required this.onPlay,
    this.artUrl,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Image.asset('assets/images/logo.png', fit: BoxFit.cover);

    return Material(
      color: Colors.white,
      elevation: 0.5,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: (artUrl == null || artUrl!.isEmpty)
                      ? placeholder
                      : Image.network(artUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => placeholder),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.black.withOpacity(.6), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.play_circle_fill, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(.2)),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String message;
  const _EmptyBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

/// ====== Weekday RJ pages ======
class MadhurimaPage extends StatelessWidget {
  const MadhurimaPage({super.key});
  @override
  Widget build(BuildContext context) => const RjShowPage(
    title: 'Madhurima',
    timeRange: '7:00 AM – 10:00 AM',
    imageAsset: 'assets/images/MadhuCover.png',
    feedUrl: _feedMadhurima,
  );
}

class HymaPage extends StatelessWidget {
  const HymaPage({super.key});
  @override
  Widget build(BuildContext context) => const RjShowPage(
    title: 'Hyma',
    timeRange: '11:00 AM – 2:00 PM',
    imageAsset: 'assets/images/hymaCover.png',
    feedUrl: _feedHyma,
  );
}

class YashiniPage extends StatelessWidget {
  const YashiniPage({super.key});
  @override
  Widget build(BuildContext context) => const RjShowPage(
    title: 'Yashini',
    timeRange: '2:00 PM – 5:00 PM',
    imageAsset: 'assets/images/yashiniCover.png',
    feedUrl: _feedYashini,
  );
}

class ShravanthiPage extends StatelessWidget {
  const ShravanthiPage({super.key});
  @override
  Widget build(BuildContext context) => const RjShowPage(
    title: 'Shravanthi',
    timeRange: '5:00 PM – 8:00 PM',
    imageAsset: 'assets/images/shravCover.png',
    feedUrl: _feedShravanthi,
  );
}

/// ====== Weekend RJ pages ======
class MythriPage extends StatelessWidget {
  const MythriPage({super.key});
  @override
  Widget build(BuildContext context) => const RjShowPage(
    title: 'Mythri',
    imageAsset: 'assets/images/Mythri_Cover.png',
    feedUrl: _feedMythri,
  );
}

class MadhuryaPage extends StatelessWidget {
  const MadhuryaPage({super.key});
  @override
  Widget build(BuildContext context) => const RjShowPage(
    title: 'Madhurya',
    imageAsset: 'assets/images/Madhu_T_Cover.png',
    feedUrl: _feedMadhurya,
  );
}

class DnrPage extends StatelessWidget {
  const DnrPage({super.key});
  @override
  Widget build(BuildContext context) => const RjShowPage(
    title: 'DNR',
    imageAsset: 'assets/images/DNR.png',
    feedUrl: _feedDnr,
  );
}

class NaveenPage extends StatelessWidget {
  const NaveenPage({super.key});
  @override
  Widget build(BuildContext context) => const RjShowPage(
    title: 'Naveen',
    imageAsset: 'assets/images/naveenCover.png',
    feedUrl: _feedNaveen,
  );
}

class AkarshPage extends StatelessWidget {
  const AkarshPage({super.key});
  @override
  Widget build(BuildContext context) => const RjShowPage(
    title: 'Akarsh',
    imageAsset: 'assets/images/akarsh_Cover.png',
    feedUrl: _feedAkarsh,
  );
}

class ShailajaPage extends StatelessWidget {
  const ShailajaPage({super.key});
  @override
  Widget build(BuildContext context) => const RjShowPage(
    title: 'Shailaja',
    imageAsset: 'assets/images/shailaja_Cover.png',
    feedUrl: _feedShailaja,
  );
}
