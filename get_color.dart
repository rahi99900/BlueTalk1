import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final bytes = File('assets/images/logo.png').readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image != null) {
    Map<String, int> colors = {};
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a > 0) { // Ignore fully transparent
          String hex = '#${pixel.r.toInt().toRadixString(16).padLeft(2, '0')}${pixel.g.toInt().toRadixString(16).padLeft(2, '0')}${pixel.b.toInt().toRadixString(16).padLeft(2, '0')}';
          colors[hex] = (colors[hex] ?? 0) + 1;
        }
      }
    }
    
    /*
    var sortedKeys = colors.keys.toList(growable: false)
      ..sort((k1, k2) => colors[k2]!.compareTo(colors[k1]!));
      
    print('Top colors:');
    for (int i = 0; i < 5 && i < sortedKeys.length; i++) {
        print('${sortedKeys[i]}: ${colors[sortedKeys[i]]}');
    }
    */
  } else {
    // print('Could not decode image');
  }
}
