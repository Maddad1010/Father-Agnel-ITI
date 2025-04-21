import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show AlertDialog, Colors, LinearProgressIndicator, ScaffoldMessenger, SnackBar, TextButton, showDialog, Icon, Icons;
import 'package:excel/excel.dart' hide Border;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class AdminStudentPanel extends StatefulWidget {
  const AdminStudentPanel({super.key});

  @override
  _AdminStudentPanelState createState() => _AdminStudentPanelState();
}

class _AdminStudentPanelState extends State<AdminStudentPanel> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController rollNoController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController removeRollNoController = TextEditingController();

  List<String> courses = ["MMV", "FT", "RACT", "ET", "ICTSM"];
  String selectedCourse = "MMV";

  // Variables for upload result functionality
  File? selectedFile;
  double uploadProgress = 0;
  bool isUploading = false;

  // Variables for roll number uniqueness check
  bool isRollNoUnique = true;
  bool isCheckingRollNo = false;

  // Professional color palette
  final Color primaryColor = const Color(0xFF2A6B8F);
  final Color secondaryColor = const Color(0xFF4CAF50);
  final Color accentColor = const Color(0xFF607D8B);
  final Color errorColor = const Color(0xFFD32F2F);
  final Color pageBackgroundColor = const Color(0xFFF5F5F5);
  final Color textColor = const Color(0xFF263238);
  final Color borderColor = const Color(0xFFE0E0E0);

  String generatePassword(String name, String rollNo) {
    String cleanName = name.replaceAll(RegExp(r'\s+'), '');
    String cleanRollNo = rollNo.replaceAll(RegExp(r'\s+'), '');
    String prefix = cleanName.length >= 3
        ? cleanName.substring(0, 3).toLowerCase()
        : cleanName.toLowerCase();
    String suffix = cleanRollNo.length >= 3
        ? cleanRollNo.substring(cleanRollNo.length - 3)
        : cleanRollNo;
    return '$prefix$suffix${Random().nextInt(900) + 100}';
  }

  Future<String> generateUniqueUsername(String name) async {
    String baseUsername = name.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    String username = baseUsername;
    int counter = 1;

    var result = await FirebaseFirestore.instance
        .collection("students")
        .where("username", isEqualTo: username)
        .get();

    while (result.docs.isNotEmpty) {
      username = '$baseUsername$counter';
      counter++;
      result = await FirebaseFirestore.instance
          .collection("students")
          .where("username", isEqualTo: username)
          .get();
    }

    return username;
  }

  Future<void> checkRollNoUniqueness(String rollNo) async {
    setState(() {
      isCheckingRollNo = true;
    });

    var result = await FirebaseFirestore.instance
        .collection("students")
        .where("RollNo", isEqualTo: rollNo)
        .get();

    setState(() {
      isRollNoUnique = result.docs.isEmpty;
      isCheckingRollNo = false;
    });
  }

  void saveStudent() async {
    if (_formKey.currentState!.validate() && isRollNoUnique) {
      await FirebaseFirestore.instance.collection("students").add({
        "Name": nameController.text.trim(),
        "RollNo": rollNoController.text.trim(),
        "Course": selectedCourse,
        "PhNo": phoneController.text.trim(),
        "username": usernameController.text.trim(),
        "pass": passwordController.text.trim(),
      });
      showMessage("Student record saved successfully!");
      nameController.clear();
      rollNoController.clear();
      phoneController.clear();
      usernameController.clear();
      passwordController.clear();
    } else {
      showMessage("Please ensure all fields are filled correctly and the roll number is unique.");
    }
  }

  void removeStudent() async {
    String rollNo = removeRollNoController.text.trim();
    if (rollNo.isEmpty) return showMessage("Please enter a roll number");

    var students = await FirebaseFirestore.instance
        .collection("students")
        .where("RollNo", isEqualTo: rollNo)
        .get();

    if (students.docs.isEmpty) return showMessage("No student found");

    for (var student in students.docs) {
      await FirebaseFirestore.instance.collection("students").doc(student.id).delete();
    }
    removeRollNoController.clear();
    showMessage("Student removed successfully!");
  }

  Future<void> downloadExcel() async {
    var students = await FirebaseFirestore.instance.collection("students").get();
    var excel = Excel.createExcel();

    for (String course in courses) {
      excel[course].appendRow(["Name", "RollNo", "Phone", "Username", "Password"]);
      students.docs.where((s) => s["Course"] == course).forEach((student) {
        excel[course].appendRow([
          student["Name"],
          student["RollNo"],
          student["PhNo"],
          student["username"],
          student["pass"]
        ]);
      });
    }

    // Use the Downloads directory path directly via the legacy storage model.
    final Directory downloadsDirectory = Directory('/storage/emulated/0/Download');
    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }

    String fileName = 'students_data.xlsx';
    String newFileName = '${fileName.split('.').first}_${DateTime.now().millisecondsSinceEpoch}.${fileName.split('.').last}';
    final File file = File('${downloadsDirectory.path}/$newFileName');

    file
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    showMessage("Excel file saved in: ${file.path}");
  }

  void showMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          "Notification",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text(
              "OK",
              style: TextStyle(color: Color(0xFF2A6B8F)),
            ),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void showCoursePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          "Select Course",
          style: TextStyle(fontSize: 18),
        ),
        actions: courses
            .map((course) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => selectedCourse = course);
                    Navigator.pop(context);
                  },
                  child: Text(
                    course,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          child: const Text(
            "Cancel",
            style: TextStyle(color: Color(0xFF757575)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // Custom text field with a clear, rounded border (no underline)
  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    bool readOnly = false,
    VoidCallback? onChanged,
    Widget? suffixIcon,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      readOnly: readOnly,
      padding: const EdgeInsets.all(14),
      style: TextStyle(color: textColor, fontSize: 15),
      placeholderStyle: TextStyle(color: borderColor, fontSize: 15),
      decoration: BoxDecoration(
        color: CupertinoColors.extraLightBackgroundGray,
        border: Border.all(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      suffix: suffixIcon,
      onChanged: (value) {
        if (onChanged != null) {
          onChanged();
        }
      },
    );
  }

  // Custom section button with white text for dark backgrounds.
  Widget _buildSectionButton({required String text, required Color color, required VoidCallback onPressed}) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14),
      borderRadius: BorderRadius.circular(8),
      color: color,
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: CupertinoColors.white,
        ),
      ),
    );
  }

  // ================= Upload Result Functionality =================
  // Now, directly allow file selection without admin credential prompt.
  Future<void> uploadResult() async {
    selectFile();
  }

  Future<void> selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
      _showConfirmationDialog();
    } else {
      _showErrorDialog('File Selection', 'No file selected.');
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Upload'),
          content: const Text('Do you want to upload the selected file?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                uploadFileToFirebase();
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<void> uploadFileToFirebase() async {
    if (selectedFile != null) {
      try {
        String fileName = selectedFile!.path.split('/').last;
        Reference ref = FirebaseStorage.instance.ref(fileName);

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
      } catch (e) {
        setState(() {
          isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    } else {
      _showErrorDialog('Upload Error', 'No file selected for upload.');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
  // ================= End of Upload Result Functionality =================

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: pageBackgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "Admin Panel",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            decoration: TextDecoration.none,
          ),
        ),
        backgroundColor: pageBackgroundColor,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Add Student Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Add New Student",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(controller: nameController, placeholder: "Full Name", onChanged: () async {
                        if (nameController.text.isNotEmpty) {
                          String generatedUsername = await generateUniqueUsername(nameController.text);
                          setState(() {
                            usernameController.text = generatedUsername;
                          });
                        }
                      }),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: rollNoController,
                        placeholder: "Roll Number",
                        onChanged: () {
                          if (rollNoController.text.isNotEmpty) {
                            checkRollNoUniqueness(rollNoController.text);
                          }
                        },
                        suffixIcon: isCheckingRollNo
                            ? const CupertinoActivityIndicator()
                            : Icon(
                                isRollNoUnique ? Icons.check_circle : Icons.cancel,
                                color: isRollNoUnique ? secondaryColor : errorColor,
                              ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          color: Colors.transparent,
                          onPressed: showCoursePicker,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Selected Course:",
                                style: TextStyle(
                                  color: textColor.withOpacity(0.8),
                                  fontSize: 15,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              Text(
                                selectedCourse,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(controller: phoneController, placeholder: "Contact Number"),
                      const SizedBox(height: 15),
                      _buildTextField(controller: usernameController, placeholder: "Username", readOnly: true),
                      const SizedBox(height: 15),
                      _buildTextField(
                        controller: passwordController,
                        placeholder: "Auto-generated Password",
                        readOnly: true,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionButton(
                        text: "Generate Secure Password",
                        color: secondaryColor,
                        onPressed: () {
                          if (nameController.text.isEmpty || rollNoController.text.isEmpty) {
                            showMessage("Please fill name and roll number");
                            return;
                          }
                          setState(() {
                            passwordController.text = generatePassword(
                              nameController.text,
                              rollNoController.text,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSectionButton(
                        text: "Save Student Record",
                        color: primaryColor,
                        onPressed: saveStudent,
                      ),
                    ],
                  ),
                ),
                // Management Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Student Management",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: removeRollNoController,
                        placeholder: "Enter Roll Number to Remove",
                      ),
                      const SizedBox(height: 15),
                      _buildSectionButton(
                        text: "Remove Student",
                        color: errorColor,
                        onPressed: removeStudent,
                      ),
                      const SizedBox(height: 12),
                      _buildSectionButton(
                        text: "Export to Excel",
                        color: accentColor,
                        onPressed: downloadExcel,
                      ),
                    ],
                  ),
                ),
                // Upload Result Section (Last Section)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Upload Result",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionButton(
                        text: "Upload Result",
                        color: accentColor,
                        onPressed: uploadResult,
                      ),
                      if (isUploading)
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Column(
                            children: [
                              const Text('Uploading...', style: TextStyle(fontSize: 16)),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: uploadProgress,
                                backgroundColor: Colors.grey[300],
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
