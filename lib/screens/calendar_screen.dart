import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/hijri_utils.dart';
import '../models/event_model.dart';
import '../theme.dart';
import 'add_event_screen.dart';
import 'event_detail_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  HijriDate _selected = HijriDate.now();
  final ScrollController _timelineCtrl = ScrollController();


  bool _initFromRegion = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initFromRegion) {
      _selected = context.read<AppProvider>().today();
      _initFromRegion = true;
    }
  }

  @override
  void dispose() {
    _timelineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Column(
      children: [
        _header(p),
        _viewSwitcher(p),
        Expanded(child: _buildView(p)),
      ],
    );
  }

  Widget _header(AppProvider p) {
    final today = context.read<AppProvider>().today();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  p.isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.focusedHijri.monthName(p.language)} ${p.focusedHijri.year}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${_gregMonth(p.focusedGregorian.month, p.language)} ${p.focusedGregorian.year}',
                  style: const TextStyle(color: AppColors.text3, fontSize: 13),
                ),
              ],
            ),
          ),
          // Bouton "Aujourd'hui" — flèches retirées (swipe à la place)
          TextButton.icon(
            icon: const Icon(Icons.today, size: 18),
            label: Text(p.label('today')),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () {
              setState(() => _selected = today);
              p.setFocusedHijri(today);
            },
          ),
        ],
      ),
    );
  }

  Widget _viewSwitcher(AppProvider p) {
    final views = [
      CalendarView.monthly,
      CalendarView.weekly,
      CalendarView.agenda,
    ];
    final labels = ['view_monthly', 'view_weekly', 'view_agenda'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: List.generate(3, (i) {
            final selected = p.view == views[i];
            return Expanded(
              child: InkWell(
                onTap: () => p.setView(views[i]),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.green : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p.label(labels[i]),
                    style: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildView(AppProvider p) {
    switch (p.view) {
      case CalendarView.monthly:
        return _monthlyView(p);
      case CalendarView.weekly:
        return _weeklyView(p);
      case CalendarView.agenda:
        return _agendaView(p);
    }
  }

  // ============================================================
  // VUE MENSUELLE — swipe gauche/droite, points d'événements agrandis
  // ============================================================
  Widget _monthlyView(AppProvider p) {
    final h = p.focusedHijri;
    final dim = HijriDate.daysInMonth(h.year, h.month);
    final firstDay = HijriDate(h.year, h.month, 1).toGregorian();
    final firstWeekday = firstDay.weekday % 7; // Sunday=0
    final today = context.read<AppProvider>().today();

    return Column(
      children: [
        _weekdayHeader(p),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (d) {
              if (d.primaryVelocity == null) return;
              final dir = d.primaryVelocity! < 0 ? 1 : -1;
              p.setFocusedHijri(
                p.focusedHijri.addMonths(p.isRtl ? -dir : dir),
              );
            },
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 0.8,
              ),
              itemCount: 42,
              itemBuilder: (_, i) {
                final dayNum = i - firstWeekday + 1;
                if (dayNum < 1 || dayNum > dim) {
                  return const SizedBox.shrink();
                }
                final cellHijri = HijriDate(h.year, h.month, dayNum);
                final cellGreg = cellHijri.toGregorian();
                final isToday = cellHijri.isSameDay(today);
                final isSelected = cellHijri.isSameDay(_selected);
                final isFriday = cellGreg.weekday == DateTime.friday;
                final isWhiteDay = [13, 14, 15].contains(dayNum);
                final isRamadan = h.month == 9;
                final dayEvents = p.eventsForHijri(cellHijri);

                Color? bg;
                if (isWhiteDay) {
                  bg = AppColors.greenPale.withOpacity(0.4);
                }
                if (isRamadan) {
                  bg = AppColors.goldPale.withOpacity(0.5);
                }
                if (isToday) bg = AppColors.green;

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() => _selected = cellHijri);
                    p.setFocusedHijri(cellHijri);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected && !isToday
                            ? AppColors.green
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? Colors.white
                                : (isFriday ? AppColors.green : null),
                          ),
                        ),
                        Text(
                          '${cellGreg.day}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isToday
                                ? Colors.white70
                                : AppColors.text3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Points d'événements AGRANDIS (8px au lieu de 5px)
                        if (dayEvents.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayEvents
                                .take(3)
                                .map(
                                  (e) => Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1.5),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          isToday ? Colors.white : e.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _selectedDayEvents(p)),
      ],
    );
  }

  Widget _weekdayHeader(AppProvider p) {
    final names = p.language == 'ar'
        ? ['أحد', 'إثن', 'ثلا', 'أرب', 'خمس', 'جمعة', 'سبت']
        : (p.language == 'fr'
            ? ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
            : (p.language == 'es'
                ? ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb']
                : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: List.generate(
          7,
          (i) => Expanded(
            child: Center(
              child: Text(
                names[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: i == 5 ? AppColors.green : AppColors.text3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectedDayEvents(AppProvider p) {
    final events = p.eventsForHijri(_selected);
    final greg = _selected.toGregorian();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${_selected.day} ${_selected.monthName(p.language)} • ${greg.day}/${greg.month}/${greg.year}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Text(
                    p.label('no_events'),
                    style: const TextStyle(color: AppColors.text3),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: events.length,
                  itemBuilder: (_, i) => _eventTile(p, events[i]),
                ),
        ),
      ],
    );
  }

  Widget _eventTile(AppProvider p, AppEvent e) {
    final timeStr = e.hour != null
        ? '${e.hour!.toString().padLeft(2, '0')}:${(e.minute ?? 0).toString().padLeft(2, '0')}'
        : null;
    return Card(
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: e.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Row(
          children: [
            if (e.emoji.isNotEmpty)
              Text('${e.emoji} ', style: const TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                e.getTitle(p.language),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            // Badge Islamique / Personnel
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: e.isIslamic
                    ? AppColors.greenPale
                    : AppColors.bluePale,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e.isIslamic
                    ? p.label('badge_islamic')
                    : p.label('badge_personal'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: e.isIslamic ? AppColors.green : AppColors.blue,
                ),
              ),
            ),
          ],
        ),
        subtitle: timeStr != null
            ? Text(timeStr)
            : (e.description.isNotEmpty
                ? Text(e.description,
                    maxLines: 1, overflow: TextOverflow.ellipsis)
                : null),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EventDetailSheet(
            event: e,
            onEdit: () {
              if (!e.isIslamic) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEventScreen(existing: e),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VUE HEBDOMADAIRE — bande horizontale + timeline 24h
  // ============================================================
  Widget _weeklyView(AppProvider p) {
    final start =
        _selected.addDays(-(_selected.toGregorian().weekday % 7));
    return Column(
      children: [
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 7,
            itemBuilder: (_, i) {
              final d = start.addDays(i);
              final greg = d.toGregorian();
              final selected = d.isSameDay(_selected);
              final today = d.isSameDay(context.read<AppProvider>().today());
              return GestureDetector(
                onTap: () => setState(() => _selected = d),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.green
                        : (today ? AppColors.greenPale : null),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : null,
                        ),
                      ),
                      Text(
                        '${greg.day}/${greg.month}',
                        style: TextStyle(
                          fontSize: 10,
                          color: selected
                              ? Colors.white70
                              : AppColors.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _timeline(p)),
      ],
    );
  }

  Widget _timeline(AppProvider p) {
    final events = p.eventsForHijri(_selected);
    final timed = events.where((e) => e.hour != null).toList();
    final allDay = events.where((e) => e.hour == null).toList();
    final now = TimeOfDay.now();
    final isToday = _selected.isSameDay(context.read<AppProvider>().today());
    const slotHeight = 60.0; // hauteur d'une heure

    return SingleChildScrollView(
      controller: _timelineCtrl,
      child: Column(
        children: [
          if (allDay.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: AppColors.greenPale.withOpacity(0.3),
              child: Column(
                children: allDay
                    .map(
                      (e) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              color: e.color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${e.emoji} ${e.getTitle(p.language)}'
                                    .trim(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          SizedBox(
            height: slotHeight * 24,
            child: Stack(
              children: [
                // Lignes horaires
                Column(
                  children: List.generate(24, (h) {
                    return SizedBox(
                      height: slotHeight,
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 50,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 4, right: 6),
                              child: Text(
                                '${h.toString().padLeft(2, '0')}:00',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.text3),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      color: AppColors.border
                                          .withOpacity(0.5)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                // Blocs d'événements
                ...timed.map((e) {
                  final top = (e.hour! + (e.minute ?? 0) / 60.0) *
                      slotHeight;
                  final endH = e.endHour ?? (e.hour! + 1);
                  final endM = e.endMinute ?? (e.minute ?? 0);
                  final dur =
                      ((endH + endM / 60.0) - (e.hour! + (e.minute ?? 0) / 60.0))
                          .clamp(0.5, 24.0);
                  return Positioned(
                    top: top,
                    left: 54,
                    right: 8,
                    height: dur * slotHeight - 4,
                    child: GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            EventDetailSheet(event: e, onEdit: () {}),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: e.color.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(color: e.color, width: 4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.emoji} ${e.getTitle(p.language)}'
                                  .trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${e.hour!.toString().padLeft(2, '0')}:${(e.minute ?? 0).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                // Ligne rouge "maintenant" (uniquement si _selected = aujourd'hui)
                if (isToday)
                  Positioned(
                    top: (now.hour + now.minute / 60.0) * slotHeight,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 2,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VUE AGENDA — liste chronologique groupée par date
  // ============================================================
  Widget _agendaView(AppProvider p) {
    final today = context.read<AppProvider>().today();
    final upcomingDays = <HijriDate>[];
    for (int i = 0; i < 60; i++) {
      final d = today.addDays(i);
      if (p.eventsForHijri(d).isNotEmpty) upcomingDays.add(d);
    }
    if (upcomingDays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy,
                size: 64, color: AppColors.text3),
            const SizedBox(height: 12),
            Text(
              p.label('no_events'),
              style: const TextStyle(color: AppColors.text3),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: upcomingDays.length,
        itemBuilder: (_, i) {
          final d = upcomingDays[i];
          final greg = d.toGregorian();
          final events = p.eventsForHijri(d);
          final isToday = d.isSameDay(today);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de date "collant" visuellement
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.green
                      : AppColors.greenPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${d.day} ${d.monthName(p.language)} ${d.year} • ${greg.day}/${greg.month}/${greg.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.white : AppColors.green,
                  ),
                ),
              ),
              ...events.map((e) => _eventTile(p, e)),
            ],
          );
        },
      ),
    );
  }

  String _gregMonth(int m, String lang) {
    const en = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const fr = [
      'Jan','Fév','Mar','Avr','Mai','Juin',
      'Juil','Août','Sep','Oct','Nov','Déc'
    ];
    const ar = [
      'يناير','فبراير','مارس','أبريل','مايو','يونيو',
      'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'
    ];
    const es = [
      'Ene','Feb','Mar','Abr','May','Jun',
      'Jul','Ago','Sep','Oct','Nov','Dic'
    ];
    switch (lang) {
      case 'ar': return ar[m - 1];
      case 'fr': return fr[m - 1];
      case 'es': return es[m - 1];
      default: return en[m - 1];
    }
  }
}
