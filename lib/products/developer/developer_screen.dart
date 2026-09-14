import 'dart:convert';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GetStorage _storage = GetStorage();

  // API Live test inputs
  final _mobileController = TextEditingController();
  final _entityIdController = TextEditingController(text: "ANKIT9470");
  final _refreshTokenController = TextEditingController();
  String _apiResponseLog = "No requests fired yet.";
  bool _isApiTesting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refreshTokenController.text =
        _storage.read<String>('refreshToken') ??
        _storage.read<String>('refresh_token') ??
        '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mobileController.dispose();
    _entityIdController.dispose();
    _refreshTokenController.dispose();
    super.dispose();
  }

  // Reload the storage view
  void _refreshStorage() {
    setState(() {});
  }

  // Storage Edit Dialog
  void _showEditDialog(String key, dynamic currentValue) {
    final valueController = TextEditingController(
      text: currentValue?.toString() ?? '',
    );
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Text(
          'Edit Key: $key',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: valueController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new value',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFFD500)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD500),
            ),
            onPressed: () async {
              String enteredText = valueController.text.trim();
              dynamic parsedValue = enteredText;

              // Simple type parsing helper
              if (enteredText.toLowerCase() == 'true') {
                parsedValue = true;
              } else if (enteredText.toLowerCase() == 'false') {
                parsedValue = false;
              } else if (double.tryParse(enteredText) != null) {
                parsedValue = double.parse(enteredText);
              }

              await _storage.write(key, parsedValue);
              Get.back();
              _refreshStorage();
              AppSnackbar.success(
                "Key '$key' updated successfully.",
                title: "Updated",
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // Add Key Dialog
  void _showAddKeyDialog() {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Add New Key-Value Pair',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Key',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFD500)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Value',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFD500)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD500),
            ),
            onPressed: () async {
              final key = keyController.text.trim();
              final value = valueController.text.trim();
              if (key.isEmpty) return;

              dynamic parsedValue = value;
              if (value.toLowerCase() == 'true') {
                parsedValue = true;
              } else if (value.toLowerCase() == 'false') {
                parsedValue = false;
              } else if (double.tryParse(value) != null) {
                parsedValue = double.parse(value);
              }

              await _storage.write(key, parsedValue);
              Get.back();
              _refreshStorage();
              AppSnackbar.success(
                "Key '$key' saved successfully.",
                title: "Created",
              );
            },
            child: const Text('Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // Live OTP test caller
  Future<void> _testSendOtpApi() async {
    setState(() {
      _isApiTesting = true;
      _apiResponseLog = "Firing request to /api/v1/auth/otp/send..";
    });

    try {
      final response = await ApiService.to.postRequest<Map<String, dynamic>>(
        '/api/v1/auth/otp/send',
        {"mobileNumber": _mobileController.text.trim()},
      );

      final prettyJson = const JsonEncoder.withIndent('  ').convert({
        'statusCode': response.statusCode,
        'statusText': response.statusText,
        'headers': response.headers,
        'body': response.body,
      });

      setState(() {
        _apiResponseLog = prettyJson;
      });
    } catch (e) {
      setState(() {
        _apiResponseLog = "Request failed:\n$e";
      });
    } finally {
      setState(() {
        _isApiTesting = false;
      });
    }
  }

  // Live Token Refresh test caller
  Future<void> _testRefreshTokenApi() async {
    final token = _refreshTokenController.text.trim();
    if (token.isEmpty) {
      AppSnackbar.error("Refresh token is required to test refresh");
      return;
    }

    setState(() {
      _isApiTesting = true;
      _apiResponseLog =
          "Calling POST /api/v1/auth/refresh\nBody: {\n  \"refreshToken\": \"$token\"\n}...";
    });

    try {
      final success = await ApiService.to.refreshToken(
        customRefreshToken: token,
      );
      final storedAccessToken =
          _storage.read<String>('accessToken') ??
          _storage.read<String>('auth_token');
      final storedRefreshToken = _storage.read<String>('refreshToken');

      final logData = {
        'refreshSuccess': success,
        'storedAccessToken': storedAccessToken,
        'storedRefreshToken': storedRefreshToken,
        'timestamp': DateTime.now().toIso8601String(),
      };

      setState(() {
        _apiResponseLog = const JsonEncoder.withIndent('  ').convert(logData);
      });

      if (success) {
        AppSnackbar.success("Token refreshed successfully!");
      } else {
        AppSnackbar.error("Failed to refresh token.");
      }
    } catch (e) {
      setState(() {
        _apiResponseLog = "Refresh exception:\n$e";
      });
    } finally {
      setState(() {
        _isApiTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        backgroundColor: Colors.transparent,
        elevation: 4,
        title: const Text(
          'Developer Control Center',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD500),
          labelColor: const Color(0xFFFFD500),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: Icon(Icons.manage_accounts_rounded),
              text: "Remember Me & Auth",
            ),
            Tab(icon: Icon(Icons.api_rounded), text: "API Explorer"),
            Tab(icon: Icon(Icons.storage_rounded), text: "Storage Explorer"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Remember Me & Auth Tab
          _buildRememberMeAuthTab(),

          // 2. API Explorer Tab
          _buildApiExplorerTab(),

          // 3. Storage Explorer Tab
          _buildStorageExplorerTab(),
        ],
      ),
    );
  }

  Widget _buildApiExplorerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "API Configuration",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            "Base URL",
            ApiService.to.httpClient.baseUrl ?? 'Not set',
            icon: Icons.link,
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            "Common Headers Included",
            "TENANT: TRANSCORPAPP\npartnerId: TRANSCORPAPP\npartnerToken: Basic VENYT1hPREFZ",
            icon: Icons.vpn_key_rounded,
          ),
          const SizedBox(height: 24),
          const Text(
            "Live Connection Test: Generate OTP",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "POST /kyc/customer/generate/otp",
                  style: TextStyle(
                    color: Color(0xFFFFD500),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _entityIdController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: "entityId",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFD500)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _mobileController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: "mobileNumber (without country code)",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFD500)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD500),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: _isApiTesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      _isApiTesting ? "Running..." : "Test Connection",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isApiTesting ? null : _testSendOtpApi,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Live Connection Test: Token Refresh",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "POST /api/v1/auth/refresh",
                  style: TextStyle(
                    color: Color(0xFFFFD500),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _refreshTokenController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "refreshToken",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFD500)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD500),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: _isApiTesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(
                      _isApiTesting ? "Refreshing..." : "Test Refresh Token",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isApiTesting ? null : _testRefreshTokenApi,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Response Logs",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Stack(
              children: [
                SelectableText(
                  _apiResponseLog,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.copy_all,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _apiResponseLog));
                      AppSnackbar.success(
                        "Response logs copied to clipboard.",
                        title: "Copied",
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStorageExplorerTab() {
    // Collect all active storage keys
    final keys = _storage.getKeys().toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${keys.length} stored key-value pairs",
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text("Clear All"),
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      backgroundColor: const Color(0xFF1E1E2E),
                      title: const Text(
                        "Clear all storage?",
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        "This will delete all persistent tokens and settings.",
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () async {
                            await _storage.erase();
                            Get.back();
                            _refreshStorage();
                            AppSnackbar.success(
                              "All storage has been cleared.",
                              title: "Erased",
                            );
                          },
                          child: const Text("Erase"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: keys.isEmpty
                ? const Center(
                    child: Text(
                      "No keys stored locally yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: keys.length,
                    itemBuilder: (context, index) {
                      final key = keys[index].toString();
                      final val = _storage.read(key);
                      return Card(
                        color: const Color(0xFF1E1E2E),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            key,
                            style: const TextStyle(
                              color: Color(0xFFFFD500),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            val?.toString() ?? 'null',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                                onPressed: () => _showEditDialog(key, val),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  await _storage.remove(key);
                                  _refreshStorage();
                                  AppSnackbar.success(
                                    "Key '$key' removed.",
                                    title: "Deleted",
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD500),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                "Add Custom Storage Key",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _showAddKeyDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, {required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD500), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRememberMeAuthTab() {
    final bool isRememberMe = _storage.read<bool>('remember_me') ?? true;
    final String rememberedName =
        _storage.read<String>('remembered_name') ??
        _storage.read<String>('name') ??
        '';
    final String rememberedPhone =
        _storage.read<String>('remembered_phone') ??
        _storage.read<String>('phone') ??
        '';
    final bool hasToken =
        (_storage.read<String>('accessToken') ??
                _storage.read<String>('auth_token') ??
                '')
            .isNotEmpty;
    final String savedMpin = _storage.read<String>('saved_mpin') ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Remember Me & Saved Account",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Manage hidden Remember Me persistence and simulate account switching on the login screen.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Remember Me Toggle Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: const Color(0xFFFFD500),
                  title: const Text(
                    "Remember Me Enabled",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    isRememberMe
                        ? "Active: Logged-in accounts are preserved on logout and shown on login screen."
                        : "Disabled: Logout clears saved account details.",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  value: isRememberMe,
                  onChanged: (val) async {
                    await _storage.write('remember_me', val);
                    _refreshStorage();
                    AppSnackbar.success(
                      val
                          ? "Remember Me enabled."
                          : "Remember Me disabled. Saved accounts cleared.",
                      title: "Updated",
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            "Current Saved Account",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),

          // Saved Account Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: rememberedName.isNotEmpty
                          ? primaryRed
                          : Colors.grey.shade800,
                      child: Text(
                        rememberedName.isNotEmpty
                            ? (rememberedName.length >= 2
                                  ? rememberedName.substring(0, 2).toUpperCase()
                                  : rememberedName.toUpperCase())
                            : "?",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rememberedName.isNotEmpty
                                ? rememberedName
                                : "No Account Saved",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rememberedPhone.isNotEmpty
                                ? "+91 $rememberedPhone"
                                : "No phone number saved",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (rememberedName.isNotEmpty ||
                                rememberedPhone.isNotEmpty)
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (rememberedName.isNotEmpty ||
                                rememberedPhone.isNotEmpty)
                            ? "SAVED"
                            : "EMPTY",
                        style: TextStyle(
                          color:
                              (rememberedName.isNotEmpty ||
                                  rememberedPhone.isNotEmpty)
                              ? Colors.greenAccent
                              : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white12),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSessionBadge(
                        "Auth Token",
                        hasToken ? "Active" : "Logged Out",
                        hasToken ? Colors.greenAccent : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSessionBadge(
                        "MPIN",
                        savedMpin.isNotEmpty ? "Configured" : "Not Set",
                        savedMpin.isNotEmpty ? Colors.blueAccent : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            "Quick Testing Actions",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),

          // Preset Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.person_add_rounded,
                  color: Color(0xFFFFD500),
                  size: 18,
                ),
                label: const Text("Set Demo: Vince Tallent"),
                onPressed: () async {
                  await _storage.write('remember_me', true);
                  await _storage.write('remembered_name', 'Vince Tallent');
                  await _storage.write('remembered_phone', '9876543210');
                  _refreshStorage();
                  AppSnackbar.success(
                    "Set saved account to Vince Tallent (9876543210)",
                    title: "Saved",
                  );
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.greenAccent,
                  size: 18,
                ),
                label: const Text("Set Demo: Ankit Saini"),
                onPressed: () async {
                  await _storage.write('remember_me', true);
                  await _storage.write('remembered_name', 'Ankit Saini');
                  await _storage.write('remembered_phone', '9470876543');
                  _refreshStorage();
                  AppSnackbar.success(
                    "Set saved account to Ankit Saini (9470876543)",
                    title: "Saved",
                  );
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                  foregroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                  ),
                ),
                icon: const Icon(Icons.person_remove_rounded, size: 18),
                label: const Text("Clear Saved Account"),
                onPressed: () async {
                  await _storage.remove('remembered_name');
                  await _storage.remove('remembered_phone');
                  _refreshStorage();
                  AppSnackbar.info("Cleared remembered name and phone.");
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            "App Lock & Background Security",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Monitor background lock lifecycle, test 2-second timeout, and inspect biometric/MPIN fallback.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _buildAppLockDiagnosticsCard(),

          const SizedBox(height: 24),
          const Text(
            "Simulate Navigation",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),

          // Simulate Logout / Go to Login Screen Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD500),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.login_rounded),
              label: const Text(
                "Open Login Screen to Test",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () {
                Get.toNamed('/loginsingup');
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAppLockDiagnosticsCard() {
    final bool hasLockService = Get.isRegistered<AppLockService>();
    final bool appLockEnabled = _storage.read<bool>('app_lock_enabled') ?? true;
    final bool appLockTestMode =
        _storage.read<bool>('app_lock_test_mode') ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLockService)
            Obx(() {
              final lockService = AppLockService.to;
              final isLocked = lockService.isLocked.value;
              final canLock = lockService.canAppLock;
              final fails = lockService.biometricFailedAttempts.value;
              final elapsed = lockService.lastElapsedMs.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSessionBadge(
                        "Current State",
                        isLocked ? "LOCKED" : "UNLOCKED",
                        isLocked ? Colors.redAccent : Colors.greenAccent,
                      ),
                      _buildSessionBadge(
                        "Lock Eligible",
                        canLock ? "YES" : "NO",
                        canLock ? Colors.greenAccent : Colors.grey,
                      ),
                      _buildSessionBadge(
                        "Biometric Fails",
                        "$fails / 3",
                        fails > 3 ? Colors.redAccent : Colors.orangeAccent,
                      ),
                    ],
                  ),
                  if (elapsed > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Last background elapsed: ${elapsed}ms (Threshold: 2000ms)",
                      style: TextStyle(
                        color: elapsed >= 2000
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              );
            }),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Toggles
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: const Color(0xFFFFD500),
            title: const Text(
              "App Lock Active",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: const Text(
              "Monitors app lifecycle and locks after 2s in background.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            value: appLockEnabled,
            onChanged: (val) async {
              await _storage.write('app_lock_enabled', val);
              _refreshStorage();
              AppSnackbar.info(val ? "App Lock enabled." : "App Lock disabled.");
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: const Color(0xFFFFD500),
            title: const Text(
              "Test Mode (Lock on All Screens)",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: const Text(
              "Forces app lock to trigger even on onboarding and login screens.",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            value: appLockTestMode,
            onChanged: (val) async {
              await _storage.write('app_lock_test_mode', val);
              _refreshStorage();
              AppSnackbar.info(
                val
                    ? "Test Mode ON: App lock will trigger on any screen."
                    : "Test Mode OFF.",
              );
            },
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.redAccent, width: 1),
                    ),
                  ),
                  icon: const Icon(Icons.lock_outline_rounded, size: 16),
                  label: const Text(
                    "Lock Now",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    if (hasLockService) {
                      AppLockService.to.lockApp();
                      AppSnackbar.info("App locked manually.");
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A3E),
                    foregroundColor: const Color(0xFFFFD500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.timer_outlined, size: 16),
                  label: const Text(
                    "Simulate 2.5s BG",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    if (!hasLockService) return;
                    AppSnackbar.info("Simulating backgrounding for 2.5s...");
                    final service = AppLockService.to;
                    service.didChangeAppLifecycleState(AppLifecycleState.inactive);
                    service.didChangeAppLifecycleState(AppLifecycleState.paused);
                    await Future.delayed(const Duration(milliseconds: 2500));
                    service.didChangeAppLifecycleState(AppLifecycleState.inactive);
                    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF14141F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
