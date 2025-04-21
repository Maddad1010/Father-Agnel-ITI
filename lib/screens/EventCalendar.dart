// ignore_for_file: unused_field, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class EventCalendar extends StatefulWidget {
  const EventCalendar({super.key});

  @override
  _EventCalendarState createState() => _EventCalendarState();
}

class _EventCalendarState extends State<EventCalendar> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<dynamic>> _events = {};
  List<dynamic> _monthEvents = [];
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = _focusedDay.year;
    _selectedMonth = _focusedDay.month;
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection('events').get();
      setState(() {
        _events = {
          for (var doc in snapshot.docs)
            DateTime.parse(doc['date']): [doc['title']],
        };
        _loadMonthEvents(_focusedDay);
      });
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  void _loadMonthEvents(DateTime focusedDay) {
    final startOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final endOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);

    setState(() {
      _monthEvents = _events.entries
          .where((entry) =>
              entry.key
                  .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              entry.key.isBefore(endOfMonth.add(const Duration(days: 1))))
          .toList();
    });
  }

  void _createEvent(DateTime date) {
    showDialog(
      context: context,
      builder: (context) {
        String title = '';
        String username = '';
        String password = '';

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            'Create Event',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView( // Make the content scrollable
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) => title = value,
                  decoration: const InputDecoration(
                    hintText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (value) => username = value,
                  decoration: const InputDecoration(
                    hintText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (value) => password = value,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                backgroundColor: const Color(0xFF305CDE),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (await _authenticateAdmin(username, password)) {
                  await FirebaseFirestore.instance.collection('events').add({
                    'title': title,
                    'date': date.toIso8601String(),
                  });
                  _fetchEvents();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event added successfully!')),
                  );
                }
              },
              child: const Text('Add Event'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _authenticateAdmin(String username, String password) async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection('admins').get();
      for (var doc in snapshot.docs) {
        if (doc['username'] == username && doc['pass'] == password) {
          return true;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password!')),
      );
      return false;
    } catch (e) {
      print('Error during authentication: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication failed!')),
      );
      return false;
    }
  }

  void _showYearMonthPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: _selectedYear,
                items: List.generate(
                  10,
                  (index) => DropdownMenuItem(
                    value: _selectedYear - 5 + index,
                    child: Text((_selectedYear - 5 + index).toString()),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value!;
                    _focusedDay = DateTime(_selectedYear, _selectedMonth, 1);
                    _loadMonthEvents(_focusedDay);
                    Navigator.of(context).pop();
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButton<int>(
                value: _selectedMonth,
                items: List.generate(
                  12,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text(DateFormat.MMM().format(DateTime(0, index + 1))),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedMonth = value!;
                    _focusedDay = DateTime(_selectedYear, _selectedMonth, 1);
                    _loadMonthEvents(_focusedDay);
                    Navigator.of(context).pop();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF305CDE),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _showYearMonthPicker,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                leftChevronVisible: true,
                rightChevronVisible: true,
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekendStyle: TextStyle(color: Colors.redAccent),
                weekdayStyle: TextStyle(fontSize: 12), // Adjust font size
              ),
              daysOfWeekHeight: 30, // Adjust height
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                  _loadMonthEvents(focusedDay);
                });
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
                _createEvent(selectedDay);
              },
              eventLoader: (date) => _events[date] ?? [],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _monthEvents.isEmpty
                ? const Center(
                    child: Text(
                      'No events this month.',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _monthEvents.length,
                    itemBuilder: (context, index) {
                      final eventDate = _monthEvents[index].key;
                      final eventTitle = _monthEvents[index].value[0];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${DateFormat.yMMMd().format(eventDate)} - $eventTitle',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}