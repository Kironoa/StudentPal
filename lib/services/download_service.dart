import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';


class ModelDownloader {
  final Dio _dio = Dio();

  Future<File?> downloadModel(String url, String fileName) async {
    try {
      
      Directory appDocDir = await getApplicationSupportDirectory();
      String savePath = "${appDocDir.path}/$fileName";

      
      if (await File(savePath).exists()) {
        debugPrint("Model already downloaded at: $savePath");
        return File(savePath);
      }

      
      debugPrint("Downloading model...");
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint("${(received / total * 100).toStringAsFixed(0)}%");
          }
        },
      );

      return File(savePath);
    } catch (e) {
      debugPrint("Download Error: $e");
      return null;
    }
  }
}
