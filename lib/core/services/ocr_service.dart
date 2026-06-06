import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

final ocrServiceProvider = Provider<OcrService>((ref) => OcrService());

class OcrService {
  final ImagePicker _picker = ImagePicker();
  
  Future<File?> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 90);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<double?> extractAmountFromImage(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(imageFile);
    
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return _parseAmount(recognizedText.text);
    } catch (e) {
      print('Lỗi nhận diện văn bản: $e');
      return null;
    } finally {
      textRecognizer.close();
    }
  }

  double? _parseAmount(String text) {
    final lines = text.toLowerCase().split('\n');
    List<double> possibleAmounts = [];
    final regex = RegExp(r'[\d\.,]+');
    
    for (String line in lines) {
      bool hasKeyword = line.contains('tổng') || 
                        line.contains('total') || 
                        line.contains('thanh toán') ||
                        line.contains('cộng');
      
      final matches = regex.allMatches(line);
      for (var match in matches) {
        String numStr = match.group(0) ?? '';
        // Xóa dấu chấm phẩy phân cách ngàn
        numStr = numStr.replaceAll(RegExp(r'[\.,]'), '');
        
        if (numStr.isNotEmpty) {
          final amount = double.tryParse(numStr);
          // Giả sử số tiền > 1000 VNĐ
          if (amount != null && amount >= 1000) {
            if (hasKeyword) {
               return amount;
            }
            possibleAmounts.add(amount);
          }
        }
      }
    }
    
    // Loại bỏ các số có thể là số điện thoại (ví dụ > 100 triệu)
    possibleAmounts = possibleAmounts.where((a) => a < 100000000).toList();
    if (possibleAmounts.isNotEmpty) {
      possibleAmounts.sort();
      return possibleAmounts.last; // Số lớn nhất thường là tổng tiền
    }
    
    return null;
  }
}
