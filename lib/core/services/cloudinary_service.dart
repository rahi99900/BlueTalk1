import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CloudinaryService {
  CloudinaryService._();
  static final instance = CloudinaryService._();

  static const String _cloudName = 'dbzbmwcdm';
  static const String _uploadPreset = 'BlueTalk';

  /// Uploads an image to Cloudinary using Unsigned upload
  /// Provide either [filePath] (for mobile/desktop) or [bytes] (for web)
  Future<String?> uploadImage({String? filePath, Uint8List? bytes, String? filename}) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _uploadPreset;

      if (bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          bytes, 
          filename: filename ?? 'upload.jpg'
        ));
      } else if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
      } else {
        return null;
      }
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final resData = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = jsonDecode(resData);
        return jsonResponse['secure_url']; // This is the public URL of the uploaded image
      } else {
        final resData = await response.stream.bytesToString();
        debugPrint('Cloudinary upload error (${response.statusCode}): $resData');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload exception: $e');
      return null;
    }
  }
}
