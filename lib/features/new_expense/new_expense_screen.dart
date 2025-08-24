import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/money/money.dart';

/// Screen for adding or editing expenses
class NewExpenseScreen extends ConsumerStatefulWidget {
  final String? groupId;
  final String? expenseId;

  const NewExpenseScreen({
    super.key,
    this.groupId,
    this.expenseId,
  });

  @override
  ConsumerState<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends ConsumerState<NewExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'Food';
  String _selectedGroup = '';
  String _selectedPayer = '';
  DateTime _selectedDate = DateTime.now();
  ExpenseType _expenseType = ExpenseType.split;
  final Map<String, double> _splitAmounts = {};

  bool get _isEditing => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    if (widget.groupId != null) {
      _selectedGroup = widget.groupId!;
    }
    _loadExpenseData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'New Expense'),
        actions: [
          TextButton(
            onPressed: _saveExpense,
            child: Text(_isEditing ? 'Update' : 'Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppTokens.screenPadding,
          children: [
            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What was this expense for?',
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),

            const SizedBox(height: AppTokens.space4),

            // Amount field
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),

            const SizedBox(height: AppTokens.space4),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: _getCategories().map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Text(_getCategoryEmoji(category)),
                      const SizedBox(width: AppTokens.space2),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),

            const SizedBox(height: AppTokens.space4),

            // Date picker
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
            ),

            const SizedBox(height: AppTokens.space6),

            // Expense type selector
            Text(
              'Expense Type',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.space2),
            SegmentedButton<ExpenseType>(
              segments: const [
                ButtonSegment(
                  value: ExpenseType.split,
                  label: Text('Split'),
                  icon: Icon(Icons.group),
                ),
                ButtonSegment(
                  value: ExpenseType.individual,
                  label: Text('Individual'),
                  icon: Icon(Icons.person),
                ),
              ],
              selected: {_expenseType},
              onSelectionChanged: (selection) {
                setState(() {
                  _expenseType = selection.first;
                });
              },
            ),

            const SizedBox(height: AppTokens.space6),

            // Group selector (for split expenses)
            if (_expenseType == ExpenseType.split) ...[
              DropdownButtonFormField<String>(
                value: _selectedGroup.isEmpty ? null : _selectedGroup,
                decoration: const InputDecoration(
                  labelText: 'Group',
                  prefixIcon: Icon(Icons.group),
                ),
                items: _getGroups().map((group) {
                  return DropdownMenuItem(
                    value: group.id,
                    child: Text(group.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGroup = value;
                    });
                  }
                },
                validator: (value) {
                  if (_expenseType == ExpenseType.split && (value == null || value.isEmpty)) {
                    return 'Please select a group';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.space4),
            ],

            // Payer selector
            DropdownButtonFormField<String>(
              value: _selectedPayer.isEmpty ? null : _selectedPayer,
              decoration: const InputDecoration(
                labelText: 'Paid by',
                prefixIcon: Icon(Icons.person),
              ),
              items: _getMembers().map((member) {
                return DropdownMenuItem(
                  value: member.id,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        child: Text(member.avatarEmoji ?? member.name[0]),
                      ),
                      const SizedBox(width: AppTokens.space2),
                      Text(member.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPayer = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select who paid';
                }
                return null;
              },
            ),

            const SizedBox(height: AppTokens.space4),

            // Split details (for split expenses)
            if (_expenseType == ExpenseType.split) ...[
              const SizedBox(height: AppTokens.space4),
              Card(
                child: Padding(
                  padding: AppTokens.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Split Details',
                            style: theme.textTheme.titleMedium,
                          ),
                          TextButton(
                            onPressed: _splitEqually,
                            child: const Text('Split Equally'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.space2),
                      ..._getMembers().map((member) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              child: Text(member.avatarEmoji ?? member.name[0]),
                            ),
                            const SizedBox(width: AppTokens.space3),
                            Expanded(child: Text(member.name)),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                initialValue: _splitAmounts[member.id]?.toString() ?? '0',
                                decoration: const InputDecoration(
                                  prefixText: '₹',
                                  isDense: true,
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (value) {
                                  final amount = double.tryParse(value) ?? 0;
                                  _splitAmounts[member.id] = amount;
                                },
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppTokens.space4),

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any additional notes',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: AppTokens.space6),

            // Save button
            ElevatedButton(
              onPressed: _saveExpense,
              child: Text(_isEditing ? 'Update Expense' : 'Save Expense'),
            ),

            if (_isEditing) ...[
              const SizedBox(height: AppTokens.space2),
              OutlinedButton(
                onPressed: _deleteExpense,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete Expense'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Load expense data for editing
  void _loadExpenseData() {
    if (!_isEditing) return;

    // Mock data loading - replace with actual data loading
    _descriptionController.text = 'Hotel Booking';
    _amountController.text = '1200.00';
    _selectedCategory = 'Accommodation';
    _selectedPayer = '1';
    _selectedDate = DateTime.now().subtract(const Duration(days: 2));
  }

  /// Get available categories
  List<String> _getCategories() {
    return [
      'Food',
      'Transport',
      'Groceries',
      'Utilities',
      'Shopping',
      'Entertainment',
      'Health',
      'Education',
      'Bills',
      'Accommodation',
      'Miscellaneous',
    ];
  }

  /// Get category emoji
  String _getCategoryEmoji(String category) {
    return switch (category.toLowerCase()) {
      'food' => '🍽️',
      'transport' => '🚕',
      'groceries' => '🛒',
      'utilities' => '💡',
      'shopping' => '🛍️',
      'entertainment' => '🎬',
      'health' => '🏥',
      'education' => '🎓',
      'bills' => '🧾',
      'accommodation' => '🏨',
      _ => '🏷️',
    };
  }

  /// Get available groups
  List<MockGroup> _getGroups() {
    return [
      const MockGroup(id: '1', name: 'Weekend Trip'),
      const MockGroup(id: '2', name: 'Roommates'),
      const MockGroup(id: '3', name: 'Office Lunch'),
    ];
  }

  /// Get available members
  List<MockMember> _getMembers() {
    return [
      const MockMember(id: '1', name: 'You', avatarEmoji: '😊'),
      const MockMember(id: '2', name: 'Alice', avatarEmoji: '👩'),
      const MockMember(id: '3', name: 'Bob', avatarEmoji: '👨'),
    ];
  }

  /// Select date
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  /// Split amount equally among members
  void _splitEqually() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final members = _getMembers();
    final splitAmount = amount / members.length;

    setState(() {
      for (final member in members) {
        _splitAmounts[member.id] = splitAmount;
      }
    });
  }

  /// Save expense
  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Implement actual save logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Expense updated!' : 'Expense saved!'),
      ),
    );

    context.pop();
  }

  /// Delete expense
  void _deleteExpense() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete logic
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Expense type enum
enum ExpenseType { split, individual }

/// Mock group data
class MockGroup {
  final String id;
  final String name;

  const MockGroup({required this.id, required this.name});
}

/// Mock member data
class MockMember {
  final String id;
  final String name;
  final String? avatarEmoji;

  const MockMember({required this.id, required this.name, this.avatarEmoji});
}
