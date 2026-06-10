import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Chưa đăng nhập')),
      );
    }

    final userProfileAsync = ref.watch(userProfileProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt tài khoản'),
      ),
      body: userProfileAsync.when(
        data: (userProfile) {
          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              const SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Tên hiển thị'),
                        subtitle: Text(userProfile?.name ?? user.displayName ?? 'Chưa cập nhật tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Email'),
                        subtitle: Text(user.email ?? 'Không rõ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Giao diện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Chế độ Tối (Dark Mode)'),
                        trailing: Switch(
                          value: ref.watch(themeProvider).themeMode == ThemeMode.dark,
                          onChanged: (isDark) {
                            ref.read(themeProvider.notifier).setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Màu chủ đạo', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: AppTheme.recommendedColors.map((color) {
                            final isSelected = ref.watch(themeProvider).primaryColor.value == color.value;
                            return GestureDetector(
                              onTap: () {
                                ref.read(themeProvider.notifier).setPrimaryColor(color);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: Colors.black54, width: 3) : null,
                                  boxShadow: [
                                    if (isSelected) BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                                  ]
                                ),
                                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Bảo mật', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Khóa ứng dụng (Sinh trắc học)'),
                        trailing: Switch(
                          value: ref.watch(settingsProvider).useBiometrics,
                          onChanged: (value) async {
                            final success = await ref.read(settingsProvider.notifier).setUseBiometrics(value);
                            if (!success && value) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Thiết bị không hỗ trợ hoặc xác thực thất bại')),
                                );
                              }
                            }
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Bắt giao dịch qua thông báo (Momo,...)'),
                        subtitle: const Text('Tự động ghi nhận khi có thông báo trừ tiền', style: TextStyle(fontSize: 12)),
                        trailing: Switch(
                          value: ref.watch(settingsProvider).autoTrackEnabled,
                          onChanged: (value) async {
                            final success = await ref.read(settingsProvider.notifier).setAutoTrack(value);
                            if (!success && value) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Không thể kích hoạt tự động theo dõi. Vui lòng cấp quyền Notification.')),
                                );
                              }
                            }
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Đăng xuất'),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ref.read(authProvider).signOut();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                          child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}
