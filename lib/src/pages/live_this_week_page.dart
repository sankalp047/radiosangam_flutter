// lib/src/pages/live_this_week_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// =============================
/// JSONBin setup
/// =============================
/// 1) Create a Bin at jsonbin.io and make it "Public (READ)" or keep it Private.
/// 2) Put the JSON from the sample we made into the Bin.
/// 3) Replace <BIN_ID> below with your bin id.
/// 4) If private, put your X-Master-Key into [_jsonBinKey].
const String _jsonBinUrl = 'https://api.jsonbin.io/v3/b/68c63131d0ea881f407d30a7/latest?meta=false';
const String? _jsonBinKey = null;

// If you prefer a raw JSON URL (e.g., GitHub raw), set this and make _jsonBinUrl empty.
const String _rawJsonUrl = '';

class DaySchedule {
  final String day;
  final List<ProgramSlot> slots;
  DaySchedule({required this.day, required this.slots});

  factory DaySchedule.fromJson(Map<String, dynamic> m) => DaySchedule(
    day: (m['day'] as String).toLowerCase(),
    slots: (m['slots'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ProgramSlot.fromJson)
        .toList(),
  );
}

class ProgramSlot {
  final TimeOfDay start;
  final TimeOfDay end;
  final List<String> hosts;
  final String? title;

  ProgramSlot({
    required this.start,
    required this.end,
    required this.hosts,
    this.title,
  });

  factory ProgramSlot.fromJson(Map<String, dynamic> m) => ProgramSlot(
    start: _parseTime(m['start'] as String),
    end: _parseTime(m['end'] as String),
    hosts: (m['hosts'] is List)
        ? (m['hosts'] as List).map((e) => e.toString()).toList()
        : [(m['hosts'] ?? '').toString()],
    title: (m['title'] as String?)?.trim(),
  );
}

class LiveThisWeekPage extends StatefulWidget {
  const LiveThisWeekPage({super.key});

  @override
  State<LiveThisWeekPage> createState() => _LiveThisWeekPageState();
}

class _LiveThisWeekPageState extends State<LiveThisWeekPage>
    with TickerProviderStateMixin {
  late Future<List<DaySchedule>> _future;

  // FIX 1: implement this helper (Mon=0..Sun=6)
  int _selectedIndex = _weekdayIndex(DateTime.now().weekday);

  @override
  void initState() {
    super.initState();
    _future = _loadSchedule();
  }

  Future<List<DaySchedule>> _loadSchedule() async {
    http.Response res;
    if (_rawJsonUrl.isNotEmpty) {
      res = await http.get(Uri.parse(_rawJsonUrl));
    } else {
      final headers = <String, String>{};
      if (_jsonBinKey != null) headers['X-Master-Key'] = _jsonBinKey!;
      res = await http.get(Uri.parse(_jsonBinUrl), headers: headers);
    }
    if (res.statusCode != 200) {
      throw Exception('Schedule fetch failed (${res.statusCode})');
    }
    final root = json.decode(res.body);
    final data =
    (root is Map && root['record'] != null) ? root['record'] : root;

    final week = (data['week'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(DaySchedule.fromJson)
        .toList();

    week.sort((a, b) => _dayOrder(a.day).compareTo(_dayOrder(b.day)));
    return week;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<DaySchedule>>(
        future: _future,
        builder: (context, snap) {
          final slivers = <Widget>[];

          slivers.add(const _FancyHeader(
            title: "This Week's Schedule",
            subtitle: "Live & on-air slots",
          ));

          if (snap.connectionState == ConnectionState.waiting) {
            slivers.add(const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
            ));
          } else if (snap.hasError) {
            slivers.add(SliverToBoxAdapter(
              child: _ErrorBox(
                message: 'Could not load schedule.\n${snap.error}',
                onRetry: () => setState(() => _future = _loadSchedule()),
              ),
            ));
          } else {
            final week = snap.data!;
            _selectedIndex = _selectedIndex.clamp(0, week.length - 1);

            // Day selector
            slivers.add(SliverToBoxAdapter(
              child: _DaySelector(
                days: week.map((e) => _prettyDay(e.day)).toList(),
                selected: _selectedIndex,
                onChanged: (i) => setState(() => _selectedIndex = i),
              ),
            ));

            // FIX 2: remove SliverAnimatedSwitcher (it doesn't exist)
            final selected = week[_selectedIndex];
            slivers.add(SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              sliver: _DaySliver(
                key: ValueKey(selected.day),
                schedule: selected,
                accent: theme.colorScheme.primary,
              ),
            ));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _loadSchedule());
              await _future;
            },
            color: Colors.black,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: slivers,
            ),
          );
        },
      ),
    );
  }
}

