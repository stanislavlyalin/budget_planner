import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import '../utils/transaction_utils.dart';
import 'add_edit_transaction_screen.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// Main screen displaying transactions in a table
class _MyHomePageState extends State<MyHomePage> {
  List<Transaction> _transactions = [];
  List<OccurrenceOverride> _overrides = [];
  late DateTime _currentEndDate;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _filterController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _currentEndDate = DateTime.now().add(const Duration(days: 30));
    _scrollController.addListener(_scrollListener);
    _loadData();

    // For demonstration, add test transactions if list is empty
    if (_transactions.isEmpty) {
      _transactions.addAll([
        Transaction(
          id: '1',
          type: TransactionType.income,
          name: 'Зарплата',
          amount: 1000,
          startDate: DateTime.now().add(const Duration(days: 1)),
          periodicity: Periodicity.month,
        ),
        Transaction(
          id: '2',
          type: TransactionType.expense,
          name: 'Аренда',
          amount: 500,
          startDate: DateTime.now().add(const Duration(days: 2)),
          periodicity: Periodicity.month,
        ),
      ]);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    String transactionsJson =
        json.encode(_transactions.map((t) => t.toJson()).toList());
    String overridesJson =
        json.encode(_overrides.map((o) => o.toJson()).toList());
    await prefs.setString('transactions', transactionsJson);
    await prefs.setString('overrides', overridesJson);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? transactionsJson = prefs.getString('transactions');
    String? overridesJson = prefs.getString('overrides');
    if (transactionsJson != null) {
      List decoded = json.decode(transactionsJson);
      _transactions = decoded
          .map((e) => Transaction.fromJson(e))
          .toList()
          .cast<Transaction>();
    }
    if (overridesJson != null) {
      List decoded = json.decode(overridesJson);
      _overrides = decoded
          .map((e) => OccurrenceOverride.fromJson(e))
          .toList()
          .cast<OccurrenceOverride>();
    }
    setState(() {});
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      setState(() {
        _currentEndDate = _currentEndDate.add(const Duration(days: 30));
      });
    }
  }

  Future<void> _addTransaction() async {
    final newTransaction = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(builder: (context) => const AddEditTransactionScreen()),
    );
    if (newTransaction != null) {
      setState(() {
        _transactions.add(newTransaction);
      });
      _saveData();
    }
  }

  void _editOccurrence(TransactionOccurrence occ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать'),
        content: const Text(
            'Выберите режим редактирования:\n• Только эту запись\n• Все записи\n• Все последующие записи'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openEditScreen(occ, EditMode.single);
            },
            child: const Text('Только эту'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openEditScreen(occ, EditMode.all);
            },
            child: const Text('Все записи'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openEditScreen(occ, EditMode.subsequent);
            },
            child: const Text('Все последующие'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditScreen(TransactionOccurrence occ, EditMode mode) async {
    if (mode == EditMode.single) {
      final editedTransaction = await Navigator.push<Transaction>(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditTransactionScreen(
            transaction: occ.transaction,
          ),
        ),
      );
      if (editedTransaction != null) {
        setState(() {
          if (editedTransaction.periodicity == Periodicity.none) {
            int index =
                _transactions.indexWhere((t) => t.id == occ.transaction.id);
            if (index != -1) {
              _transactions[index] = editedTransaction;
            }
          } else {
            _overrides.add(
              OccurrenceOverride(
                transactionId: occ.transaction.id,
                date: occ.date,
                newTransaction: editedTransaction,
              ),
            );
          }
        });
        _saveData();
      }
    } else if (mode == EditMode.all) {
      final editedTransaction = await Navigator.push<Transaction>(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditTransactionScreen(
            transaction: occ.transaction,
          ),
        ),
      );
      if (editedTransaction != null) {
        setState(() {
          int index =
              _transactions.indexWhere((t) => t.id == occ.transaction.id);
          if (index != -1) {
            _transactions[index] = editedTransaction;
          }
          _overrides.removeWhere((o) => o.transactionId == occ.transaction.id);
        });
        _saveData();
      }
    } else if (mode == EditMode.subsequent) {
      final editedTransaction = await Navigator.push<Transaction>(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditTransactionScreen(
            transaction: occ.transaction,
          ),
        ),
      );
      if (editedTransaction != null) {
        setState(() {
          int index =
              _transactions.indexWhere((t) => t.id == occ.transaction.id);
          if (index != -1) {
            Transaction original = _transactions[index];
            _transactions[index] = original.copyWith(
                endDate: occ.date.subtract(const Duration(days: 1)));
          }
          _transactions.add(editedTransaction.copyWith(startDate: occ.date));
        });
        _saveData();
      }
    }
  }

  void _deleteOccurrence(TransactionOccurrence occ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить'),
        content: const Text(
            'Выберите режим удаления:\n• Только эту запись\n• Все записи\n• Все последующие записи'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _overrides.add(
                  OccurrenceOverride(
                    transactionId: occ.transaction.id,
                    date: occ.date,
                  ),
                );
              });
              _saveData();
            },
            child: const Text('Только эту'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _transactions.removeWhere((t) => t.id == occ.transaction.id);
                _overrides
                    .removeWhere((o) => o.transactionId == occ.transaction.id);
              });
              _saveData();
            },
            child: const Text('Все записи'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                int index =
                    _transactions.indexWhere((t) => t.id == occ.transaction.id);
                if (index != -1) {
                  Transaction original = _transactions[index];
                  _transactions[index] = original.copyWith(
                    endDate: occ.date.subtract(const Duration(days: 1)),
                  );
                }
              });
              _saveData();
            },
            child: const Text('Все последующие'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackupAppSpecific() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to get external storage directory')),
      );
      return;
    }

    final backupData = {
      'transactions': _transactions.map((t) => t.toJson()).toList(),
      'overrides': _overrides.map((o) => o.toJson()).toList(),
    };

    final jsonString = json.encode(backupData);
    final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final filePath = '${dir.path}/$fileName';

    try {
      final file = File(filePath);
      await file.writeAsString(jsonString);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File saved: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving file: $e')),
      );
    }
  }

  Future<void> _importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        final jsonString = await file.readAsString();
        final data = json.decode(jsonString);
        final transactionsData = data['transactions'] as List;
        final overridesData = data['overrides'] as List;

        setState(() {
          _transactions =
              transactionsData.map((e) => Transaction.fromJson(e)).toList();
          _overrides =
              overridesData.map((e) => OccurrenceOverride.fromJson(e)).toList();
        });
        _saveData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring backup: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startRange = DateTime(now.year, now.month, now.day);

    // Calculate current balance (sum of all past transactions, excluding today)
    List<TransactionOccurrence> pastOccurrences = getOccurrencesInRange(
      _transactions,
      DateTime(2000, 1, 1),
      startRange,
      _overrides,
    );
    double currentBalance = 0;
    for (var occ in pastOccurrences) {
      currentBalance += occ.transaction.type == TransactionType.income
          ? occ.transaction.amount
          : -occ.transaction.amount;
    }

    // Future occurrences from today onward
    List<TransactionOccurrence> futureOccurrences = getOccurrencesInRange(
      _transactions,
      startRange,
      _currentEndDate,
      _overrides,
    );

    // Calculate cumulative sums for future occurrences based on full data
    List<double> fullCumulativeSums = [];
    double runningTotal = currentBalance;
    for (var occ in futureOccurrences) {
      double signedAmount = occ.transaction.type == TransactionType.income
          ? occ.transaction.amount
          : -occ.transaction.amount;
      runningTotal += signedAmount;
      fullCumulativeSums.add(runningTotal);
    }

    // Pair each future occurrence with its cumulative sum
    List<MapEntry<TransactionOccurrence, double>> fullEntries = [];
    for (int i = 0; i < futureOccurrences.length; i++) {
      fullEntries.add(MapEntry(futureOccurrences[i], fullCumulativeSums[i]));
    }

    // Filter entries based on _searchQuery (case-insensitive) on transaction name
    List<MapEntry<TransactionOccurrence, double>> filteredEntries;
    if (_searchQuery.isEmpty) {
      filteredEntries = fullEntries;
    } else {
      filteredEntries = fullEntries
          .where((entry) => entry.key.transaction.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Total rows: 1 for current balance + filtered future occurrences
    int totalRows = 1 + filteredEntries.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export backup',
            onPressed: _exportBackupAppSpecific,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import backup',
            onPressed: _importBackup,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field for filtering by transaction name
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 48,
              child: TextField(
                controller: _filterController,
                decoration: InputDecoration(
                  labelText: 'Фильтр по наименованию',
                  hintText: 'Фильтр отключен',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _filterController.clear();
                      setState(() {
                        _searchQuery = "";
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          // Table header
          Container(
            color: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: const [
                Expanded(
                  flex: 22,
                  child: Text('Дата',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 34,
                  child: Text('Наименование',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 22,
                  child: Text('Сумма',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 22,
                  child: Text('Итог',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: totalRows,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // "Current Balance" row
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 22,
                          child: Text(
                            'На текущий момент',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Expanded(flex: 34, child: Text('')),
                        const Expanded(flex: 22, child: Text('')),
                        Expanded(
                          flex: 22,
                          child: Text(
                            currentBalance.toStringAsFixed(2),
                            style: TextStyle(
                              color: currentBalance >= 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  final entry = filteredEntries[index - 1];
                  final occ = entry.key;
                  final cumSum = entry.value;
                  final dateStr = DateFormat('dd.MM.yyyy').format(occ.date);
                  final isIncome =
                      occ.transaction.type == TransactionType.income;
                  final amountStr = occ.transaction.amount.toStringAsFixed(2);
                  final totalStr = cumSum.toStringAsFixed(2);
                  return InkWell(
                    onTap: () => _editOccurrence(occ),
                    onLongPress: () => _deleteOccurrence(occ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 22, child: Text(dateStr)),
                          Expanded(flex: 34, child: Text(occ.transaction.name)),
                          Expanded(
                            flex: 22,
                            child: Text(
                              amountStr,
                              style: TextStyle(
                                  color: isIncome ? Colors.green : Colors.red),
                            ),
                          ),
                          Expanded(
                            flex: 22,
                            child: Text(
                              totalStr,
                              style: TextStyle(
                                color: double.parse(totalStr) >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Editing modes for periodic transactions
enum EditMode { single, all, subsequent }
