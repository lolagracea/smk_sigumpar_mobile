import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../common/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/role_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.go(
        RoleHelper.getHomeRouteByRole(
          auth.user?.role,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ─── Background Gradient ─────────────────────────
          Container(
            height: size.height * 0.45,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // ─── Logo & Title ───────────────────────
                  const Icon(
                    Icons.school_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.appShortName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sistem Informasi Sekolah',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ─── Login Card ─────────────────────────
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.loginTitle,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.loginSubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ─── Username Field ───────────
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              enabled: !auth.isLoading,
                              decoration: const InputDecoration(
                                labelText: AppStrings.username,
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Username tidak boleh kosong';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // ─── Password Field ───────────
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              enabled: !auth.isLoading,
                              onFieldSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                labelText: AppStrings.password,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: auth.isLoading
                                      ? null
                                      : () {
                                    setState(() {
                                      _obscurePassword =
                                      !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }

                                return null;
                              },
                            ),

                            // ─── Error Message ────────────
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.error,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        auth.errorMessage!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 28),

                            // ─── Login Button ─────────────
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                auth.isLoading ? null : _handleLogin,
                                child: auth.isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text(AppStrings.login),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    '© ${DateTime.now().year} SMK Negeri 1 Sigumpar',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}