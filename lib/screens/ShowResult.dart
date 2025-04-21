import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ShowResultPage extends StatefulWidget {
  const ShowResultPage({super.key});

  @override
  ShowResultPageState createState() => ShowResultPageState();
}

class ShowResultPageState extends State<ShowResultPage> {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? latestFileUrl;
  String? latestFileName;
  String? errorMessage;
  bool isDownloading = false;
  double downloadProgress = 0;

  String? username; // Retrieved from SharedPreferences.
  String studentName = '';
  String studentRollNo = '';
  String studentCourse = '';
  String studentPhoneNo = '';

  @override
  void initState() {
    super.initState();
    fetchUsernameAndStudentData();
  }

  Future<void> fetchUsernameAndStudentData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? prefUsername = prefs.getString('username');

    if (prefUsername != null) {
      setState(() {
        username = prefUsername;
      });
      await fetchStudentData(prefUsername);
    } else {
      setState(() {
        errorMessage = 'Username not found in preferences.';
      });
    }
  }

  Future<void> fetchStudentData(String prefUsername) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('students')
          .where('username', isEqualTo: prefUsername)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userDoc = querySnapshot.docs.first.data() as Map<String, dynamic>;
        studentName = userDoc['Name'] ?? '';
        studentRollNo = userDoc['RollNo'].toString();
        studentCourse = userDoc['Course'] ?? '';
        studentPhoneNo = userDoc['PhNo'].toString();

        await checkLatestFile();
      } else {
        setState(() {
          errorMessage = 'Student not found.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching student data: $e';
      });
    }
  }

  Future<void> checkLatestFile() async {
    try {
      final ListResult result = await storage.ref().listAll();
      final List<Reference> items = result.items;

      if (username == null || studentRollNo.isEmpty) {
        setState(() {
          errorMessage = 'Insufficient data to determine file name.';
        });
        return;
      }

      String expectedFileName = "$username$studentRollNo";

      // Filter files based on prefix (handles any extension)
      List<Reference> matchingItems = items.where((item) =>
          item.name.startsWith(expectedFileName)).toList();

      if (matchingItems.isEmpty) {
        setState(() {
          latestFileUrl = null;
          latestFileName = null;
          errorMessage = 'Result not available yet!';
        });
        return;
      }

      // Retrieve metadata for sorting
      List<FullMetadata> metadataList = await Future.wait(
          matchingItems.map((item) => item.getMetadata()));

      List<MapEntry<Reference, FullMetadata>> entries = List.generate(
          matchingItems.length,
          (i) => MapEntry(matchingItems[i], metadataList[i]));

      // Sort by last updated time (descending)
      entries.sort((a, b) {
        DateTime aTime = a.value.updated ?? DateTime.fromMillisecondsSinceEpoch(0);
        DateTime bTime = b.value.updated ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      // Use the most recent file
      Reference latestItem = entries.first.key;
      latestFileUrl = await latestItem.getDownloadURL();
      latestFileName = latestItem.name;

      setState(() {
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching files: $e';
      });
    }
  }

  Future<void> downloadFile(String url, String fileName) async {
    try {
      final Directory downloadsDirectory =
          Directory('/storage/emulated/0/Download');

      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      String newFileName =
          '${fileName.split('.').first}_${DateTime.now().millisecondsSinceEpoch}.${fileName.split('.').last}';
      final File file = File('${downloadsDirectory.path}/$newFileName');

      final Dio dio = Dio();
      setState(() {
        isDownloading = true;
      });

      await dio.download(url, file.path, onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() {
            downloadProgress = received / total;
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File downloaded to ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    } finally {
      setState(() {
        isDownloading = false;
        downloadProgress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Show Result'),
        backgroundColor: const Color(0xFF305CDE),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: $studentName',
                          style: TextStyle(fontSize: width * 0.04)),
                      Text('Roll No: $studentRollNo',
                          style: TextStyle(fontSize: width * 0.04)),
                      Text('Course: $studentCourse',
                          style: TextStyle(fontSize: width * 0.04)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: height * 0.02),
              if (latestFileName != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latest Result:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.04),
                        ),
                        SizedBox(height: height * 0.01),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                latestFileName!,
                                style: TextStyle(fontSize: width * 0.04),
                              ),
                            ),
                            SizedBox(width: width * 0.04),
                            isDownloading
                                ? CircularProgressIndicator(
                                    value: downloadProgress,
                                    color: const Color(0xFF305CDE),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF305CDE),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      if (latestFileUrl != null) {
                                        downloadFile(
                                            latestFileUrl!, latestFileName!);
                                      }
                                    },
                                    child: const Text('Download',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
