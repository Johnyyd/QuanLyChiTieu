import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/sql_server_helper.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({required this.messages, this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  late GenerativeModel _model;
  late ChatSession _chat;
  bool _historyLoaded = false;

  @override
  ChatState build() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(model: 'gemini-flash-latest', apiKey: apiKey);
    _chat = _model.startChat();
    _loadHistory();
    return ChatState(messages: [], isLoading: true);
  }

  Future<void> _loadHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(isLoading: false);
      _historyLoaded = true;
      return;
    }
    try {
      final query =
          "SELECT MessageText, IsUser FROM ChatMessages WHERE UserId = '$uid' ORDER BY CreatedAt ASC";
      final res = await SqlServerHelper.instance.executeQuery(query);
      if (res.isNotEmpty && res != '[]') {
        final List<dynamic> list = jsonDecode(res);
        final messages = list
            .map(
              (e) => ChatMessage(
                text: e['MessageText'],
                isUser: e['IsUser'] == 1 || e['IsUser'] == true,
              ),
            )
            .toList();

        final historyContents = messages.map((m) {
          return Content(m.isUser ? 'user' : 'model', [TextPart(m.text)]);
        }).toList();

        _chat = _model.startChat(history: historyContents);
        state = state.copyWith(messages: messages, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('Load history error: $e');
      state = state.copyWith(isLoading: false);
    }
    _historyLoaded = true;
  }

  Future<void> _saveMessageToDb(ChatMessage msg) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final id =
          DateTime.now().millisecondsSinceEpoch.toString() +
          (msg.isUser ? 'U' : 'A');
      final query = '''
        INSERT INTO ChatMessages (Id, UserId, MessageText, IsUser, CreatedAt)
        VALUES (@Id, @UserId, @MessageText, @IsUser, @CreatedAt)
      ''';
      await SqlServerHelper.instance.executeWriteWithParams(query, {
        'Id': id,
        'UserId': uid,
        'MessageText': msg.text,
        'IsUser': msg.isUser ? 1 : 0,
        'CreatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Save message error: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    while (!_historyLoaded) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final userMsg = ChatMessage(text: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );
    _saveMessageToDb(userMsg);

    try {
      String finalPrompt = text;
      if (_chat.history.isEmpty) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        String contextData = '''
Bạn là một chuyên gia tư vấn tài chính cá nhân thông minh, thân thiện và chuyên nghiệp. 
Nhiệm vụ của bạn là phân tích dữ liệu chi tiêu của người dùng và đưa ra các lời khuyên hữu ích.
Khi người dùng yêu cầu thống kê hoặc hỏi về chi tiêu, hãy thực hiện các bước sau (nếu phù hợp):
1. Tính tổng số tiền đã chi tiêu trong danh sách.
2. Phân loại và tổng hợp số tiền theo từng nhóm (ví dụ: Ăn uống, Mua sắm, v.v.).
3. Nhận xét về thói quen chi tiêu (khoản nào chiếm tỷ trọng lớn nhất, có lãng phí không).
4. Đưa ra lời khuyên tiết kiệm hoặc gợi ý phân bổ tài chính (như quy tắc 50/30/20).
Lưu ý: 
- Trình bày câu trả lời rõ ràng, dễ đọc bằng cách dùng in đậm, gạch đầu dòng (Markdown).
- Xưng "tôi" và gọi người dùng là "bạn". Không cần nhắc lại rằng bạn chỉ nhận được 50 khoản chi tiêu trừ khi cần thiết.
- Nếu người dùng hỏi bạn là ai, hãy trả lời bạn là trợ lý tài chính cá nhân thông minh.
- Chỉ trả lời các câu hỏi liên quan đến chi tiêu. Nếu câu hỏi không liên quan đến chi tiêu, hãy trả lời rằng bạn chỉ có thể trả lời các câu hỏi liên quan đến chi tiêu và không trả lời các câu hỏi khác.
''';
        if (uid != null) {
          // Lấy dữ liệu tiết kiệm
          String savingsStr = '';
          try {
            final savingsSnapshot = await FirebaseFirestore.instance
                .collection('savings_goals')
                .where('userId', isEqualTo: uid)
                .get();
            final savingsList = savingsSnapshot.docs
                .map((d) {
                  final data = d.data();
                  final title = data['title'] ?? 'Không tên';
                  final current = data['currentAmount'] ?? 0;
                  final target = data['targetAmount'] ?? 0;
                  return '- Mục tiêu tiết kiệm "$title": đã gom được $current/$target VND';
                })
                .join('\n');
            if (savingsList.isNotEmpty) {
              savingsStr = '\n--- MỤC TIÊU TIẾT KIỆM ---\n$savingsList\n';
            }
          } catch (e) {
            // Bỏ qua nếu lỗi
          }

          // Lấy dữ liệu chi tiêu và thu nhập từ các nhóm
          final groupsSnapshot = await FirebaseFirestore.instance
              .collection('groups')
              .where('members', arrayContains: uid)
              .get();

          List<Map<String, dynamic>> allExpenses = [];
          for (var groupDoc in groupsSnapshot.docs) {
            final groupData = groupDoc.data();
            final groupName = groupData['name'] ?? 'Cá nhân';
            final expSnapshot = await groupDoc.reference
                .collection('expenses')
                .get();
            final userExpenses = expSnapshot.docs.where(
              (d) => d.data()['paidBy'] == uid,
            );
            for (var doc in userExpenses) {
              final eData = doc.data();
              eData['groupName'] = groupName;
              allExpenses.add(eData);
            }
          }

          allExpenses.sort((a, b) {
            final aDate = a['date'] is Timestamp
                ? (a['date'] as Timestamp).toDate()
                : DateTime.now();
            final bDate = b['date'] is Timestamp
                ? (b['date'] as Timestamp).toDate()
                : DateTime.now();
            return bDate.compareTo(aDate);
          });

          final expensesList = allExpenses
              .take(50)
              .map((data) {
                final title = data['title'] ?? 'Không tên';
                final amount = data['amount'] ?? 0;
                final category = data['category'] ?? 'Khác';
                final type = data['type'] ?? 'expense';
                final group = data['groupName'];
                final typeStr = type == 'income' ? 'THU NHẬP' : 'CHI TIÊU';
                return '- [$typeStr trong ví $group] Mua "$title": $amount VND (Nhóm: $category)';
              })
              .join('\n');
          contextData +=
              '$savingsStr\n--- DỮ LIỆU GIAO DỊCH GẦN ĐÂY CỦA NGƯỜI DÙNG ---\n$expensesList\n-----------------------------------\n';
        }
        finalPrompt = '$contextData\nCâu hỏi/Yêu cầu của người dùng: "$text"';
      }

      GenerateContentResponse? response;
      try {
        response = await _chat.sendMessage(Content.text(finalPrompt));
      } catch (e) {
        String errorText = e.toString();
        if (errorText.contains('503') || errorText.contains('UNAVAILABLE')) {
          print(
            'Model gemini-flash-latest overloaded, trying gemini-flash-latest fallback...',
          );
          final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
          final fallbackModel = GenerativeModel(
            model: 'gemini-flash-latest',
            apiKey: apiKey,
          );
          final fallbackChat = fallbackModel.startChat(
            history: _chat.history.toList(),
          );
          response = await fallbackChat.sendMessage(Content.text(finalPrompt));
          _model = fallbackModel;
          _chat = fallbackChat;
        } else {
          rethrow;
        }
      }

      final responseText =
          response?.text ?? 'Xin lỗi, tôi không thể trả lời lúc này.';
      final aiMsg = ChatMessage(text: responseText, isUser: false);
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
      _saveMessageToDb(aiMsg);
    } catch (e) {
      String errorText = e.toString();
      if (errorText.contains('503') || errorText.contains('UNAVAILABLE')) {
        errorText =
            'Hệ thống AI của Google hiện đang bị quá tải hoặc phản hồi chậm. Bạn vui lòng thử lại sau vài phút nhé!';
      } else {
        errorText = 'Lỗi kết nối: $e';
      }
      final errorMsg = ChatMessage(text: errorText, isUser: false);
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
      );
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});
