import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<DateTime?> showDobPicker(BuildContext context, {DateTime? initialDate}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => DobPickerSheet(initialDate: initialDate),
  );
}

const Color _kPrimaryRed = Color(0xFFE53935);
const Color _kTextDark = Color(0xFF0F172A);
const Color _kTextMuted = Color(0xFF64748B);
const Color _kTextDisabled = Color(0xFFCBD5E1);
const Color _kBorderColor = Color(0xFFE2E8F0);
const Color _kBgLight = Color(0xFFF8FAFC);

const List<String> _kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _kWeekdays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

const int _kMinYear = 1900;

class DobPickerSheet extends StatefulWidget {
  final DateTime? initialDate;

  const DobPickerSheet({super.key, this.initialDate});

  @override
  State<DobPickerSheet> createState() => _DobPickerSheetState();
}

class _DobPickerSheetState extends State<DobPickerSheet> {
  late final DateTime _today;
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);

    if (widget.initialDate != null) {
      final initial = widget.initialDate!;
      if (!initial.isAfter(_today) && initial.year >= _kMinYear) {
        _selectedYear = initial.year;
        _selectedMonth = initial.month;
        _selectedDay = initial.day;
      } else {
        _setDefaultDate();
      }
    } else {
      _setDefaultDate();
    }

    _clampDaySafely();
  }

  void _setDefaultDate() {
    final defaultYear = (_today.year - 18).clamp(_kMinYear, _today.year);
    _selectedYear = defaultYear;
    _selectedMonth = 1;
    _selectedDay = 1;
  }

  void _clampDaySafely() {
    final maxDays = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    if (_selectedDay > maxDays) {
      _selectedDay = maxDays;
    }
    if (_selectedDay < 1) {
      _selectedDay = 1;
    }

    if (_selectedYear == _today.year && _selectedMonth == _today.month) {
      if (_selectedDay > _today.day) {
        _selectedDay = _today.day;
      }
    }
  }

  bool get _canGoPreviousMonth {
    if (_selectedYear > _kMinYear) return true;
    return _selectedMonth > 1;
  }

  bool get _canGoNextMonth {
    if (_selectedYear < _today.year) return true;
    return _selectedMonth < _today.month;
  }

  void _previousMonth() {
    if (!_canGoPreviousMonth) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedMonth == 1) {
        _selectedYear--;
        _selectedMonth = 12;
      } else {
        _selectedMonth--;
      }
      _clampDaySafely();
    });
  }

  void _nextMonth() {
    if (!_canGoNextMonth) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedMonth == 12) {
        _selectedYear++;
        _selectedMonth = 1;
      } else {
        _selectedMonth++;
      }
      _clampDaySafely();
    });
  }

  void _openMonthPicker() async {
    HapticFeedback.lightImpact();
    final int? pickedMonth = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MonthSelectionSheet(
        selectedYear: _selectedYear,
        selectedMonth: _selectedMonth,
        maxYear: _today.year,
        maxMonth: _today.month,
      ),
    );

    if (pickedMonth != null && mounted) {
      setState(() {
        _selectedMonth = pickedMonth;
        _clampDaySafely();
      });
    }
  }

  void _openYearPicker() async {
    HapticFeedback.lightImpact();
    final int? pickedYear = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _YearSelectionSheet(
        selectedYear: _selectedYear,
        minYear: _kMinYear,
        maxYear: _today.year,
      ),
    );

    if (pickedYear != null && mounted) {
      setState(() {
        _selectedYear = pickedYear;

        if (_selectedYear == _today.year && _selectedMonth > _today.month) {
          _selectedMonth = _today.month;
        }
        _clampDaySafely();
      });
    }
  }

  void _onConfirm() {
    HapticFeedback.mediumImpact();
    final result = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset > 0 ? 12 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: _kBorderColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Date of Birth",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _kTextDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Select your date of birth",
                          style: TextStyle(
                            fontSize: 13,
                            color: _kTextMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pop(null),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: _kBgLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: _kTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: _SelectableField(
                              label: "Month",
                              value: _kMonthNames[_selectedMonth - 1],
                              onTap: _openMonthPicker,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: _SelectableField(
                              label: "Year",
                              value: "$_selectedYear",
                              onTap: _openYearPicker,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _kBgLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kBorderColor, width: 0.8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              color: _canGoPreviousMonth
                                  ? _kTextDark
                                  : _kTextDisabled,
                              splashRadius: 20,
                              onPressed: _canGoPreviousMonth
                                  ? _previousMonth
                                  : null,
                            ),
                            Text(
                              "${_kMonthNames[_selectedMonth - 1]} $_selectedYear",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _kTextDark,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded),
                              color: _canGoNextMonth
                                  ? _kTextDark
                                  : _kTextDisabled,
                              splashRadius: 20,
                              onPressed: _canGoNextMonth ? _nextMonth : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      _CalendarDayGrid(
                        year: _selectedYear,
                        month: _selectedMonth,
                        selectedDay: _selectedDay,
                        today: _today,
                        onDaySelected: (day) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedDay = day;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Confirm Button (always pinned and accessible)
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  child: const Text("Confirm"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SelectableField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorderColor, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _kPrimaryRed,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayGrid extends StatelessWidget {
  final int year;
  final int month;
  final int selectedDay;
  final DateTime today;
  final ValueChanged<int> onDaySelected;

  const _CalendarDayGrid({
    required this.year,
    required this.month,
    required this.selectedDay,
    required this.today,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final firstWeekday = DateTime(year, month, 1).weekday;
    final leadingEmpty = firstWeekday - 1;
    final totalCells = leadingEmpty + daysInMonth;

    return Column(
      children: [
        Row(
          children: _kWeekdays.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTextMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.15,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            if (index < leadingEmpty) {
              return const SizedBox.shrink();
            }

            final day = index - leadingEmpty + 1;
            final isSelected = day == selectedDay;

            final bool isFuture =
                (year == today.year &&
                    month == today.month &&
                    day > today.day) ||
                (year == today.year && month > today.month) ||
                (year > today.year);

            final bool isToday =
                (year == today.year &&
                month == today.month &&
                day == today.day);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isFuture ? null : () => onDaySelected(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _kPrimaryRed
                      : isToday
                      ? const Color(0xFFFEE2E2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: _kPrimaryRed, width: 1.2)
                      : null,
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x40E53935),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    "$day",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isFuture
                          ? _kTextDisabled
                          : isToday
                          ? _kPrimaryRed
                          : _kTextDark,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MonthSelectionSheet extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final int maxYear;
  final int maxMonth;

  const _MonthSelectionSheet({
    required this.selectedYear,
    required this.selectedMonth,
    required this.maxYear,
    required this.maxMonth,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset > 0 ? 12 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: _kBorderColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Month",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kTextDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final isSelected = month == selectedMonth;
                  final isFuture =
                      (selectedYear == maxYear && month > maxMonth);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isFuture
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop(month);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kPrimaryRed
                            : isFuture
                            ? _kBgLight
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _kPrimaryRed : _kBorderColor,
                          width: isSelected ? 0 : 1.2,
                        ),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: Color(0x35E53935),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _kMonthNames[index].substring(0, 3),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : isFuture
                                ? _kTextDisabled
                                : _kTextDark,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearSelectionSheet extends StatefulWidget {
  final int selectedYear;
  final int minYear;
  final int maxYear;

  const _YearSelectionSheet({
    required this.selectedYear,
    required this.minYear,
    required this.maxYear,
  });

  @override
  State<_YearSelectionSheet> createState() => _YearSelectionSheetState();
}

class _YearSelectionSheetState extends State<_YearSelectionSheet> {
  late final ScrollController _scrollController;
  late final List<int> _years;

  @override
  void initState() {
    super.initState();

    _years = List.generate(
      widget.maxYear - widget.minYear + 1,
      (i) => widget.maxYear - i,
    );

    final selectedIndex = _years.indexOf(widget.selectedYear);

    final initialOffset =
        (selectedIndex >= 0 ? selectedIndex * 52.0 - 100 : 0.0).clamp(
          0.0,
          double.infinity,
        );

    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset > 0 ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: _kBorderColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select Year",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kTextDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: _years.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: _kBorderColor),
                  itemBuilder: (context, index) {
                    final year = _years[index];
                    final isSelected = year == widget.selectedYear;

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      title: Text(
                        "$year",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected ? _kPrimaryRed : _kTextDark,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: _kPrimaryRed,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop(year);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
