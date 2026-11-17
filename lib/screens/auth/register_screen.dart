// ==============================================================================
// FILE: lib/screens/auth/register_screen.dart
// PANDUAN: Halaman pendaftaran akun baru.
// Menyimpan akun ke Hive Box 'usersBox' via AuthProvider.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_helpers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validasi seluruh input form
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.register(
      fullName: _fullNameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      AppHelpers.showSnackBar(
        context,
        'Registrasi berhasil! Silakan masuk dengan akun Anda.',
      );
      // Kembali ke halaman Login
      Navigator.pop(context);
    } else {
      AppHelpers.showSnackBar(
        context,
        authProvider.errorMessage ?? 'Registrasi gagal.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Buat Akun Anda',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Data tersimpan aman di database lokal Hive',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input Nama Lengkap
                  CustomTextField(
                    controller: _fullNameController,
                    labelText: 'Nama Lengkap',
                    hintText: 'Contoh: Rick Sanchez',
                    prefixIcon: Icons.badge_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama lengkap tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Username
                  CustomTextField(
                    controller: _usernameController,
                    labelText: 'Username',
                    hintText: 'Pilih username unik',
                    prefixIcon: Icons.person_outline,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Username tidak boleh kosong';
                      }
                      if (val.trim().length < 3) {
                        return 'Username minimal 3 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Email (Opsional)
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email (Opsional)',
                    hintText: 'Contoh: user@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Input Password
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: 'Minimal 4 karakter',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (val.length < 4) {
                        return 'Password minimal 4 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Konfirmasi Password
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Konfirmasi Password',
                    hintText: 'Ulangi password di atas',
                    prefixIcon: Icons.lock_reset_outlined,
                    isPassword: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Konfirmasi password wajib diisi';
                      }
                      if (val != _passwordController.text) {
                        return 'Password tidak cocok';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Tombol Daftar
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleRegister,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('DAFTAR SEKARANG'),
                  ),
                  const SizedBox(height: 20),

                  // Kembali ke Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun? '),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Masuk',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

