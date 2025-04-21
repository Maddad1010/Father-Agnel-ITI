import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './custom_drawer.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String studentName = "";
  String course = "";
  String rollNumber = "";
  String contactNumber = "";

  List<String> months = [
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
    'December'
  ];

  String? selectedMonth;
  Map<String, List<String>> attendanceData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');

    if (username != null) {
      try {
        DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('username', isEqualTo: username)
            .limit(1)
            .get()
            .then((QuerySnapshot querySnapshot) => querySnapshot.docs.first);

        setState(() {
          studentName = studentSnapshot['Name'];
          course = studentSnapshot['Course'];
          rollNumber = studentSnapshot['RollNo'].toString();
          contactNumber = studentSnapshot['PhNo'].toString();
        });
        await fetchAttendanceData(studentName, selectedMonth);
      } catch (error) {
        print("Error fetching data: $error");
      }
    }
  }

  Future<void> fetchAttendanceData(String name, String? month) async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance_data')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (attendanceSnapshot.docs.isNotEmpty) {
        var attendanceDoc = attendanceSnapshot.docs.first;
        List<String> presentDates = List.from(attendanceDoc['presentDates']);
        List<String> absentDates = List.from(attendanceDoc['absentDates']);

        attendanceData['Present Dates'] = presentDates;
        attendanceData['Absent Dates'] = absentDates;
      } else {
        attendanceData = {'Present Dates': [], 'Absent Dates': []};
      }
      setState(() {
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching attendance data: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile Page',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF305CDE),
        elevation: 0,
      ),
      drawer: const CustomDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF305CDE),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile Information',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF305CDE),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        _buildProfileDetail('Name', studentName),
                        _buildProfileDetail('Roll No', rollNumber),
                        _buildProfileDetail('Phone No', contactNumber),
                        _buildProfileDetail('Course', course),
                        const SizedBox(height: 30.0),
                        DropdownButton<String>(
                          hint: const Text(
                            'Select Month',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          value: selectedMonth,
                          isExpanded: true,
                          onChanged: (String? newValue) async {
                            setState(() {
                              selectedMonth = newValue;
                            });
                            await fetchAttendanceData(studentName, selectedMonth);
                          },
                          items: months
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20.0),
                        if (isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          _buildAttendanceDetails(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 5.0),
          Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDetails() {
    List<String> datesInMonth = [];
    int monthIndex =
        selectedMonth != null ? months.indexOf(selectedMonth!) + 1 : 0;

    if (monthIndex > 0) {
      int currentYear = DateTime.now().year;

      for (int day = 1; day <= 31; day++) {
        String date =
            '$currentYear-${monthIndex.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        if (attendanceData['Present Dates']!.contains(date)) {
          datesInMonth.add('$date: Present');
        } else if (attendanceData['Absent Dates']!.contains(date)) {
          datesInMonth.add('$date: Absent');
        } else {
          datesInMonth.add('$date: Not Taken Attendance');
        }
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: datesInMonth.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            datesInMonth[index],
            style: const TextStyle(fontSize: 16.0, color: Colors.black87),
          ),
        );
      },
    );
  }
}
