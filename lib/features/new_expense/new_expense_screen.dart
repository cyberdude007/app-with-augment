import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/money/money.dart';
import '../../core/utils/date_fmt.dart';
import '../../data/models/expense_type.dart';
import '../../data/models/category.dart';
import '../../widgets/buttons.dart';
import '../../widgets/inputs.dart';
import '../../widgets/category_chip.dart';
import 'widgets/expense_type_toggle.dart';
import 'widgets/category_picker.dart';

/// New expense screen with Split ⇄ Individual toggle and adaptive layout
class NewExpenseScreen extends ConsumerStatefulWidget {
  final String? expenseId;
  final String? groupId;

  const NewExpenseScreen({
    super.key,
    this.expenseId,
    this.groupId,
  });

  @override
  ConsumerState<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends ConsumerState<NewExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  // Form state
  ExpenseFormState _formState = const ExpenseFormState();
  
  // Mock data - will be replaced with real providers
  final List<Category> _allCategories = DefaultCategories.categories;
  final List<Category> _recentCategories = [];
  final List<String> _groupMembers = ['Alice', 'Bob', 'Charlie'];
  
  bool get _isEditing => widget.expenseId != null;
  bool get _isTabletLayout => MediaQuery.of(context).size.width >= AppTokens.breakpointMedium;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    // Initialize form with default values
    _formState = _formState.copyWith(
      groupId: widget.groupId,
      type: widget.groupId != null ? ExpenseType.split : ExpenseType.individual,
      date: DateTime.now(),
      payerId: 'current_user', // Will be replaced with actual user ID
    );

