import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:dm1/models/stats_data.dart';

class HistoryCalendar extends StatefulWidget {
  final Map<DateTime, List<DrivingStats>> historyData;
  final void Function(DateTime selectedDay) onDaySelected;

  const HistoryCalendar({
    super.key,
    required this.historyData,
    required this.onDaySelected,
  });

  @override
  State<HistoryCalendar> createState() => _HistoryCalendarState();
}

class _HistoryCalendarState extends State<HistoryCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: TableCalendar<DrivingStats>(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now(),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

        // 给有记录的日期打标记
        eventLoader: (day) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          return widget.historyData[normalizedDay] ?? [];
        },

        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          widget.onDaySelected(selectedDay);
        },

        calendarStyle: CalendarStyle(
          markerSize: 6,
          markerDecoration: const BoxDecoration(
            color: Color.fromARGB(255, 19, 36, 135), 
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.orange.withAlpha(45), 
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color.fromARGB(255, 6, 44, 125), 
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        daysOfWeekStyle: const DaysOfWeekStyle(
          weekendStyle: TextStyle(color: Colors.red),
        ),

        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }
}
