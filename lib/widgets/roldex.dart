// lib/widgets/rolodex_dob_picker.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef DobChanged = void Function(DateTime dob);

class RolodexDobPicker extends StatefulWidget {
  RolodexDobPicker({
    super.key,
    required this.initialDate,
    required this.onChanged,
    this.minYear = 1900,
    int? maxYear,
    this.height = 220,
    this.itemExtent = 48,
    this.backgroundColor = const Color(0xFFF2F2F2),
    this.highlightColor = const Color(0xFFE7E7E7),
    this.textStyle = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: Colors.black,
    ),
    this.fadedTextStyle = const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: Color(0xFFBDBDBD),
    ),
  }) : maxYear = maxYear ?? DateTime.now().year;

  /// Used only once on first build to initialize wheels.
  final DateTime initialDate;

  final DobChanged onChanged;

  final int minYear;
  final int maxYear;

  final double height;
  final double itemExtent;

  final Color backgroundColor;
  final Color highlightColor;

  final TextStyle textStyle;
  final TextStyle fadedTextStyle;

  @override
  State<RolodexDobPicker> createState() => _RolodexDobPickerState();
}

class _RolodexDobPickerState extends State<RolodexDobPicker> {
  static const _months = <String>[
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  late int _monthIndex; // 0..11
  late int _day; // 1..31
  late int _year;

  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _yearCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDate;

    _monthIndex = (d.month - 1).clamp(0, 11);
    _year = d.year.clamp(widget.minYear, widget.maxYear);

    final maxDay = _daysInMonth(_year, _monthIndex + 1);
    _day = d.day.clamp(1, maxDay);

    _monthCtrl = FixedExtentScrollController(initialItem: _monthIndex);
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    _yearCtrl =
        FixedExtentScrollController(initialItem: _year - widget.minYear);

    // Emit once after first layout (safe)
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) {
    final firstOfNext =
        (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return firstOfNext.subtract(const Duration(days: 1)).day;
  }

  void _clampDayAndSyncWheel() {
    final maxDay = _daysInMonth(_year, _monthIndex + 1);
    if (_day > maxDay) {
      _day = maxDay;
      _dayCtrl.jumpToItem(_day - 1);
    }
  }

  void _emit() {
    widget.onChanged(DateTime(_year, _monthIndex + 1, _day));
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required int selectedIndex,
    required ValueChanged<int> onSelectedItemChanged,
    required Widget Function(BuildContext, int, bool) itemBuilder,
    double? width,
  }) {
    return SizedBox(
      width: width,
      height: widget.height,
      child: CupertinoPicker.builder(
        scrollController: controller,
        itemExtent: widget.itemExtent,
        magnification: 1.12,
        useMagnifier: true,
        squeeze: 1.1,
        onSelectedItemChanged: onSelectedItemChanged,
        childCount: itemCount,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return Center(child: itemBuilder(context, index, isSelected));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yearCount = widget.maxYear - widget.minYear + 1;
    final dayCount = _daysInMonth(_year, _monthIndex + 1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: widget.backgroundColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  height: widget.itemExtent,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: widget.highlightColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _wheel(
                  width: 120,
                  controller: _monthCtrl,
                  itemCount: 12,
                  selectedIndex: _monthIndex,
                  onSelectedItemChanged: (i) {
                    setState(() {
                      _monthIndex = i;
                      _clampDayAndSyncWheel();
                    });
                    _emit();
                  },
                  itemBuilder: (_, i, selected) => Text(
                    _months[i],
                    style: selected ? widget.textStyle : widget.fadedTextStyle,
                  ),
                ),
                _wheel(
                  width: 80,
                  controller: _dayCtrl,
                  itemCount: dayCount,
                  selectedIndex: _day - 1,
                  onSelectedItemChanged: (i) {
                    setState(() => _day = i + 1);
                    _emit();
                  },
                  itemBuilder: (_, i, selected) => Text(
                    '${i + 1}',
                    style: selected ? widget.textStyle : widget.fadedTextStyle,
                  ),
                ),
                _wheel(
                  width: 110,
                  controller: _yearCtrl,
                  itemCount: yearCount,
                  selectedIndex: _year - widget.minYear,
                  onSelectedItemChanged: (i) {
                    setState(() {
                      _year = widget.minYear + i;
                      _clampDayAndSyncWheel();
                    });
                    _emit();
                  },
                  itemBuilder: (_, i, selected) => Text(
                    '${widget.minYear + i}',
                    style: selected ? widget.textStyle : widget.fadedTextStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
