import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

void main() {
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF6366F1); // Indigo accent

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ProFinance Tracker',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const FinanceHome(),
    );
  }
}

enum TransactionType { income, expense }

class Transaction {
  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  final String id;
  final String title;
  final double amount;
  final String category;
  final TransactionType type;
  final DateTime date;
}

class FinanceHome extends StatefulWidget {
  const FinanceHome({super.key});

  @override
  State<FinanceHome> createState() => _FinanceHomeState();
}

class _FinanceHomeState extends State<FinanceHome> {
  int _currentIndex = 0;
  final GlobalKey _screenshotKey = GlobalKey();
  bool _isSharing = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String _selectedCategory = 'Food & Dining';
  double _monthlyBudgetLimit = 30000.0; // Default budget limit

  final Map<String, Color> _categoryColors = {
    'Food & Dining': Colors.orangeAccent,
    'Rent & Bills': Colors.blueAccent,
    'Shopping': Colors.purpleAccent,
    'Transport': Colors.tealAccent,
    'Entertainment': Colors.pinkAccent,
    'Salary': Colors.green,
    'Freelance': Colors.lightGreen,
    'Investments': Colors.cyan,
  };

  final List<String> _expenseCategories = [
    'Food & Dining',
    'Rent & Bills',
    'Shopping',
    'Transport',
    'Entertainment',
  ];

  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investments',
    'Gift',
  ];

  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      title: 'Monthly Software Salary',
      amount: 55000.0,
      category: 'Salary',
      type: TransactionType.income,
    ),
    Transaction(
      id: '2',
      title: 'Grocery Supermarket Run',
      amount: 3450.0,
      category: 'Food & Dining',
      type: TransactionType.expense,
    ),
    Transaction(
      id: '3',
      title: 'High-speed Fiber Internet',
      amount: 1199.0,
      category: 'Rent & Bills',
      type: TransactionType.expense,
    ),
    Transaction(
      id: '4',
      title: 'New Headset Purchase',
      amount: 4500.0,
      category: 'Shopping',
      type: TransactionType.expense,
    ),
  ];

  String _searchQuery = '';

  double get _totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _netBalance => _totalIncome - _totalExpense;

  void _addTransaction() {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    if (title.isEmpty || amountText.isEmpty) return;
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    setState(() {
      _transactions.insert(
        0,
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          amount: amount,
          category: _selectedCategory,
          type: _selectedType,
        ),
      );
      _titleController.clear();
      _amountController.clear();
    });

    Navigator.pop(context);
  }

  void _deleteTransaction(String id) {
    setState(() {
      _transactions.removeWhere((t) => t.id == id);
    });
  }

  Future<void> _shareScreenshot() async {
    setState(() => _isSharing = true);
    try {
      final boundary = _screenshotKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final xFile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: 'finance_summary.png',
      );

      await Share.shareXFiles(
        [xFile],
        text: '📊 Check out my monthly financial breakdown on ProFinance!',
      );
    } catch (e) {
      if (kDebugMode) print('Error sharing screenshot: $e');
    } finally {
      setState(() => _isSharing = false);
    }
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final categories = _selectedType == TransactionType.expense
                ? _expenseCategories
                : _incomeCategories;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'New Transaction',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('Expense'),
                          icon: Icon(Icons.arrow_downward, color: Colors.red),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text('Income'),
                          icon: Icon(Icons.arrow_upward, color: Colors.green),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (val) {
                        setModalState(() {
                          _selectedType = val.first;
                          _selectedCategory =
                              _selectedType == TransactionType.expense
                                  ? _expenseCategories.first
                                  : _incomeCategories.first;
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title / Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => _selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _addTransaction,
                      child: const Text('Add Record',
                          style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardTab(),
      _buildTransactionsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ProFinance Workspace',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            tooltip: 'Share Financial Summary',
            onPressed: _isSharing ? null : _shareScreenshot,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: RepaintBoundary(
            key: _screenshotKey,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: pages[_currentIndex],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddModal,
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
    );
  }

  // TAB 1: Analytics & Dashboard with Charts & Budget Progress
  Widget _buildDashboardTab() {
    final budgetProgress =
        (_totalExpense / _monthlyBudgetLimit).clamp(0.0, 1.0);

    // Compute category expenses for Pie Chart
    final Map<String, double> categoryTotals = {};
    for (var tx in _transactions.where((t) => t.type == TransactionType.expense)) {
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balance Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Net Balance',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 6),
                Text(
                  '₹${_netBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _netBalance >= 0 ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryMetric('Income', _totalIncome, Colors.greenAccent,
                        Icons.arrow_upward),
                    Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.3)),
                    _summaryMetric('Expenses', _totalExpense, Colors.redAccent,
                        Icons.arrow_downward),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Monthly Budget Limit Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monthly Budget Utilization',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '₹${_totalExpense.toInt()} / ₹${_monthlyBudgetLimit.toInt()}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: budgetProgress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      budgetProgress > 0.85 ? Colors.redAccent : Colors.indigoAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Expense Breakdown Pie Chart
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Expense Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                categoryTotals.isEmpty
                    ? const SizedBox(
                        height: 180,
                        child: Center(child: Text('No expense data to chart.')),
                      )
                    : SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: categoryTotals.entries.map((entry) {
                              final color = _categoryColors[entry.key] ?? Colors.blue;
                              final percentage = (_totalExpense > 0)
                                  ? (entry.value / _totalExpense) * 100
                                  : 0.0;
                              return PieChartSectionData(
                                color: color,
                                value: entry.value,
                                title: '${percentage.toInt()}%',
                                radius: 55,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                const SizedBox(height: 10),
                // Legend
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: categoryTotals.keys.map((cat) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _categoryColors[cat] ?? Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(cat, style: const TextStyle(fontSize: 11)),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // TAB 2: Transactions List with Search
  Widget _buildTransactionsTab() {
    final filtered = _transactions.where((t) {
      return t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No matching transactions found.'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      final isIncome = tx.type == TransactionType.income;
                      final catColor = _categoryColors[tx.category] ?? Colors.grey;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: catColor.withOpacity(0.2),
                            child: Icon(
                              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                              color: catColor,
                            ),
                          ),
                          title: Text(tx.title,
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(tx.category,
                              style: TextStyle(fontSize: 11, color: catColor)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isIncome ? Colors.greenAccent : Colors.redAccent,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.grey),
                                onPressed: () => _deleteTransaction(tx.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, double amount, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}