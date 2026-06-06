import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/expenses/models/expense_model.dart';
import '../providers/settings_provider.dart';

class AutoTrackService {
  static final AutoTrackService _instance = AutoTrackService._internal();
  factory AutoTrackService() => _instance;
  AutoTrackService._internal();

  bool _isListening = false;

  Future<void> init() async {
    final bool status = await NotificationListenerService.isPermissionGranted();
    if (!status) {
      log("Notification Listener Permission not granted");
      return;
    }

    if (_isListening) return;
    _isListening = true;

    NotificationListenerService.notificationsStream.listen((event) {
      _handleNotification(event);
    });
  }

  Future<bool> requestPermission() async {
    final bool status = await NotificationListenerService.isPermissionGranted();
    if (!status) {
      return await NotificationListenerService.requestPermission();
    }
    return true;
  }

  void _handleNotification(ServiceNotificationEvent event) async {
    log("Received notification from: ${event.packageName}");
    log("Title: ${event.title}, Content: ${event.content}");

    if (event.packageName == null || event.content == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // TODO: Need to check if user has active group, but for simplicity we can fetch default group or first group
    final groupsSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .limit(1)
        .get();

    if (groupsSnapshot.docs.isEmpty) return;
    final groupId = groupsSnapshot.docs.first.id;

    // Check for Momo / Banking apps
    if (event.packageName == 'com.mservice.momotransfer' || 
        event.packageName!.contains('bank')) {
      
      final content = event.content!;
      
      // Basic regex to find amount like -50,000VND or - 50.000đ
      // Match negative amounts or payments
      if (content.toLowerCase().contains('thanh toán') || 
          content.toLowerCase().contains('trừ') || 
          content.contains('-')) {
        
        final regex = RegExp(r'(?:-|trừ|thanh toán)[\s]*([0-9.,]+)[\s]*(?:vnd|đ|d)', caseSensitive: false);
        final match = regex.firstMatch(content);
        
        if (match != null && match.group(1) != null) {
          String amountStr = match.group(1)!.replaceAll(RegExp(r'[,.]'), '');
          double amount = double.tryParse(amountStr) ?? 0;
          
          if (amount > 0) {
            _saveDraftExpense(
              groupId: groupId,
              userId: user.uid,
              amount: amount,
              description: event.title ?? 'Chi tiêu tự động',
              source: event.packageName!,
            );
          }
        }
      }
    }
  }

  Future<void> _saveDraftExpense({
    required String groupId,
    required String userId,
    required double amount,
    required String description,
    required String source,
  }) async {
    final expenseRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc();

    final expense = Expense(
      id: expenseRef.id,
      groupId: groupId,
      description: '[$source] $description',
      amount: amount,
      category: 'Chưa phân loại',
      paidBy: userId,
      date: DateTime.now(),
      type: 'expense',
      isConfirmed: false, // Wait for user to confirm
    );

    await expenseRef.set(expense.toMap());
    log("Saved draft expense from $source: $amount");
  }
}
