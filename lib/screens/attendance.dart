import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  AttendancePageState createState() => AttendancePageState();
}

class AttendancePageState extends State<AttendancePage> {
  List<Map<String, dynamic>> _students = [];
  Map<String, bool>? _attendanceStatus;
  String _selectedCourse = 'Mechanic Motor Vehicle (MMV)';
  final DateTime _currentDate = DateTime.now();
  bool _isLoading = false;

  final Map<String, String> _courseShortForms = {
    'Mechanic Motor Vehicle (MMV)': 'MMV',
    'Fitter (FT)': 'FT',
    'Refrigeration & Air-conditioning Technician (RACT)': 'RACT',
    'Electrician (ET)': 'ET',
    'Information and Communication Technology System Maintenance (ICTSM)': 'ICTSM',
  };

  @override
  void initState() {
    super.initState();
    _attendanceStatus = {};
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('students').get();
      List<Map<String, dynamic>> loadedStudents = [];
      String selectedCourseShortForm = _courseShortForms[_selectedCourse] ?? '';

      for (var doc in snapshot.docs) {
        var studentData = doc.data() as Map<String, dynamic>;
        if (studentData['Course'] == selectedCourseShortForm) {
          loadedStudents.add({
            'id': doc.id,
            'rollNumber': studentData['RollNo'].toString(),
            'name': studentData['Name'],
            'course': studentData['Course'],
            'phNo': studentData['PhNo'],
          });
        }
      }

      loadedStudents.sort((a, b) {
        int rollA = int.tryParse(a['rollNumber']) ?? 0;
        int rollB = int.tryParse(b['rollNumber']) ?? 0;
        return rollA.compareTo(rollB);
      });

      setState(() {
        _students = loadedStudents;
        _attendanceStatus = {for (var student in loadedStudents) student['id']: false};
      });
    } catch (e) {
      print('Error loading students: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load students')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleAttendance(String studentId) {
    setState(() {
      if (_attendanceStatus != null && _attendanceStatus!.containsKey(studentId)) {
        _attendanceStatus![studentId] = !_attendanceStatus![studentId]!;
      }
    });
  }

  Future<void> _saveAttendance() async {
    try {
      final String dateKey = _currentDate.toIso8601String().split("T").first;
      List<String> presentStudents = [];
      List<String> absentStudents = [];

      for (var student in _students) {
        if (student['id'] != null && _attendanceStatus != null) {
          bool isPresent = _attendanceStatus![student['id']] ?? false;

          if (isPresent) {
            presentStudents.add(student['name']);
          } else {
            absentStudents.add(student['name']);
          }

          QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
              .collection('attendance_data')
              .where('rollNo', isEqualTo: student['rollNumber'])
              .where('course', isEqualTo: _selectedCourse)
              .get();

          if (attendanceSnapshot.docs.isNotEmpty) {
            String existingDocId = attendanceSnapshot.docs.first.id;
            Map<String, dynamic> attendanceData = attendanceSnapshot.docs.first.data() as Map<String, dynamic>;

            List<String> absentDates = List<String>.from(attendanceData['absentDates'] ?? []);
            List<String> presentDates = List<String>.from(attendanceData['presentDates'] ?? []);

            if (isPresent) {
              if (!presentDates.contains(dateKey)) {
                presentDates.add(dateKey);
              }
              absentDates.remove(dateKey);
            } else {
              if (!absentDates.contains(dateKey)) {
                absentDates.add(dateKey);
              }
              presentDates.remove(dateKey);
            }

            await FirebaseFirestore.instance.collection('attendance_data').doc(existingDocId).update({
              'presentDates': presentDates,
              'absentDates': absentDates,
            });
          } else {
            Map<String, dynamic> attendanceRecord = {
              'course': _selectedCourse,
              'rollNo': student['rollNumber'],
              'name': student['name'],
              'presentDates': isPresent ? [dateKey] : [],
              'absentDates': !isPresent ? [dateKey] : [],
            };
            await FirebaseFirestore.instance.collection('attendance_data').add(attendanceRecord);
          }
        }
      }

      _showAttendanceSummary(presentStudents, absentStudents);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully')),
      );

      setState(() {
        _attendanceStatus?.clear();
      });
    } catch (e) {
      print('Error saving attendance data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save attendance')),
      );
    }
  }

  Future<void> _downloadAttendance() async {
    var excel = Excel.createExcel();
    var sheet = excel['Attendance'];
    sheet.appendRow(['Course: $_selectedCourse']);
    sheet.appendRow(['Roll Number', 'Name', 'Dates Present', 'Dates Absent', 'Attendance %']);

    for (var student in _students) {
      Set<String> presentDates = {};
      Set<String> absentDates = {};

      var attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance_data')
          .where('rollNo', isEqualTo: student['rollNumber'])
          .where('course', isEqualTo: _selectedCourse)
          .get();

      for (var entry in attendanceSnapshot.docs) {
        Map<String, dynamic> attendanceData = entry.data();

        List<String> present = List<String>.from(attendanceData['presentDates'] ?? []);
        List<String> absent = List<String>.from(attendanceData['absentDates'] ?? []);

        presentDates.addAll(present);
        absentDates.addAll(absent);
      }

      int totalDays = presentDates.length + absentDates.length;
      int presentCount = presentDates.length;

      String attendancePercent = totalDays == 0 ? 'N/A' : '${((presentCount / totalDays) * 100).toStringAsFixed(2)}%';
      sheet.appendRow([
        student['rollNumber'],
        student['name'],
        presentDates.join(', '),
        absentDates.join(', '),
        attendancePercent,
      ]);
    }

    final directory = Directory('/storage/emulated/0/Download');
    final String filePath = '${directory.path}/attendance_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final File file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attendance downloaded to $filePath')),
    );
  }

  void _showAttendanceSummary(List<String> presentStudents, List<String> absentStudents) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Attendance Summary'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Present Students:'),
                ...presentStudents.map((name) => Text(name)),
                const SizedBox(height: 10),
                const Text('Absent Students:'),
                ...absentStudents.map((name) => Text(name)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Page'),
        backgroundColor: const Color(0xFF305CDE),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            DropdownButton<String>(
  value: _selectedCourse,
  onChanged: (newValue) {
    if (newValue != null) {
      setState(() {
        _selectedCourse = newValue;
      });
      _loadStudents();
    }
  },
  isExpanded: true,
  dropdownColor: Colors.white, // Set background color for dropdown items
  items: _courseShortForms.keys.map((course) {
    return DropdownMenuItem(
      value: course,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0), // Add padding
        child: Text(
          course,
          style: const TextStyle(
            fontSize: 16, // Increase font size for better readability
          ),
        ),
      ),
    );
  }).toList(),
),


            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    var student = _students[index];
                    return ListTile(
                      title: Text('${student['rollNumber']} - ${student['name']}'),
                      subtitle: Text('Contact: ${student['phNo']}'),
                      trailing: Switch(
                        value: _attendanceStatus?[student['id']] ?? false,
                        onChanged: (value) {
                          _toggleAttendance(student['id']!);
                        },
                      ),
                    );
                  },
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: ElevatedButton(
                    onPressed: _saveAttendance,
                    child: const Text('Save Attendance'),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton(
                    onPressed: _downloadAttendance,
                    child: const Text('Download Attendance'),
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
