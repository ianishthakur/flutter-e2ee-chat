import 'dart:math';

import 'package:e2ee_chatapp/core/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'chat_room_screen.dart';

class JoinCreateScreen extends StatefulWidget {
  final String username;

  const JoinCreateScreen({super.key, required this.username});

  @override
  State<JoinCreateScreen> createState() => _JoinCreateScreenState();
}

class _JoinCreateScreenState extends State<JoinCreateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Join tab controllers
  final _joinFormKey = GlobalKey<FormState>();
  final _joinRoomIdController = TextEditingController();
  final _joinPinController = TextEditingController();
  final _joinRoomNameController = TextEditingController();

  // Create tab controllers
  final _createFormKey = GlobalKey<FormState>();
  final _createRoomNameController = TextEditingController();

  String? _generatedRoomId;
  String? _generatedPin;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 1 && _generatedRoomId != null) {
        setState(() {
          _generatedRoomId = null;
          _generatedPin = null;
        });
      }
    });
  }

  String _generatePin() {
    final random = Random.secure();
    return (1000 + random.nextInt(9000)).toString();
  }

  void _createRoom() {
    if (_createFormKey.currentState!.validate()) {
      setState(() {
        _generatedRoomId = const Uuid().v4().substring(0, 8);
        _generatedPin = _generatePin();
      });
    }
  }

  Future<void> _joinRoom(String roomId, String pin, String? roomName) async {
    setState(() => _isJoining = true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(
            username: widget.username,
            roomId: roomId,
            pin: pin,
            roomName: roomName,
          ),
        ),
      );

      if (result == false && mounted) {
        _showPinErrorDialog();
      }

      if (mounted) {
        _joinRoomIdController.clear();
        _joinPinController.clear();
        _joinRoomNameController.clear();
        _createRoomNameController.clear();
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPinErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: AppColors.error, size: 48),
        title: const Text('Incorrect PIN or Room ID'),
        content: const Text(
          'The PIN or Room ID you entered is incorrect. Please check with the room creator and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.username}'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Create Room'),
            Tab(icon: Icon(Icons.login), text: 'Join Room'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCreateTab(), _buildJoinTab()],
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _createFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.meeting_room, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Create a New Chat Room',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _createRoomNameController,
              decoration: InputDecoration(
                labelText: 'Room Name',
                hintText: 'e.g., Project Discussion',
                prefixIcon: const Icon(Icons.chat_bubble_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a room name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_generatedRoomId == null)
              FilledButton.icon(
                onPressed: _createRoom,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Generate Room ID & PIN'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 48,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Room Created!',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      _buildInfoRow('Room ID', _generatedRoomId!),
                      const SizedBox(height: 12),
                      _buildInfoRow('PIN', _generatedPin!),
                      const SizedBox(height: 24),
                      Text(
                        'Share these credentials with others to let them join',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _joinRoom(
                          _generatedRoomId!,
                          _generatedPin!,
                          _createRoomNameController.text.trim(),
                        ),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Enter Room'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(
          AppColors.surfaceContainerColor(context),
          0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _copyToClipboard(value, label),
            icon: Icon(Icons.copy, color: AppColors.primary),
            tooltip: 'Copy $label',
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _joinFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.vpn_key, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Join an Existing Room',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Get the Room ID and PIN from the room creator',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _joinRoomIdController,
              decoration: InputDecoration(
                labelText: 'Room ID',
                hintText: 'Enter room ID',
                prefixIcon: const Icon(Icons.tag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a room ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _joinPinController,
              decoration: InputDecoration(
                labelText: 'PIN',
                hintText: 'Enter 4-digit PIN',
                prefixIcon: const Icon(Icons.pin),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a PIN';
                }
                if (value.length < 4) {
                  return 'PIN must be at least 4 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _joinRoomNameController,
              decoration: InputDecoration(
                labelText: 'Room Name (Optional)',
                hintText: 'e.g., John\'s Chat',
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isJoining
                  ? null
                  : () {
                      if (_joinFormKey.currentState!.validate()) {
                        _joinRoom(
                          _joinRoomIdController.text.trim(),
                          _joinPinController.text.trim(),
                          _joinRoomNameController.text.trim().isNotEmpty
                              ? _joinRoomNameController.text.trim()
                              : null,
                        );
                      }
                    },
              icon: _isJoining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textOnPrimary,
                        ),
                      ),
                    )
                  : const Icon(Icons.arrow_forward),
              label: Text(_isJoining ? 'Joining...' : 'Join Room'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.withOpacity(AppColors.primaryLight, 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.withOpacity(AppColors.primary, 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Make sure you have the correct PIN. Wrong PIN will prevent you from reading messages.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _joinRoomIdController.dispose();
    _joinPinController.dispose();
    _createRoomNameController.dispose();
    _joinRoomNameController.dispose();
    super.dispose();
  }
}
