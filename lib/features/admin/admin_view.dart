import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/api_service.dart';

class AdminView extends StatefulWidget {
  const AdminView({super.key});

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _stocks = [];
  List<dynamic> _bets = [];

  List<dynamic> get _openChallenges =>
      _bets.where((bet) => bet['status'] == 'open').toList();

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        apiService.fetchStocks(),
        apiService.fetchBets(),
      ]);

      setState(() {
        _stocks = results[0];
        _bets = results[1];
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openCreateStockDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateStockDialog(),
    );

    if (created == true) {
      await _loadAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock created successfully'),
          backgroundColor: Color(0xFF00D09C),
        ),
      );
    }
  }

  Future<void> _openCreateBetDialog({required String title}) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => _CreateBetDialog(title: title),
    );

    if (created == true) {
      await _loadAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bet created successfully'),
          backgroundColor: Color(0xFF00D09C),
        ),
      );
    }
  }

  Future<void> _openSetResultDialog(String betId) async {
    final resolved = await showDialog<bool>(
      context: context,
      builder: (context) => _SetResultDialog(betId: betId),
    );

    if (resolved == true) {
      await _loadAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bet resolved successfully'),
          backgroundColor: Color(0xFF00D09C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0E12),
      ),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                toolbarHeight: 60,
                expandedHeight: 104,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                    onPressed: _isLoading ? null : _loadAdminData,
                  ),
                ],
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      color: const Color(0xFF101010).withOpacity(0.85),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.fromLTRB(64, 0, 72, 44),
                      child: Text(
                        'ADMIN CONSOLE',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                bottom: const TabBar(
                  indicatorColor: Color(0xFFFF5722),
                  labelColor: Color(0xFFFF5722),
                  unselectedLabelColor: Colors.white54,
                  tabs: [
                    Tab(icon: Icon(Icons.candlestick_chart_rounded, size: 18), text: 'STOCKS'),
                    Tab(icon: Icon(Icons.flag_rounded, size: 18), text: 'CHALLENGES'),
                    Tab(icon: Icon(Icons.fact_check_rounded, size: 18), text: 'BETS'),
                  ],
                ),
              ),
              SliverFillRemaining(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5722)),
      );
    }

    if (_error != null) {
      return _EmptyState(
        icon: Icons.warning_amber_rounded,
        title: 'Could not load admin data',
        message: _error!,
      );
    }

    return TabBarView(
      children: [
        _buildStocksList(),
        _buildBetsList(
          _openChallenges,
          emptyTitle: 'No active challenges',
          createLabel: 'ADD CHALLENGE',
          onCreate: () => _openCreateBetDialog(title: 'Create Challenge'),
        ),
        _buildBetsList(
          _bets,
          emptyTitle: 'No bets created yet',
          createLabel: 'ADD BET',
          onCreate: () => _openCreateBetDialog(title: 'Create Bet'),
        ),
      ],
    );
  }

  Widget _buildStocksList() {
    final createButton = _CreateButton(
      label: 'ADD STOCK',
      icon: Icons.add_chart_rounded,
      onPressed: _openCreateStockDialog,
    );

    if (_stocks.isEmpty) {
      return _EmptyState(
        icon: Icons.candlestick_chart_rounded,
        title: 'No stocks created yet',
        message: 'Create the first tradable asset from here.',
        action: createButton,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        createButton,
        const SizedBox(height: 18),
        ..._stocks.map((stock) {
          final price = (stock['price'] ?? 0).toDouble();
          final previousPrice = (stock['previousPrice'] ?? 0).toDouble();
          final isUp = price >= previousPrice;

          return _AdminTile(
            icon: Icons.show_chart_rounded,
            accent: isUp ? const Color(0xFF00D09C) : const Color(0xFFEB5B3C),
            title: stock['name'] ?? 'Unnamed stock',
            subtitle: stock['stockId'] ?? 'No stock id',
            trailing: '${price.toStringAsFixed(2)} CMX',
            meta: 'Shares: ${stock['sharesct'] ?? 0}',
          );
        }),
      ],
    );
  }

  Widget _buildBetsList(
    List<dynamic> bets, {
    required String emptyTitle,
    required String createLabel,
    required VoidCallback onCreate,
  }) {
    final createButton = _CreateButton(
      label: createLabel,
      icon: Icons.add_task_rounded,
      onPressed: onCreate,
    );

    if (bets.isEmpty) {
      return _EmptyState(
        icon: Icons.fact_check_rounded,
        title: emptyTitle,
        message: 'Create one from this console to see it here.',
        action: createButton,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        createButton,
        const SizedBox(height: 18),
        ...bets.map((bet) {
          final status = bet['status'] ?? 'unknown';
          final resultTime = DateTime.tryParse(bet['resultTime'] ?? '');
          final accent = status == 'open'
              ? const Color(0xFF00D09C)
              : const Color(0xFFEB5B3C);

          return _AdminTile(
            icon: Icons.flag_rounded,
            accent: accent,
            title: bet['question'] ?? 'Untitled bet',
            subtitle: bet['betId'] ?? 'No bet id',
            trailing: status.toString().toUpperCase(),
            meta: 'Pool: ${bet['totalPool'] ?? 0} CMX  |  Users: ${bet['totalEnrolled'] ?? 0}  |  Result: ${bet['result'] ?? 'hidden'}${resultTime == null ? '' : '  |  ${_formatDate(resultTime)}'}',
            action: status == 'open'
                ? TextButton(
                    onPressed: () => _openSetResultDialog(bet['betId']),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF5722),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: const Color(0xFFFF5722).withOpacity(0.1),
                    ),
                    child: const Text('SET RESULT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                : null,
          );
        }),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String trailing;
  final String meta;
  final Widget? action;

  const _AdminTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.meta,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  meta,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                trailing,
                textAlign: TextAlign.right,
                style: GoogleFonts.robotoMono(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 8),
                action!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _CreateButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5722),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white24, size: 54),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, height: 1.4),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              SizedBox(width: 220, child: action!),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateStockDialog extends StatefulWidget {
  const _CreateStockDialog();

  @override
  State<_CreateStockDialog> createState() => _CreateStockDialogState();
}

