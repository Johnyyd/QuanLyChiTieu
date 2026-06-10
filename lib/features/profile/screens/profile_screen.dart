import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName == 'Chưa cập nhật tên' ? '' : currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cập nhật tên hiển thị'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Tên mới',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != currentName) {
                  Navigator.pop(context); // Close dialog first
                  try {
                    await ref.read(authProvider).updateDisplayName(newName);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cập nhật tên thành công!')),
                      );
                      final user = ref.read(authStateProvider).value;
                      if (user != null) {
                         ref.invalidate(userProfileProvider(user.uid));
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi cập nhật tên: $e')),
                      );
                    }
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu mới', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentPass = currentPasswordController.text;
                final newPass = newPasswordController.text;
                final confirmPass = confirmPasswordController.text;

                if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')));
                  return;
                }
                if (newPass != confirmPass) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu mới không khớp')));
                  return;
                }

                Navigator.pop(context); // Close dialog first
                try {
                  await ref.read(authProvider).changePassword(currentPass, newPass);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref, bool requiresPassword) {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xoá tài khoản', style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('CẢNH BÁO: Hành động này sẽ xoá VĨNH VIỄN toàn bộ dữ liệu thu chi, nhóm, và thông tin tài khoản của bạn. Bạn không thể hoàn tác.', style: TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              if (requiresPassword) ...[
                const Text('Vui lòng nhập mật khẩu để xác nhận:'),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder()),
                ),
              ] else ...[
                const Text('Bạn có chắc chắn muốn xoá tài khoản không?'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final password = passwordController.text;
                if (requiresPassword && password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mật khẩu')));
                  return;
                }

                Navigator.pop(context); // Close dialog first
                try {
                  await ref.read(authProvider).deleteAccount(requiresPassword ? password : null);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xoá tài khoản thành công')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xoá Vĩnh Viễn', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

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
                        trailing: const Icon(Icons.edit, size: 20),
                        onTap: () {
                          _showEditNameDialog(context, ref, userProfile?.name ?? user.displayName ?? 'Chưa cập nhật tên');
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
                        title: const Text('Email'),
                        subtitle: Text(user.email ?? 'Không rõ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      // Chỉ hiện Đổi mật khẩu nếu đăng nhập bằng Email (Provider ID là password)
                      if (user.providerData.any((userInfo) => userInfo.providerId == 'password')) ...[
                        const Divider(),
                        ListTile(
                          leading: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                          title: const Text('Đổi mật khẩu'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            _showChangePasswordDialog(context, ref);
                          },
                        ),
                      ],
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  final requiresPassword = user.providerData.any((userInfo) => userInfo.providerId == 'password');
                  _showDeleteAccountDialog(context, ref, requiresPassword);
                },
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Xóa tài khoản', style: TextStyle(color: Colors.red)),
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
