import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/groups_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo nhóm mới'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Đặt tên cho nhóm chi tiêu của bạn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm (vd: Du lịch Đà Lạt)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group_add),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ngân sách dự kiến (không bắt buộc)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
                suffixText: 'đ',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;

                final budgetText = _budgetController.text.replaceAll(RegExp(r'[^0-9]'), '');
                final budget = budgetText.isNotEmpty ? double.tryParse(budgetText) : null;

                final user = ref.read(authStateProvider).value;
                if (user != null) {
                  try {
                    await ref.read(groupServiceProvider).createGroup(name, user.uid, budget: budget);
                    if (context.mounted) {
                      Navigator.pop(context); // Quay về màn hình Home
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi tạo nhóm: $e')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Tạo nhóm', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