class _CreateStockDialogState extends State<_CreateStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _stockIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _previousPriceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _stockIdController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _previousPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await apiService.createStock(
        stockId: _stockIdController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        previousPrice: _previousPriceController.text.trim().isEmpty
            ? null
            : double.parse(_previousPriceController.text.trim()),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AdminDialogShell(
      title: 'Create Stock',
      isSubmitting: _isSubmitting,
      submitLabel: 'CREATE STOCK',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AdminTextField(
              controller: _stockIdController,
              label: 'Stock ID',
              icon: Icons.tag_rounded,
              validator: _required,
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _nameController,
              label: 'Stock name',
              icon: Icons.business_rounded,
              validator: _required,
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _priceController,
              label: 'Current price',
              icon: Icons.monetization_on_rounded,
              keyboardType: TextInputType.number,
              validator: _positiveNumber,
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _previousPriceController,
              label: 'Previous price (optional)',
              icon: Icons.history_rounded,
              keyboardType: TextInputType.number,
              validator: _optionalPositiveNumber,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateBetDialog extends StatefulWidget {
  final String title;

  const _CreateBetDialog({required this.title});

  @override
  State<_CreateBetDialog> createState() => _CreateBetDialogState();
}

class _CreateBetDialogState extends State<_CreateBetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _betIdController = TextEditingController();
  final _questionController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _resultTime;
  String _result = 'YES';
  String _accentColor = 'orange';
  bool _isTrending = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _betIdController.dispose();
    _questionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickResultTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _resultTime ?? DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _resultTime ?? DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    if (time == null) return;

    setState(() {
      _resultTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_resultTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a result time'),
          backgroundColor: Color(0xFFEB5B3C),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await apiService.createBet(
        betId: _betIdController.text.trim(),
        question: _questionController.text.trim(),
        description: _descriptionController.text.trim(),
        result: _result,
        resultTime: _resultTime!,
        isTrending: _isTrending,
        accentColor: _accentColor,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AdminDialogShell(
      title: widget.title,
      isSubmitting: _isSubmitting,
      submitLabel: 'CREATE',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AdminTextField(
              controller: _betIdController,
              label: 'Bet ID',
              icon: Icons.tag_rounded,
              validator: _required,
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _questionController,
              label: 'Question',
              icon: Icons.help_rounded,
              validator: _required,
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.notes_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _result,
                    decoration: _inputDecoration('Result', Icons.check_rounded),
                    dropdownColor: const Color(0xFF1E1E1E),
                    items: const [
                      DropdownMenuItem(value: 'YES', child: Text('YES')),
                      DropdownMenuItem(value: 'NO', child: Text('NO')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _result = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _accentColor,
                    decoration: _inputDecoration('Accent', Icons.palette_rounded),
                    dropdownColor: const Color(0xFF1E1E1E),
                    items: const [
                      DropdownMenuItem(value: 'orange', child: Text('Orange')),
                      DropdownMenuItem(value: 'blue', child: Text('Blue')),
                      DropdownMenuItem(value: 'red', child: Text('Red')),
                      DropdownMenuItem(value: 'green', child: Text('Green')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _accentColor = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickResultTime,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: _inputDecoration('Result time', Icons.event_rounded),
                child: Text(
                  _resultTime == null
                      ? 'Choose date and time'
                      : _formatDateTime(_resultTime!),
                  style: TextStyle(
                    color: _resultTime == null ? Colors.white54 : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isTrending,
              onChanged: (value) => setState(() => _isTrending = value),
              title: const Text('Mark as trending'),
              activeColor: const Color(0xFFFF5722),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  final String submitLabel;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _AdminDialogShell({
    required this.title,
    required this.child,
    required this.submitLabel,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF16171B),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(child: child),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5722),
            foregroundColor: Colors.white,
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(submitLabel),
        ),
      ],
    );
  }
}

class _SetResultDialog extends StatefulWidget {
  final String betId;

  const _SetResultDialog({required this.betId});

  @override
  State<_SetResultDialog> createState() => _SetResultDialogState();
}

class _SetResultDialogState extends State<_SetResultDialog> {
  final _formKey = GlobalKey<FormState>();
  String _result = 'YES';
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await apiService.resolveBet(
        betId: widget.betId,
        result: _result,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AdminDialogShell(
      title: 'Resolve Bet',
      isSubmitting: _isSubmitting,
      submitLabel: 'RESOLVE',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set the result for ${widget.betId}. This will close the bet and distribute the winnings automatically. This action cannot be undone.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _result,
              decoration: _inputDecoration('Result', Icons.check_rounded),
              dropdownColor: const Color(0xFF1E1E1E),
              items: const [
                DropdownMenuItem(value: 'YES', child: Text('YES')),
                DropdownMenuItem(value: 'NO', child: Text('NO')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _result = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _AdminTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon),
    );
  }
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white54),
    prefixIcon: Icon(icon, color: Colors.white54),
    filled: true,
    fillColor: const Color(0xFF202126),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFFF5722)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEB5B3C)),
    ),
  );
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'Required';
  return null;
}

String? _positiveNumber(String? value) {
  final number = double.tryParse(value?.trim() ?? '');
  if (number == null || number <= 0) return 'Enter a positive number';
  return null;
}

String? _optionalPositiveNumber(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return _positiveNumber(value);
}

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} $hour:$minute';
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.toString().replaceFirst('Exception: ', '')),
      backgroundColor: const Color(0xFFEB5B3C),
    ),
  );
}
