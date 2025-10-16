import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../models/contact.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';

class RoomLoginSheet extends StatefulWidget {
  final Contact contact;

  const RoomLoginSheet({super.key, required this.contact});

  @override
  State<RoomLoginSheet> createState() => _RoomLoginSheetState();
}

class _RoomLoginSheetState extends State<RoomLoginSheet> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoggingIn = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPassword();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Load saved password for this room
  Future<void> _loadSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final roomKey = 'room_password_${widget.contact.publicKeyHex}';
    final savedPassword = prefs.getString(roomKey);
    if (savedPassword != null) {
      _passwordController.text = savedPassword;
    }
  }

  /// Save password for this room
  Future<void> _savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final roomKey = 'room_password_${widget.contact.publicKeyHex}';
    await prefs.setString(roomKey, password);
  }

  Future<void> _loginToRoom() async {
    final password = _passwordController.text.trim();

    final connectionProvider = context.read<ConnectionProvider>();
    final contactsProvider = context.read<ContactsProvider>();

    if (password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseEnterPassword),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!connectionProvider.deviceInfo.isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deviceNotConnected),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    // 🕐 CLOCK DRIFT CHECK: Get device time to detect synchronization issues
    print('🕐 [RoomLogin] Checking for clock drift between app and radio...');
    try {
      await connectionProvider.getDeviceTime();
      // Give time for response to be logged
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('⚠️ [RoomLogin] Failed to get device time: $e');
      // Don't fail login - this is just a diagnostic check
    }

    // 🔍 PRE-LOGIN CHECK: Ensure room contact exists in device
    print('🔍 [RoomLogin] Checking if room "${widget.contact.advName}" exists in contacts...');
    print('   Target public key prefix: ${widget.contact.publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

    // Check if the room exists in our local contacts
    bool roomExists = contactsProvider.rooms.any(
      (room) => room.publicKeyHex == widget.contact.publicKeyHex,
    );

    print('   Local contact list: ${roomExists ? "✅ Found" : "❌ Not found"}');

    if (!roomExists) {
      print('⚠️ [RoomLogin] Room not in local contacts - syncing with device...');

      try {
        // Sync contacts from device
        await connectionProvider.getContacts();

        // Give time for contacts to be processed
        await Future.delayed(const Duration(milliseconds: 800));

        // Check again after sync
        roomExists = contactsProvider.rooms.any(
          (room) => room.publicKeyHex == widget.contact.publicKeyHex,
        );

        print('   After sync: ${roomExists ? "✅ Found" : "❌ Still not found"}');

        if (!roomExists) {
          // Room still doesn't exist on the device - try to add it manually
          print('❌ [RoomLogin] Room still not found after sync');
          print('🔧 [RoomLogin] Attempting to add room contact to companion radio...');

          try {
            // Manually add the room contact to the radio's flash storage
            await connectionProvider.addOrUpdateContact(widget.contact);

            print('✅ [RoomLogin] Room contact added via CMD_ADD_UPDATE_CONTACT');
            print('   Waiting 500ms for radio to save to flash...');

            // Give the radio time to save the contact to flash
            await Future.delayed(const Duration(milliseconds: 500));

            print('✅ [RoomLogin] Room contact should now be available - proceeding with login');
          } catch (e) {
            print('❌ [RoomLogin] Failed to add room contact: $e');

            if (!mounted) return;

            setState(() {
              _isLoggingIn = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.failedToAddRoom(e.toString())),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 7),
              ),
            );

            // Log available rooms for debugging
            final availableRooms = contactsProvider.rooms;
            print('📋 [RoomLogin] Available rooms on device (${availableRooms.length}):');
            for (final room in availableRooms) {
              print('   - ${room.advName} (${room.publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')})');
            }

            return;
          }
        }

        print('✅ [RoomLogin] Room contact found after sync - proceeding with login');
      } catch (e) {
        print('❌ [RoomLogin] Contact sync failed: $e');

        if (!mounted) return;

        setState(() {
          _isLoggingIn = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSyncContacts(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    } else {
      print('✅ [RoomLogin] Room contact found in local contacts - proceeding with login');
    }

    // Save password before sending
    await _savePassword(password);

    // Set up login callbacks
    Function(Uint8List, int, bool, int)? originalOnSuccess;
    Function(Uint8List)? originalOnFail;

    originalOnSuccess = connectionProvider.onLoginSuccess;
    originalOnFail = connectionProvider.onLoginFail;

    connectionProvider.onLoginSuccess = (publicKeyPrefix, permissions, isAdmin, tag) async {
      // Restore original callback
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;

      print('✅ [RoomLogin] Login successful! Tag: $tag, Permissions: $permissions, Admin: $isAdmin');
      print('📡 [RoomLogin] Room server will now push messages automatically via PUSH_CODE_MSG_WAITING');
      print('   Messages will be fetched when onMessageWaiting callback is triggered');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loggedInSuccessfully),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };

    connectionProvider.onLoginFail = (publicKeyPrefix) {
      // Restore original callback
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;

      print('❌ [RoomLogin] Login failed - incorrect password');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loginFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };

    try {
      // Send login request to room
      await connectionProvider.loginToRoom(
        roomPublicKey: widget.contact.publicKey,
        password: password,
      );

      _focusNode.unfocus();

      if (!mounted) return;
      Navigator.pop(context); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loggingIn(widget.contact.displayName)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Restore original callbacks on error
      connectionProvider.onLoginSuccess = originalOnSuccess;
      connectionProvider.onLoginFail = originalOnFail;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToSendLogin(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.loginToRoom,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.contact.displayName,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.onPrimaryContainer, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.enterPasswordInfo,
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Password input (fixed at bottom)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _passwordController,
                  focusNode: _focusNode,
                  maxLength: 15, // Max password length from protocol
                  obscureText: _obscurePassword,
                  autofocus: true,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    hintText: AppLocalizations.of(context)!.enterRoomPassword,
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loginToRoom(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoggingIn ? null : _loginToRoom,
                    icon: _isLoggingIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(_isLoggingIn ? AppLocalizations.of(context)!.loggingInDots : AppLocalizations.of(context)!.login),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
}
