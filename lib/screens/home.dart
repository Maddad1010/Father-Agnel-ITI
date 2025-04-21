import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './login.dart';
import './attendance.dart';
import './ShowResult.dart';
import './profile.dart';
import 'curriculum.dart';
import 'EventCalendar.dart';
import 'NoticeBoard.dart';
import 'custom_drawer.dart';
import 'classroom.dart';
import 'package:marquee/marquee.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String studentName = "";
  String course = "";
  String rollNumber = "";
  String contactNumber = "";
  bool isLoading = true;
  bool isInitialized = false;

  List<String> _announcements = [];

  @override
  void initState() {
    super.initState();
    print('InitState called');
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await Future.wait([
        fetchStudentData(),
        fetchAllAnnouncements(),
      ]);
      setState(() {
        isInitialized = true;
        isLoading = false;
      });
    } catch (e) {
      print('Initialization error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchStudentData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');
      
      if (username == null) {
        setState(() {
          isLoading = false;  // Make sure to set loading to false
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginWidget()),
        );
        return;
      }
  
      // Query students collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
  
      if (querySnapshot.docs.isEmpty) {
        print("No student found with username: $username");
        setState(() {
          isLoading = false;
        });
        return;
      }
  
      final studentSnapshot = querySnapshot.docs.first;
      
      setState(() {
        studentName = studentSnapshot['Name'] ?? '';
        course = studentSnapshot['Course'] ?? '';
        rollNumber = studentSnapshot['RollNo']?.toString() ?? '';
        contactNumber = studentSnapshot['PhNo']?.toString() ?? '';
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching data: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAllAnnouncements() async {
    try {
      DateTime now = DateTime.now();
      String today = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Fetch from Notices collection where the date is greater than or equal to today
      final noticeQuery = await FirebaseFirestore.instance
          .collection('notices')
          .where('date', isGreaterThanOrEqualTo: today) // Filter by date
          .orderBy('date', descending: true) // Order by date descending
          .limit(5) // Limit to the latest 5 notices
          .get();

      // Fetch from Events collection where the date is greater than or equal to today
      final eventQuery = await FirebaseFirestore.instance
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: today) // Filter by date
          .orderBy('date', descending: true) // Order by date descending
          .limit(5) // Limit to the latest 5 events
          .get();

      List<String> tempAnnouncements = [];

      // Process notices
      for (var doc in noticeQuery.docs) {
        try {
          final data = doc.data();
          String formattedDate = _formatDate(data['date']);
          String announcement = '📢 Notice: $formattedDate - ${data['title']}: ${data['content']}';
          tempAnnouncements.add(announcement);
        } catch (e) {
          print('Error processing notice document: $e');
        }
      }

      // Process events
      for (var doc in eventQuery.docs) {
        try {
          final data = doc.data();
          String formattedDate = _formatDate(data['date']);
          String announcement = '📅 Event: $formattedDate - ${data['title']}';
          tempAnnouncements.add(announcement);
        } catch (e) {
          print('Error processing event document: $e');
        }
      }

      setState(() {
        _announcements = tempAnnouncements;
      });

    } catch (error) {
      print('Error fetching announcements: $error');
      setState(() {
        _announcements = [];
      });
    }
  }

  String _formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      print('Error formatting date: $e');
      return date; // Return the original date string if parsing fails
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginWidget()),
    );
  }

  Future<void> _navigateToAttendancePage() async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Admin Login'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String username = usernameController.text;
                String password = passwordController.text;

                try {
                  DocumentSnapshot adminSnapshot = await FirebaseFirestore
                      .instance
                      .collection('admins')
                      .where('username', isEqualTo: username)
                      .where('pass', isEqualTo: password)
                      .limit(1)
                      .get()
                      .then((QuerySnapshot querySnapshot) =>
                          querySnapshot.docs.first);

                  if (adminSnapshot.exists) {
                    Navigator.of(context).pop(); // Close the dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AttendancePage()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Invalid username or password')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Invalid username or password')),
                  );
                }
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String getCurrentDate() {
    DateTime now = DateTime.now();
    return DateFormat('dd-MM-yyyy').format(now);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    if (!isInitialized && isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Home Page',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF305CDE),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        drawer: CustomDrawer(logoutCallback: _logout),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildScrollingAnnouncement(), // Ensure this line is here
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildStudentCard(screenWidth),
                              const SizedBox(height: 20),
                              _buildExploreSection(screenWidth),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildBottomNavBar(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 4.0,
            color: Colors.grey,
            offset: Offset(0.0, 2.0),
          ),
        ],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50.0),
            child: Image.asset(
              'assets/studentsLogo.jpg',
              width: screenWidth * 0.18,
              height: screenWidth * 0.18,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            studentName,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            course,
            style: TextStyle(fontSize: screenWidth * 0.045),
          ),
          Text(
            'Roll No: $rollNumber',
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
          Text(
            'Contact: $contactNumber',
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreSection(double screenWidth) {
    return Column(
      children: [
        Text(
          'Explore',
          style: TextStyle(
            fontSize: screenWidth * 0.07,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          children: [
            _buildIconButton(
                'assets/eventcalendarlogo.png', 'Event Calendar', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EventCalendar()),
              );
            }),
            _buildIconButton('assets/attendancelogo.png', 'Attendance', () {
              _navigateToAttendancePage();
            }),
            _buildIconButton('assets/resultlogo.png', 'Result', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShowResultPage()),
              );
            }),
            _buildIconButton('assets/noticeboard.png', 'Notice Board', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NoticeBoard()),
              );
            }),
            _buildIconButton('assets/curriculumlogo.png', 'Curriculum', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CurriculumPage()),
              );
            }),
            _buildIconButton('assets/classroomlogo.png', 'Classroom', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClassroomPage(course: course),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(
      String imagePath, String title, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 6.0,
                  color: Color(0x34090F13),
                  offset: Offset(0.0, 2.0),
                ),
              ],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Image.asset(
              imagePath,
              width: 50,
              height: 50,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

Widget _buildScrollingAnnouncement() {
  if (_announcements.isEmpty) {
    return Container(
      color: const Color(0xFF305CDE),
      height: 40.0,
      alignment: Alignment.center,
      child: const Text(
        'No announcements available',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  return Container(
    color: const Color(0xFF305CDE),
    height: 40.0,
    padding: const EdgeInsets.symmetric(horizontal: 10.0),
    child: Row(
      children: [
        const Icon(Icons.announcement, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Marquee(
            text: _announcements.join("   |   "),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            blankSpace: 100.0,
            velocity: 50.0,
            pauseAfterRound: const Duration(milliseconds: 1000),
            startPadding: 10.0,
            accelerationDuration: const Duration(milliseconds: 500),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
            showFadingOnlyWhenScrolling: true,
            fadingEdgeStartFraction: 0.1,
            fadingEdgeEndFraction: 0.1,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildBottomNavBar() { 
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.grey,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.blue),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}