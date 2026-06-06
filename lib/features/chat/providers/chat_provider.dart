import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  ChatState build() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
    );
    _chat = _model.startChat();
    return ChatState(messages: []);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true);
    state = state.copyWith(messages: [...state.messages, userMsg], isLoading: true);

    try {
      String finalPrompt = text;
      if (_chat.history.isEmpty) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        String contextData = 'Bạn là chuyên gia tư vấn tài chính cá nhân. Trả lời ngắn gọn, thân thiện.\n';
        if (uid != null) {
          final groupsSnapshot = await FirebaseFirestore.instance
              .collection('groups')
              .where('members', arrayContains: uid)
              .get();
              
          List<QueryDocumentSnapshot<Map<String, dynamic>>> allExpenses = [];
          for (var groupDoc in groupsSnapshot.docs) {
            final expSnapshot = await groupDoc.reference.collection('expenses').get();
            allExpenses.addAll(expSnapshot.docs.where((d) => d.data()['paidBy'] == uid));
          }
          
          final sortedDocs = allExpenses
            ..sort((a, b) {
              final aData = a.data();
              final bData = b.data();
              final aDate = aData['date'] is Timestamp ? (aData['date'] as Timestamp).toDate() : DateTime.now();
              final bDate = bData['date'] is Timestamp ? (bData['date'] as Timestamp).toDate() : DateTime.now();
              return bDate.compareTo(aDate);
            });
            
          final expensesList = sortedDocs.take(50).map((d) {
             final data = d.data();
             final title = data['title'] ?? 'Không tên';
             final amount = data['amount'] ?? 0;
             final category = data['category'] ?? 'Khác';
             return '- $title ($amount VND) - Nhóm: $category';
          }).join('\n');
          contextData += 'Dưới đây là 50 khoản chi tiêu gần nhất của tôi:\n$expensesList\n\n';
        }
        finalPrompt = '$contextData\nYêu cầu của người dùng: $text';
      }

      final response = await _chat.sendMessage(Content.text(finalPrompt));
      final responseText = response.text ?? 'Xin lỗi, tôi không thể trả lời lúc này.';
      final aiMsg = ChatMessage(text: responseText, isUser: false);
      state = state.copyWith(messages: [...state.messages, aiMsg], isLoading: false);
    } catch (e) {
      final errorMsg = ChatMessage(text: 'Lỗi kết nối: $e', isUser: false);
      state = state.copyWith(messages: [...state.messages, errorMsg], isLoading: false);
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});
