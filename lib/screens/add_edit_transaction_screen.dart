import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  TransactionType _selectedType = TransactionType.income;
  String _name = '';
  double _amount = 0;
  Periodicity _selectedPeriodicity = Periodicity.none;
  DateTime _startDate = DateTime.now();

  String get _startDateStr => DateFormat('dd.MM.yyyy').format(_startDate);

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _selectedType = widget.transaction!.type;
      _name = widget.transaction!.name;
      _amount = widget.transaction!.amount;
      _selectedPeriodicity = widget.transaction!.periodicity;
      _startDate = widget.transaction!.startDate;
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _saveTransaction() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      Transaction newTransaction = Transaction(
        id: widget.transaction?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        name: _name,
        amount: _amount,
        startDate: _startDate,
        periodicity: _selectedPeriodicity,
        endDate: widget.transaction?.endDate,
      );
      Navigator.pop(context, newTransaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Добавить транзакцию'
            : 'Редактировать транзакцию'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<TransactionType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Тип'),
                items: const [
                  DropdownMenuItem(
                    value: TransactionType.income,
                    child: Text('Доход'),
                  ),
                  DropdownMenuItem(
                    value: TransactionType.expense,
                    child: Text('Расход'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Наименование'),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Введите наименование'
                    : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _amount != 0 ? _amount.toString() : '',
                decoration: const InputDecoration(labelText: 'Сумма'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите сумму';
                  if (double.tryParse(value) == null) {
                    return 'Неверный формат числа';
                  }
                  return null;
                },
                onSaved: (value) => _amount = double.parse(value!),
              ),
              DropdownButtonFormField<Periodicity>(
                value: _selectedPeriodicity,
                decoration: const InputDecoration(labelText: 'Периодичность'),
                items: const [
                  DropdownMenuItem(
                    value: Periodicity.none,
                    child: Text('Нет'),
                  ),
                  DropdownMenuItem(
                    value: Periodicity.day,
                    child: Text('День'),
                  ),
                  DropdownMenuItem(
                    value: Periodicity.week,
                    child: Text('Неделя'),
                  ),
                  DropdownMenuItem(
                    value: Periodicity.month,
                    child: Text('Месяц'),
                  ),
                  DropdownMenuItem(
                    value: Periodicity.year,
                    child: Text('Год'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPeriodicity = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Стартовая дата: '),
                  Text(_startDateStr),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: const Text('Выбрать'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