    // Set default category
    if (_allCategories.isNotEmpty) {
      _formState = _formState.copyWith(category: _allCategories.first.name);
    }
  }

  void _updateFormState(ExpenseFormState newState) {
    setState(() {
      _formState = newState;
    });
  }

  void _onExpenseTypeChanged(ExpenseType type) {
    _updateFormState(_formState.copyWith(type: type));
  }

  void _onCategorySelected(Category category) {
    _updateFormState(_formState.copyWith(category: category.name));
  }

  void _onSplitMethodChanged(SplitMethod method) {
    _updateFormState(_formState.copyWith(splitMethod: method));
  }

  void _showCategoryPicker() {
    if (_isTabletLayout) {
      // For tablet, category picker is shown in side pane
      return;
    }

    // Show bottom sheet for mobile
    showCategoryPickerSheet(
      context: context,
      categories: _allCategories,
      recentCategories: _recentCategories,
      selectedCategoryId: _allCategories
          .where((c) => c.name == _formState.category)
          .firstOrNull?.id,
    ).then((category) {
      if (category != null) {
        _onCategorySelected(category);
      }
    });
  }

  void _saveExpense() {
    if (!_formKey.currentState!.validate() || !_formState.isValid) {
      // Show validation errors
      final errors = _formState.validationErrors;
      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errors.first),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // TODO: Implement actual save logic
    final message = _isEditing ? 'Expense updated!' : 'Expense saved!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'New Expense'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: () {
                // TODO: Implement delete
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _isTabletLayout ? _buildTabletLayout() : _buildPhoneLayout(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPhoneLayout() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expense type toggle
            ExpenseTypeToggle(
              selectedType: _formState.type,
              onTypeChanged: _onExpenseTypeChanged,
            ),
            
            const SizedBox(height: AppTokens.space6),
            
            // Individual expense info banner
            if (_formState.type == ExpenseType.individual) ...[
              const IndividualExpenseInfo(),
              const SizedBox(height: AppTokens.space4),
            ],
            
            // Common fields
            _buildCommonFields(),
            
            // Split-specific fields
            if (_formState.type == ExpenseType.split) ...[
              const SizedBox(height: AppTokens.space6),
              _buildSplitFields(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Left pane - Form
        Expanded(
          flex: 2,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.space6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expense type toggle
                  ExpenseTypeToggle(
                    selectedType: _formState.type,
                    onTypeChanged: _onExpenseTypeChanged,
                  ),
                  
                  const SizedBox(height: AppTokens.space6),
                  
                  // Individual expense info banner
                  if (_formState.type == ExpenseType.individual) ...[
                    const IndividualExpenseInfo(),
                    const SizedBox(height: AppTokens.space4),
                  ],
                  
                  // Common fields
                  _buildCommonFields(),
                  
                  // Split-specific fields
                  if (_formState.type == ExpenseType.split) ...[
                    const SizedBox(height: AppTokens.space6),
                    _buildSplitFields(),
                  ],
                ],
              ),
            ),
          ),
        ),
        
        // Right pane - Category picker and preview
        Expanded(
          child: Column(
            children: [
              // Category picker pane
              Expanded(
                child: CategoryPicker(
                  categories: _allCategories,
                  recentCategories: _recentCategories,
                  selectedCategoryId: _allCategories
                      .where((c) => c.name == _formState.category)
                      .firstOrNull?.id,
                  onCategorySelected: _onCategorySelected,
                  isExpanded: true,
                ),
              ),
              
              // Preview section
              if (_formState.type == ExpenseType.split)
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(AppTokens.space4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: _buildSplitPreview(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommonFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description
        AppTextFormField(
          controller: _descriptionController,
          labelText: 'Description',
          hintText: 'What was this expense for?',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Description is required';
            }
            return null;
          },
          onChanged: (value) {
            _updateFormState(_formState.copyWith(description: value));
          },
        ),

        const SizedBox(height: AppTokens.space4),

        // Amount
        AppTextFormField(
          controller: _amountController,
          labelText: 'Amount',
          hintText: '0.00',
          prefixText: '₹ ',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Amount is required';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Enter a valid amount';
            }
            return null;
          },
          onChanged: (value) {
            _updateFormState(_formState.copyWith(amount: value));
          },
        ),

        const SizedBox(height: AppTokens.space4),

        // Category field
        _buildCategoryField(),

        const SizedBox(height: AppTokens.space4),

        // Payer (for split) or just show current user (for individual)
        if (_formState.type == ExpenseType.split)
          _buildPayerField()
        else
          _buildCurrentUserField(),

        const SizedBox(height: AppTokens.space4),

        // Date
        _buildDateField(),

        const SizedBox(height: AppTokens.space4),

        // Notes
        AppTextFormField(
          controller: _notesController,
          labelText: 'Notes (Optional)',
          hintText: 'Add any additional details...',
          maxLines: 3,
          onChanged: (value) {
            _updateFormState(_formState.copyWith(notes: value));
          },
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    final selectedCategory = _allCategories
        .where((c) => c.name == _formState.category)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.space2),

        // Quick category chips (recent/favorites)
        if (_recentCategories.isNotEmpty && !_isTabletLayout) ...[
          QuickCategorySelector(
            quickCategories: _recentCategories.take(6).toList(),
            selectedCategoryId: selectedCategory?.id,
            onCategorySelected: _onCategorySelected,
            onShowAllCategories: _showCategoryPicker,
            placeholder: 'Tap to select category',
          ),
        ] else ...[
          // Category selection button
          InkWell(
            onTap: _showCategoryPicker,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTokens.space3),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
              child: Row(
                children: [
                  if (selectedCategory?.emoji != null) ...[
                    Text(
                      selectedCategory!.emoji!,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: AppTokens.space2),
                  ],
                  Expanded(
                    child: Text(
                      selectedCategory?.name ?? 'Select category',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selectedCategory != null
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPayerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paid by',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        DropdownButtonFormField<String>(
          value: _formState.payerId.isNotEmpty ? _formState.payerId : null,
          decoration: const InputDecoration(
            hintText: 'Select who paid',
          ),
          items: _groupMembers.map((member) {
            return DropdownMenuItem(
              value: member,
              child: Text(member),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _updateFormState(_formState.copyWith(payerId: value));
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select who paid';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCurrentUserField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paid by',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTokens.space3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Text(
            'You', // Will be replaced with actual user name
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _formState.date ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (date != null) {
              _updateFormState(_formState.copyWith(date: date));
            }
          },
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTokens.space3),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppTokens.space2),
                Text(
                  _formState.date != null
                      ? DateFmt.format(_formState.date!)
                      : 'Select date',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Split method selector
        SplitMethodSelector(
          selectedMethod: _formState.splitMethod,
          onMethodChanged: _onSplitMethodChanged,
        ),

        const SizedBox(height: AppTokens.space4),

        // Split details based on method
        _buildSplitDetails(),
      ],
    );
  }

  Widget _buildSplitDetails() {
    switch (_formState.splitMethod) {
      case SplitMethod.equally:
        return _buildEqualSplitDetails();
      case SplitMethod.exact:
        return _buildExactSplitDetails();
      case SplitMethod.percentage:
        return _buildPercentageSplitDetails();
    }
  }

  Widget _buildEqualSplitDetails() {
    final amount = double.tryParse(_formState.amount) ?? 0.0;
    final perPersonAmount = _groupMembers.isNotEmpty ? amount / _groupMembers.length : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split Details',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        Container(
          padding: const EdgeInsets.all(AppTokens.space3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Per person:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    Money.fromRupees(perPersonAmount).formatDisplay(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space2),
              Text(
                '${_groupMembers.length} people × ${Money.fromRupees(perPersonAmount).formatDisplay()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExactSplitDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter exact amounts for each person',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        // TODO: Implement exact split input fields
        Container(
          padding: const EdgeInsets.all(AppTokens.space4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: const Text('Exact split input - Coming soon'),
        ),
      ],
    );
  }

  Widget _buildPercentageSplitDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter percentage for each person',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        // TODO: Implement percentage split input fields
        Container(
          padding: const EdgeInsets.all(AppTokens.space4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: const Text('Percentage split input - Coming soon'),
        ),
      ],
    );
  }

  Widget _buildSplitPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split Preview',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.space3),
        Expanded(
          child: ListView.builder(
            itemCount: _groupMembers.length,
            itemBuilder: (context, index) {
              final member = _groupMembers[index];
              final amount = double.tryParse(_formState.amount) ?? 0.0;
              final perPersonAmount = amount / _groupMembers.length;

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 16,
                  child: Text(member[0]),
                ),
                title: Text(member),
                trailing: Text(
                  Money.fromRupees(perPersonAmount).formatDisplay(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space3,
        AppTokens.space4,
        AppTokens.space4 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton.primary(
              onPressed: _saveExpense,
              child: Text(
                _formState.type == ExpenseType.split
                    ? (_isEditing ? 'Update Split' : 'Save Split')
                    : (_isEditing ? 'Update Individual' : 'Save Individual'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
