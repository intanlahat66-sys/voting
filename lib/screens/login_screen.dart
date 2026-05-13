import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _registeredUsersKey = 'registered_users';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegisterMode = false;
  String _selectedRole = 'mahasiswa';
  final List<Map<String, String>> _roles = [
    {'value': 'mahasiswa', 'label': 'Mahasiswa'},
    {'value': 'admin', 'label': 'Admin'},
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name');
    final userRole = prefs.getString('user_role') ?? 'mahasiswa';
    if (userName != null && mounted) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/voting',
          arguments: {'userName': userName, 'userRole': userRole},
        );
      }
    }
  }

  Future<Map<String, dynamic>> _loadRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_registeredUsersKey);
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return decoded;
  }

  Future<void> _saveRegisteredUsers(Map<String, dynamic> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registeredUsersKey, jsonEncode(users));
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan password tidak boleh kosong!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final users = await _loadRegisteredUsers();
    if (users.containsKey(name)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun sudah terdaftar, silakan login.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    users[name] = {'password': password, 'role': _selectedRole};
    await _saveRegisteredUsers(users);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_role', _selectedRole);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        '/voting',
        arguments: {'userName': name, 'userRole': _selectedRole},
      );
    }
  }

  Future<void> _login() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan password tidak boleh kosong!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final users = await _loadRegisteredUsers();
    final storedData = users[name] as Map<String, dynamic>?;

    if (storedData == null || storedData['password'] != password) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama atau password salah.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    final role = storedData['role'] as String? ?? 'mahasiswa';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_role', role);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        '/voting',
        arguments: {'userName': name, 'userRole': role},
      );
    }
  }

  LinearGradient get _pageGradient => const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF4338CA), Color(0xFF8B5CF6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  LinearGradient get _cardGradient => const LinearGradient(
        colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _pageGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: _cardGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.how_to_vote,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'E-Voting Dosen Informatika',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sistem Pemilihan Dosen Terbaik',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _isLoading ? null : () => setState(() => _isRegisterMode = false),
                              style: TextButton.styleFrom(
                                backgroundColor: !_isRegisterMode ? Colors.white : Colors.white10,
                                foregroundColor: !_isRegisterMode ? Colors.deepPurple : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  'Masuk',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextButton(
                              onPressed: _isLoading ? null : () => setState(() => _isRegisterMode = true),
                              style: TextButton.styleFrom(
                                backgroundColor: _isRegisterMode ? Colors.white : Colors.white10,
                                foregroundColor: _isRegisterMode ? Colors.deepPurple : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text(
                                  'Daftar',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _isRegisterMode ? 'Buat akun baru untuk memulai voting.' : 'Masuk dengan akun yang sudah terdaftar.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Masukkan username',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white, width: 2),
                          ),
                          prefixIcon: const Icon(Icons.person, color: Colors.white54),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (_) => _isRegisterMode ? _register() : _login(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Masukkan password',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white, width: 2),
                          ),
                          prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (_) => _isRegisterMode ? _register() : _login(),
                      ),
                      if (_isRegisterMode) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Daftar sebagai',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          items: _roles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role['value'],
                                  child: Text(role['label']!),
                                ),
                              )
                              .toList(),
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _selectedRole = value);
                                  }
                                },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white24),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          dropdownColor: const Color(0xFF312E81),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : (_isRegisterMode ? _register : _login),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Icon(_isRegisterMode ? Icons.app_registration : Icons.login),
                          label: Text(_isLoading ? 'Memproses...' : (_isRegisterMode ? 'Daftar' : 'Masuk')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B21B6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading ? null : () => setState(() => _isRegisterMode = !_isRegisterMode),
                        child: Text(
                          _isRegisterMode
                              ? 'Sudah punya akun? Masuk di sini'
                              : 'Belum punya akun? Daftar sekarang',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