class _FancyHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _FancyHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 160,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E1E1E), Color(0xFF3C3C3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .2,
                        )),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      titleTextStyle: const TextStyle(color: Colors.black),
      foregroundColor: Colors.black,
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<String> days;
  final int selected;
  final ValueChanged<int> onChanged;
  const _DaySelector(
      {required this.days, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isToday = (String label) =>
    label.toLowerCase() == _prettyDay(_todayKey()).toLowerCase();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < days.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    isToday(days[i]) ? '${days[i]} · Today' : days[i],
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  selected: i == selected,
                  onSelected: (_) => onChanged(i),
                  selectedColor: Colors.black,
                  labelStyle: TextStyle(
                    color: i == selected ? Colors.white : Colors.black,
                  ),
                  backgroundColor: Colors.black.withOpacity(.06),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DaySliver extends StatelessWidget {
  final DaySchedule schedule;
  final Color accent;
  const _DaySliver({super.key, required this.schedule, required this.accent});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _dayKey(now.weekday) == schedule.day;

    final slots = [...schedule.slots]
      ..sort((a, b) => _toMinutes(a.start).compareTo(_toMinutes(b.start)));

    return SliverList.builder(
      itemCount: slots.length,
      itemBuilder: (context, i) {
        final s = slots[i];
        final live = isToday && _isNowInRange(now, s.start, s.end);
        final progress = live ? _rangeProgress(now, s.start, s.end) : null;
        return _SlotCard(
          slot: s,
          live: live,
          progress: progress,
          accent: accent,
        );
      },
    );
  }
}

class _SlotCard extends StatefulWidget {
  final ProgramSlot slot;
  final bool live;
  final double? progress;
  final Color accent;

  const _SlotCard(
      {required this.slot, required this.live, required this.progress, required this.accent});

  @override
  State<_SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<_SlotCard> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 350))
      ..forward();
    _slide = Tween(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.slot;
    final hostText = s.hosts.join(' & ');
    final title = s.title ?? hostText;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    _AvatarStack(names: s.hosts),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (widget.live)
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('LIVE',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11)),
                                ),
                              if (widget.live) const SizedBox(width: 8),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hostText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black.withOpacity(.65),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 16, color: Colors.black.withOpacity(.5)),
                              const SizedBox(width: 6),
                              Text(
                                '${_fmt(s.start)} – ${_fmt(s.end)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black.withOpacity(.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (widget.progress != null) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: widget.progress!.clamp(0, 1),
                                minHeight: 6,
                                color: widget.accent,
                                backgroundColor: Colors.black.withOpacity(.07),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<String> names;
  const _AvatarStack({required this.names});

  @override
  Widget build(BuildContext context) {
    final items = names.take(2).toList();
    return SizedBox(
      width: items.length == 1 ? 46 : 60,
      height: 46,
      child: Stack(
        children: [
          for (int i = 0; i < items.length; i++)
            Positioned(
              left: i * 26.0,
              child: _RjAvatar(name: items[i]),
            ),
        ],
      ),
    );
  }
}

class _RjAvatar extends StatelessWidget {
  final String name;
  const _RjAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final asset = _imageFor(name);
    if (asset != null && asset.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(asset, width: 46, height: 46, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

/// ===== Helpers =====
TimeOfDay _parseTime(String s) {
  final t = s.trim().toLowerCase().replaceAll(' ', '');
  final am = t.endsWith('am');
  final pm = t.endsWith('pm');
  String core = (am || pm) ? t.substring(0, t.length - 2) : t;

  int h, m;
  if (core.contains(':')) {
    final p = core.split(':');
    h = int.parse(p[0]);
    m = int.parse(p[1]);
  } else {
    h = int.parse(core);
    m = 0;
  }
  if (am && h == 12) h = 0;
  if (pm && h < 12) h += 12;
  return TimeOfDay(hour: h, minute: m);
}

int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
bool _isNowInRange(DateTime now, TimeOfDay start, TimeOfDay end) {
  final mins = now.hour * 60 + now.minute;
  return mins >= _toMinutes(start) && mins < _toMinutes(end);
}

double _rangeProgress(DateTime now, TimeOfDay start, TimeOfDay end) {
  final mins = now.hour * 60 + now.minute;
  final s = _toMinutes(start).toDouble();
  final e = _toMinutes(end).toDouble();
  if (mins <= s) return 0;
  if (mins >= e) return 1;
  return (mins - s) / (e - s);
}

String _fmt(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final mm = t.minute.toString().padLeft(2, '0');
  final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$h:$mm $suffix';
}

int _dayOrder(String d) {
  const order = {
    'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4,
    'friday': 5, 'saturday': 6, 'sunday': 7,
  };
  return order[d.toLowerCase()] ?? 99;
}

String _prettyDay(String d) => d[0].toUpperCase() + d.substring(1).toLowerCase();

String _dayKey(int weekday) {
  const keys = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
  return keys[(weekday - 1).clamp(0, 6)];
}

String _todayKey() => _dayKey(DateTime.now().weekday);

// FIX 1 helper
int _weekdayIndex(int weekday) => (weekday - 1).clamp(0, 6);

String? _imageFor(String name) {
  const map = {
    'Madhurima': 'assets/images/MadhuCover.png',
    'Hyma': 'assets/images/hymaCover.png',
    'Yashini': 'assets/images/yashiniCover.png',
    'Shravanthi': 'assets/images/shravCover.png',
    'Geethika': 'assets/images/logo.png',
    'Mythri': 'assets/images/Mythri_Cover.png',
    'Shailaja': 'assets/images/shailaja_Cover.png',
    'Shilaja': 'assets/images/shailaja_Cover.png',
    'Naveen': 'assets/images/naveenCover.png',
    'Kishore': 'assets/images/logo.png',
    'Nani': 'assets/images/logo.png',
    'DNR': 'assets/images/DNR.png',
    'Madhu': 'assets/images/Madhu_T_Cover.png',
    'Akarsh': 'assets/images/akarsh_Cover.png',
    'Akshya': 'assets/images/logo.png',
    'Madhurya': 'assets/images/Madhu_T_Cover.png',
  };
  return map[name.trim()];
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(.2)),
        ),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
