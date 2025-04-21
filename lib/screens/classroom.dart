import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class ClassroomPage extends StatefulWidget {
  final String course;

  const ClassroomPage({super.key, required this.course});

  @override
  _ClassroomPageState createState() => _ClassroomPageState();
}

class _ClassroomPageState extends State<ClassroomPage> {
  List<Reference> files = [];
  bool isLoading = true;
  bool isUploading = false;
  double uploadProgress = 0.0;
  File? selectedFile;
  Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    fetchFiles();
  }

  Future<void> fetchFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('${widget.course} classroom');
      final ListResult result = await storageRef.listAll();

      setState(() {
        files = result.items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching files: $e');
    }
  }

  Future<void> downloadFile(Reference ref) async {
    try {
      Directory downloadsDir = Directory('/storage/emulated/0/Download');

      String fileName = ref.name;
      String fileExtension = fileName.split('.').last;
      String baseName = fileName.replaceAll('.$fileExtension', '');

      String filePath = '${downloadsDir.path}/$fileName';
      int counter = 1;

      while (await File(filePath).exists()) {
        filePath = '${downloadsDir.path}/$baseName ($counter).$fileExtension';
        counter++;
      }

      await dio.download(await ref.getDownloadURL(), filePath,
          onReceiveProgress: (received, total) {
        if (total != -1) {
          print('Downloading: ${(received / total * 100).toStringAsFixed(0)}%');
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded ${ref.name} successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download ${ref.name}: $e')),
      );
    }
  }

  Future<void> showAdminUploadDialog() async {
    TextEditingController usernameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    String? selectedCourse;

    List<String> courseList = [
      'ET classroom',
      'FT classroom',
      'ICTSM classroom',
      'MMV classroom',
      'RACT classroom',
    ];

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0)),
          title: const Text(
            "Admin Login and Upload",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        labelStyle: const TextStyle(color: Colors.blueGrey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Colors.blueGrey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: selectedCourse,
                      hint: const Text('Select Course'),
                      style: const TextStyle(color: Colors.blueGrey),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCourse = newValue;
                        });
                      },
                      items: courseList.map<DropdownMenuItem<String>>(
                          (String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel", style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18), backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final adminSnapshot = await FirebaseFirestore.instance
                    .collection('admins')
                    .where('username', isEqualTo: usernameController.text)
                    .where('pass', isEqualTo: passwordController.text)
                    .get();

                if (adminSnapshot.docs.isNotEmpty && selectedCourse != null) {
                  Navigator.of(context).pop();
                  await pickAndUploadFile(selectedCourse!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Invalid credentials or course not selected')),
                  );
                }
              },
              child: const Text("Upload", style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Future<void> pickAndUploadFile(String course) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });

      bool confirmUpload = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            title: const Text("Confirm Upload", style: TextStyle(fontSize: 18)),
            content: Text(
                "Do you want to upload ${selectedFile!.path.split('/').last}?"),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancel", style: TextStyle(fontSize: 16)),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)), backgroundColor: Colors.blueAccent,
                ),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text("Yes", style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      );

      if (confirmUpload) {
        await uploadFileToFirebase(course);
      }
    }
  }

  Future<void> uploadFileToFirebase(String course) async {
    if (selectedFile != null) {
      try {
        String fileName = selectedFile!.path.split('/').last;

        Reference ref = FirebaseStorage.instance.ref('$course/$fileName');

        UploadTask uploadTask = ref.putFile(
          selectedFile!,
          SettableMetadata(contentType: 'application/octet-stream'),
        );

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          setState(() {
            uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
            isUploading = true;
          });
        });

        await uploadTask;

        setState(() {
          uploadProgress = 1.0;
          isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );

        fetchFiles();
      } catch (e) {
        setState(() {
          isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected for upload.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.course} Classroom',
            style: const TextStyle(color: Colors.white, fontSize: 22)),
        centerTitle: true,
        backgroundColor: const Color(0xFF305CDE),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : files.isEmpty
              ? const Center(
                  child: Text(
                    'No study materials for this course.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 4,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 12.0),
                        title: Text(
                          files[index].name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.download,
                              color: Colors.blueAccent),
                          onPressed: () => downloadFile(files[index]),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF305CDE),
        onPressed: showAdminUploadDialog,
        child: const Icon(Icons.upload, color: Colors.white),
      ),
    );
  }
}
