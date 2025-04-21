import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dio/dio.dart';

class CurriculumPage extends StatefulWidget {
  const CurriculumPage({super.key});

  @override
  State<CurriculumPage> createState() => _CurriculumPageState();
}

class _CurriculumPageState extends State<CurriculumPage> {
  String? selectedCurriculum;
  final FirebaseStorage storage = FirebaseStorage.instance;
  bool isDownloading = false;
  double downloadProgress = 0;

  Future<void> downloadFile(String curriculum) async {
    setState(() {
      isDownloading = true;
    });

    try {
      String filePath = 'curriculum/$curriculum.pdf';
      Reference ref = storage.ref().child(filePath);
      String downloadUrl = await ref.getDownloadURL();

      // Use the Downloads directory path directly via the legacy storage model.
      final Directory downloadsDirectory = Directory('/storage/emulated/0/Download');
      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      String fileName = '$curriculum.pdf';
      String newFileName =
          '${fileName.split('.').first}_${DateTime.now().millisecondsSinceEpoch}.${fileName.split('.').last}';
      final File file = File('${downloadsDirectory.path}/$newFileName');

      final Dio dio = Dio();
      await dio.download(
        downloadUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$curriculum.pdf downloaded successfully to Downloads!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isDownloading = false;
        downloadProgress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.blue[800]),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Curriculum',
          style: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select Your Curriculum',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: DropdownButton<String>(
                  value: selectedCurriculum,
                  isExpanded: true,
                  hint: const Text(
                    'Select Curriculum',
                    style: TextStyle(color: Colors.black54),
                  ),
                  items: <String>[
                    'ET',
                    'FT',
                    'ICTSM',
                    'RACT',
                    'MMV',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCurriculum = newValue;
                    });
                  },
                  underline: const SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.blue[800]),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: selectedCurriculum == null || isDownloading
                    ? null
                    : () {
                        downloadFile(selectedCurriculum!);
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
                  backgroundColor: selectedCurriculum != null ? Colors.blue[800] : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  shadowColor: Colors.blue.withOpacity(0.2),
                  elevation: 10,
                ),
                child: isDownloading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: downloadProgress,
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Download Curriculum',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
