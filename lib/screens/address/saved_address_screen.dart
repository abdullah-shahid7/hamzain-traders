import 'package:flutter/material.dart';
import 'package:hamzain_traders/models/address_model.dart';
import 'package:hamzain_traders/models/user_model.dart';
import 'package:hamzain_traders/services/address_service.dart';
import 'package:hamzain_traders/services/session_service.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';

/// Save Address screen (existing screen, kept in the Drawer).
///
/// Backed by the NEW `address` table + addaddress.php / getaddresses.php /
/// updateaddress.php / deleteaddress.php APIs. Supports add / edit /
/// delete / list, and — when opened from Checkout with
/// [selectionMode] true — lets the user tap an address to select it,
/// returning the chosen [AddressModel] via `Navigator.pop`.
class SavedAddressScreen extends StatefulWidget {
  final bool selectionMode;

  const SavedAddressScreen({super.key, this.selectionMode = false});

  @override
  State<SavedAddressScreen> createState() => _SavedAddressScreenState();
}

class _SavedAddressScreenState extends State<SavedAddressScreen> {
  final _addressService = AddressService();

  bool _isLoadingAddresses = true;
  String? _addressLoadError;
  UserModel? _currentUser;
  List<AddressModel> _savedAddresses = const [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await SessionService.instance.getUser();
    if (!mounted) return;
    setState(() => _currentUser = user);
    await _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final user = _currentUser;
    if (user == null) {
      setState(() => _isLoadingAddresses = false);
      return;
    }
    setState(() {
      _isLoadingAddresses = true;
      _addressLoadError = null;
    });
    try {
      final addresses = await _addressService.getAddresses(userId: user.id);
      if (!mounted) return;
      setState(() {
        _savedAddresses = addresses;
        _isLoadingAddresses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addressLoadError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingAddresses = false;
      });
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openForm({AddressModel? existing}) async {
    final user = _currentUser;
    if (user == null) {
      _showSnack('No active session found. Please log in again.', isError: true);
      return;
    }

    final saved = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddressFormSheet(
        userId: user.id,
        existing: existing,
        addressService: _addressService,
      ),
    );

    if (saved != null) {
      await _loadAddresses();
      if (!mounted) return;
      _showSnack(
        existing == null ? 'Address saved successfully' : 'Address updated successfully',
        isError: false,
      );
      if (widget.selectionMode) {
        // Newly added address should be immediately usable in Checkout.
        Navigator.pop(context, saved);
      }
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    final user = _currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _addressService.deleteAddress(id: address.id, userId: user.id);
      await _loadAddresses();
      if (mounted) _showSnack('Address deleted', isError: false);
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'Select Address' : 'Saved Address'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Address'),
      ),
      body: PremiumScreenBackground(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadAddresses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: _buildSavedAddressesSection(),
        ),
      ),
      ),
    );
  }

  Widget _buildSavedAddressesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Saved Addresses',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _buildAddressesBody(),
        ),
      ],
    );
  }

  Widget _buildAddressesBody() {
    if (_isLoadingAddresses) {
      return const Center(
        key: ValueKey('loading'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_addressLoadError != null) {
      // The raw backend message is deliberately not shown here — it's
      // a technical/API detail, not something a shopper needs to
      // read. A friendly, on-brand state with a clear next step
      // (retry, or just add an address) replaces it.
      return _AddressStateCard(
        key: const ValueKey('error'),
        icon: Icons.cloud_off_rounded,
        title: "We couldn't load your saved addresses",
        subtitle: 'Please check your connection and try again, or add a new delivery address below.',
        primaryLabel: 'Try Again',
        onPrimaryPressed: _loadAddresses,
        secondaryLabel: 'Add Address',
        onSecondaryPressed: () => _openForm(),
      );
    }

    if (_savedAddresses.isEmpty) {
      return _AddressStateCard(
        key: const ValueKey('empty'),
        icon: Icons.location_off_outlined,
        title: 'No saved addresses yet',
        subtitle: 'Add your first delivery address to speed up checkout next time.',
        primaryLabel: 'Add Address',
        onPrimaryPressed: () => _openForm(),
      );
    }

    return Column(
      key: const ValueKey('list'),
      children: _savedAddresses
          .map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AddressCard(
                address: a,
                selectionMode: widget.selectionMode,
                onSelect: () => Navigator.pop(context, a),
                onEdit: () => _openForm(existing: a),
                onDelete: () => _deleteAddress(a),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AddressStateCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  const _AddressStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  @override
  State<_AddressStateCard> createState() => _AddressStateCardState();
}

class _AddressStateCardState extends State<_AddressStateCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.08).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _iconScale,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(widget.icon, color: AppColors.primary, size: 30),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 6),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              if (widget.secondaryLabel != null)
                OutlinedButton(
                  onPressed: widget.onSecondaryPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.secondaryLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ElevatedButton(
                onPressed: widget.onPrimaryPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.primaryLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool selectionMode;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.address,
    required this.selectionMode,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: selectionMode ? onSelect : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            address.addressType,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      address.fullName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address.oneLineSummary,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                    ),
                    if (address.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(address.phone, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ),
              if (!selectionMode)
                Column(
                  children: [
                    InkWell(
                      onTap: onEdit,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade500),
                      ),
                    ),
                    InkWell(
                      onTap: onDelete,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                      ),
                    ),
                  ],
                )
              else
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add / Edit address form, shown as a scrollable bottom sheet.
class _AddressFormSheet extends StatefulWidget {
  final String userId;
  final AddressModel? existing;
  final AddressService addressService;

  const _AddressFormSheet({
    required this.userId,
    required this.existing,
    required this.addressService,
  });

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _areaController;
  late final TextEditingController _notesController;
  late String _selectedType;
  bool _isSubmitting = false;

  final List<String> _types = const ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _fullNameController = TextEditingController(text: e?.fullName ?? '');
    _phoneController = TextEditingController(text: e?.phone ?? '');
    _emailController = TextEditingController(text: e?.email ?? '');
    _addressController = TextEditingController(text: e?.address ?? '');
    _cityController = TextEditingController(text: e?.city ?? '');
    _areaController = TextEditingController(text: e?.area ?? '');
    _notesController = TextEditingController(text: e?.addressNotes ?? '');
    _selectedType = e?.addressType.isNotEmpty == true ? e!.addressType : 'Home';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await widget.addressService.addAddress(
          userId: widget.userId,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          area: _areaController.text.trim(),
          addressNotes: _notesController.text.trim(),
          addressType: _selectedType,
        );
      } else {
        await widget.addressService.updateAddress(
          id: existing.id,
          userId: widget.userId,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          area: _areaController.text.trim(),
          addressNotes: _notesController.text.trim(),
          addressType: _selectedType,
        );
      }

      if (!mounted) return;

      final resultAddress = AddressModel(
        id: existing?.id ?? '',
        userId: widget.userId,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        addressNotes: _notesController.text.trim(),
        addressType: _selectedType,
        createdAt: existing?.createdAt ?? '',
        updatedAt: existing?.updatedAt ?? '',
      );
      Navigator.pop(context, resultAddress);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.existing == null ? 'Add New Address' : 'Edit Address',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _fullNameController,
                  decoration: _inputDecoration('Full Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Phone'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: _inputDecoration('Full Address'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: _inputDecoration('City'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'City is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _areaController,
                        decoration: _inputDecoration('Area'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Area is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: _inputDecoration('Address Notes (optional)'),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Address Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _types.map((type) {
                    final selected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedType = type),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.primarySoft,
                      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.primaryDark, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                          )
                        : Text(
                            widget.existing == null ? 'Save Address' : 'Update Address',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
