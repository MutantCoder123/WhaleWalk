import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/api_service.dart';
import '../../core/state/app_state.dart';

class AdminView extends ConsumerStatefulWidget {
  const AdminView({super.key});

  @override
  ConsumerState<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends ConsumerState<AdminView> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _stocks = [];
  List<dynamic> _bets = [];
  List<dynamic> _zones = [];

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
        apiService.fetchZones(),
      ]);

      setState(() {
        _stocks = results[0];
        _bets = results[1];
        _zones = results[2];
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

  Future<void> _openCreateZoneDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreateZoneDialog(),
    );

    if (created == true) {
      await _loadAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zone created successfully'),
          backgroundColor: Color(0xFF00D09C),
        ),
      );
    }
  }

  Future<void> _openEditZoneDialog(Map<String, dynamic> zone) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => _CreateZoneDialog(initialZone: zone),
    );

    if (updated == true) {
      await _loadAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zone updated successfully'),
          backgroundColor: Color(0xFF00D09C),
        ),
      );
    }
  }

  Future<void> _deleteZone(String id) async {
    try {
      await apiService.deleteZone(id);
      await _loadAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting zone: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteStock(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stock?'),
        content: const Text('This action cannot be undone and may affect active orders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await apiService.deleteStock(id);
      await _loadAdminData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0E12),
      ),
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
            ),
            SliverFillRemaining(
              child: _buildBody(),
            ),
          ],
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

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _SquareActionCard(
              icon: Icons.candlestick_chart_rounded,
              title: 'STOCKS\nMGNT',
              color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => _AdminStocksPage(
                stocks: _stocks, 
                onAdd: _openCreateStockDialog,
                onDelete: _deleteStock,
              ))),
            ),
            _SquareActionCard(
              icon: Icons.flag_rounded,
              title: 'CHALLENGES\nMGNT',
              color: Colors.orange,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => _AdminBetsPage(
                title: 'CHALLENGES',
                bets: _bets.where((b) => b['isTrending'] == true).toList(), 
                onAdd: () => _openCreateBetDialog(title: 'Create Challenge'),
                onSetResult: _openSetResultDialog,
              ))),
            ),
            _SquareActionCard(
              icon: Icons.fact_check_rounded,
              title: 'BETS\nMGNT',
              color: Colors.purple,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => _AdminBetsPage(
                title: 'BETS',
                bets: _bets.where((b) => b['isTrending'] != true).toList(), 
                onAdd: () => _openCreateBetDialog(title: 'Create Bet'),
                onSetResult: _openSetResultDialog,
              ))),
            ),
          ],
        ),
        const SizedBox(height: 36),
        const Text("CAMPUS ZONES MANAGEMENT", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
        const SizedBox(height: 16),
        _buildAdminMapControl(),
        const SizedBox(height: 16),
        _buildZonesSection(),
      ],
    );
  }

  Widget _buildAdminMapControl() {
    final wallet = ref.watch(walletProvider);
    final userPos = (wallet.userLat != null && wallet.userLng != null) 
        ? LatLng(wallet.userLat!, wallet.userLng!) 
        : const LatLng(25.5358, 84.8510);

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: userPos,
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
            userAgentPackageName: 'com.example.app',
          ),
          CircleLayer(
            circles: _zones.map((z) => CircleMarker(
              point: LatLng((z['latitude'] ?? 0.0).toDouble(), (z['longitude'] ?? 0.0).toDouble()),
              color: Colors.blue.withOpacity(0.3),
              borderColor: Colors.blue,
              borderStrokeWidth: 2,
              useRadiusInMeter: true,
              radius: (z['radiusMeters'] ?? 50.0).toDouble(),
            )).toList(),
          ),
          MarkerLayer(
            markers: [
              ..._zones.map((z) => Marker(
                point: LatLng((z['latitude'] ?? 0.0).toDouble(), (z['longitude'] ?? 0.0).toDouble()),
                width: 80,
                height: 40,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      z['name'] ?? 'Zone',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )),
              if (wallet.userLat != null && wallet.userLng != null)
                Marker(
                  point: LatLng(wallet.userLat!, wallet.userLng!),
                  width: 60,
                  height: 60,
                  child: const _UserLocationMarker(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZonesSection() {
    if (_zones.isEmpty) {
      return _EmptyState(
        icon: Icons.map_rounded,
        title: 'No zones active',
        message: 'No location tracking bubbles map.',
        action: _CreateButton(
           label: 'DEFINE NEW ZONE',
           icon: Icons.add_location_alt_rounded,
           onPressed: _openCreateZoneDialog,
        ),
      );
    }

    return Column(
      children: [
        ..._zones.map((zone) {
          return _AdminTile(
            icon: Icons.location_on_rounded,
            accent: Colors.pinkAccent,
            title: zone['name'] ?? 'Unknown',
            subtitle: '${zone['latitude']}, ${zone['longitude']}',
            trailing: '${zone['radiusMeters']}m',
            meta: 'Boundary configuration active',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white38, size: 20),
                  onPressed: () => _openEditZoneDialog(zone),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.white38, size: 20),
                  onPressed: () => _deleteZone(zone['_id']),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        _CreateButton(
           label: 'DEFINE NEW ZONE',
           icon: Icons.add_location_alt_rounded,
           onPressed: _openCreateZoneDialog,
        ),
      ],
    );
  }

  Widget _buildStocksList() {
    if (_stocks.isEmpty) return const SizedBox.shrink();
    return Column(
      children: _stocks.map((stock) {
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
          action: IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38),
            onPressed: () => _deleteStock(stock['_id']),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _SquareActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _SquareActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
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

class _CreateZoneDialog extends StatefulWidget {
  final Map<String, dynamic>? initialZone;
  const _CreateZoneDialog({this.initialZone});
  @override
  State<_CreateZoneDialog> createState() => _CreateZoneDialogState();
}

class _CreateZoneDialogState extends State<_CreateZoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _radiusController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialZone?['name']);
    _latController = TextEditingController(text: widget.initialZone?['latitude']?.toString());
    _lngController = TextEditingController(text: widget.initialZone?['longitude']?.toString());
    _radiusController = TextEditingController(text: widget.initialZone?['radiusMeters']?.toString() ?? '50.0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      if (widget.initialZone != null) {
        await apiService.updateZone(
          id: widget.initialZone!['_id'],
          name: _nameController.text.trim(),
          latitude: double.parse(_latController.text.trim()),
          longitude: double.parse(_lngController.text.trim()),
          radiusMeters: double.parse(_radiusController.text.trim()),
        );
      } else {
        await apiService.createZone(
          name: _nameController.text.trim(),
          latitude: double.parse(_latController.text.trim()),
          longitude: double.parse(_lngController.text.trim()),
          radiusMeters: double.parse(_radiusController.text.trim()),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AdminDialogShell(
      title: widget.initialZone != null ? 'Edit Zone' : 'Define New Zone',
      isSubmitting: _isSubmitting,
      submitLabel: widget.initialZone != null ? 'UPDATE ZONE' : 'CREATE ZONE',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AdminTextField(
              controller: _nameController,
              label: 'Zone Name (e.g Library)',
              icon: Icons.title_rounded,
              validator: _required,
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _latController,
              label: 'Latitude (e.g 25.535)',
              icon: Icons.map_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: _required,
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _lngController,
              label: 'Longitude (e.g 84.851)',
              icon: Icons.map_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: _required,
            ),
            const SizedBox(height: 12),
            _AdminTextField(
              controller: _radiusController,
              label: 'Radius (Meters)',
              icon: Icons.radar_rounded,
              keyboardType: TextInputType.number,
              validator: _positiveNumber,
            ),
          ],
        ),
      ),
    );
  }
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

class _AdminStocksPage extends StatelessWidget {
  final List<dynamic> stocks;
  final VoidCallback onAdd;
  final Function(String) onDelete;

  const _AdminStocksPage({
    required this.stocks,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('STOCKS MANAGEMENT'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _CreateButton(
            label: 'ADD NEW STOCK',
            icon: Icons.add_chart_rounded,
            onPressed: onAdd,
          ),
          const SizedBox(height: 24),
          if (stocks.isEmpty)
            const _EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No stocks found',
              message: 'Add some stocks to see them here.',
            )
          else
            ...stocks.map((stock) {
              final price = (stock['price'] ?? 0).toDouble();
              final previousPrice = (stock['previousPrice'] ?? 0).toDouble();
              final isUp = price >= previousPrice;
              return _AdminTile(
                icon: Icons.show_chart_rounded,
                accent: isUp ? const Color(0xFF00D09C) : const Color(0xFFEB5B3C),
                title: stock['name'] ?? 'Unnamed',
                subtitle: stock['stockId'] ?? 'UNK',
                trailing: '${price.toStringAsFixed(2)} CMX',
                meta: 'Shares: ${stock['sharesct'] ?? 0}',
                action: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38),
                  onPressed: () => onDelete(stock['_id']),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AdminBetsPage extends StatelessWidget {
  final String title;
  final List<dynamic> bets;
  final VoidCallback onAdd;
  final Function(String) onSetResult;

  const _AdminBetsPage({
    required this.title,
    required this.bets,
    required this.onAdd,
    required this.onSetResult,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('$title MANAGEMENT'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _CreateButton(
            label: 'ADD NEW ${title.toUpperCase()}',
            icon: Icons.add_task_rounded,
            onPressed: onAdd,
          ),
          const SizedBox(height: 24),
          if (bets.isEmpty)
             _EmptyState(
              icon: Icons.assignment_late_outlined,
              title: 'No $title found',
              message: 'Define some to start tracking.',
            )
          else
            ...bets.map((bet) {
              final isClosed = bet['status'] == 'closed';
              return _AdminTile(
                icon: isClosed ? Icons.lock_clock_rounded : Icons.pending_actions_rounded,
                accent: isClosed ? Colors.grey : Colors.purpleAccent,
                title: bet['question'] ?? 'No question',
                subtitle: 'ID: ${bet['_id']}',
                trailing: '${bet['totalPool'] ?? 0} CMX',
                meta: isClosed ? 'STATUS: CLOSED' : 'STATUS: ACTIVE',
                action: isClosed ? null : IconButton(
                  icon: const Icon(Icons.fact_check_rounded, color: Colors.white70),
                  onPressed: () => onSetResult(bet['_id']),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF2962FF).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: Color(0xFF2962FF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
