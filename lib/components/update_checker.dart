import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:the_music_tech/core/providers/my_provider.dart';

class UpdateChecker extends StatefulWidget {
  const UpdateChecker({super.key});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  double progress = 0;
  bool showUpdateActions = false;
  String? filePath;

  @override
  void initState() {
    super.initState();
    // checkForUpdate();
  }

  Future<void> _downloadAndInstallApk(String url) async {
    // Check if the filePath is not null (APK already downloaded)
    if (filePath != null) {
      // If the filePath is valid, check install permission
      await _requestInstallPermission();
      OpenFile.open(filePath); // Open APK
    }
    // If the filePath is null, request storage permission and download the APK
    else if (await Permission.manageExternalStorage.request().isGranted) {
      try {
        setState(() {
          showUpdateActions = false;
        });
        final downloadsDir = Directory('/storage/emulated/0/Download');

        final directory = downloadsDir;
        if (!downloadsDir.existsSync()) {
          throw Exception('Downloads folder not found');
        }
        filePath = path.join(downloadsDir.path, 'app_update.apk');

        Dio dio = Dio();
        await dio.download(
          url,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              setState(() {
                progress = (received / total * 100);
              });
            }
          },
        );

        // After download, request install permission again
        await _requestInstallPermission();
        OpenFile.open(filePath);
      } catch (e) {
        setState(() {
          progress = 0;
        });
      }
    } else {
      // If storage permission is denied, request permission again
      // await Permission.storage.request();
      await openAppSettings();
    }
  }

  Future<void> _requestInstallPermission() async {
    if (!await Permission.requestInstallPackages.isGranted) {
      // If permission is denied, request it again
      await Permission.requestInstallPackages.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final myProvider = Provider.of<MyProvider>(context);

    return Stack(
      children: [
        Image.network(
          "https://d29fhpw069ctt2.cloudfront.net/photo/3380/preview/addd3a4d-c1db-49f7-b309-9e66bff3ff2e_1280x1280.jpg",
          height: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
          color: Colors.black.withAlpha(100),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              // mainAxisAlignment: MainAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 100),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      'New Update is',
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      'Available',
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      textAlign: TextAlign.center,
                      myProvider.appUpdate?.version ?? "",
                      style: const TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        myProvider.appUpdate?.description ?? "",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Roboto',
                        ),
                        maxLines: 4,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (progress != 0) ...[
                  CircularPercentIndicator(
                    radius: 60.0,
                    lineWidth: 8.0,
                    percent: progress * 0.01,
                    center: Text(
                      "${progress.toStringAsFixed(0)}%",
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                      ),
                    ),
                    progressColor: Colors.purpleAccent,
                  ),
                ],
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                        ),
                        onPressed: () {
                          if (myProvider.appUpdate?.downloadLink != null) {
                            _downloadAndInstallApk(
                              myProvider.appUpdate!.downloadLink!,
                            );
                          }
                        },
                        child: const Text(
                          "Update Now",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      showUpdateActions = false;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Later",
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
