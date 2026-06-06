import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/expenses/models/expense_model.dart';

class ExportService {
  static Future<void> exportExpensesToCsv(List<Expense> expenses, {String? fileName}) async {
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      "Ngày",
      "Mô tả",
      "Danh mục",
      "Loại",
      "Số tiền (VNĐ)",
      "Trạng thái"
    ]);

    final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    for (var expense in expenses) {
      rows.add([
        dateFormat.format(expense.date),
        expense.description,
        expense.category,
        expense.type == 'income' ? 'Thu' : (expense.type == 'settlement' ? 'Quyết toán' : 'Chi'),
        expense.amount,
        expense.isConfirmed ? 'Đã duyệt' : 'Chờ duyệt',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final String path = "${directory.path}/${fileName ?? 'chi_tieu_${DateTime.now().millisecondsSinceEpoch}'}.csv";
    
    final File file = File(path);
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(path)], text: 'Báo cáo chi tiêu');
  }
}
