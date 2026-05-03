// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure   = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(AuthLoginRequested(
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.error_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(state.message)),
            ]),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
            margin: const EdgeInsets.all(16),
          ));
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity : _fadeAnim,
                  child   : SlideTransition(
                    position: _slideAnim,
                    child   : ConstrainedBox(
                      constraints:
                      const BoxConstraints(maxWidth: 380),
                      child: Column(
                        children: [
                          // Logo
                          Container(
                            width : 72, height: 72,
                            decoration: BoxDecoration(
                              color : Colors.white.withOpacity(0.15),
                              shape : BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white30, width: 2),
                            ),
                            child: const Icon(Icons.school_rounded,
                                size: 38, color: Colors.white),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'SMK NEGERI 1 SIGUMPAR',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color      : Colors.white,
                              fontSize   : 15,
                              fontWeight : FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sistem Informasi Akademik',
                            style: TextStyle(
                              color   : Color(0xFFBBDEFB),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Form Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color       : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow   : [
                                BoxShadow(
                                  color     : Colors.black
                                      .withOpacity(0.15),
                                  blurRadius: 20,
                                  offset    : const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text('Masuk',
                                      style: TextStyle(
                                        fontSize  : 20,
                                        fontWeight: FontWeight.w700,
                                        color     : AppColors.textPrimary,
                                      )),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Masukkan username dan password Anda',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color   : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 22),

                                  // Username
                                  const _Label('Username'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _userCtrl,
                                    decoration: const InputDecoration(
                                      hintText  : 'Masukkan username',
                                      prefixIcon: Icon(
                                          Icons.person_outline_rounded,
                                          size: 20),
                                      isDense: true,
                                    ),
                                    textInputAction:
                                    TextInputAction.next,
                                    validator: (v) =>
                                    v == null || v.isEmpty
                                        ? 'Username tidak boleh kosong'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Password
                                  const _Label('Password'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller : _passCtrl,
                                    obscureText: _obscure,
                                    decoration : InputDecoration(
                                      hintText  : 'Masukkan password',
                                      prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                          size: 20),
                                      isDense   : true,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                                () => _obscure = !_obscure),
                                      ),
                                    ),
                                    textInputAction:
                                    TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    validator: (v) =>
                                    v == null || v.isEmpty
                                        ? 'Password tidak boleh kosong'
                                        : null,
                                  ),
                                  const SizedBox(height: 22),

                                  // Button
                                  BlocBuilder<AuthBloc, AuthState>(
                                    builder: (context, state) {
                                      final loading =
                                      state is AuthLoading;
                                      return SizedBox(
                                        width : double.infinity,
                                        height: 46,
                                        child : ElevatedButton(
                                          onPressed: loading
                                              ? null : _submit,
                                          style: ElevatedButton
                                              .styleFrom(
                                            backgroundColor:
                                            AppColors.primary,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: loading
                                              ? const SizedBox(
                                            width : 20,
                                            height: 20,
                                            child : CircularProgressIndicator(
                                              color      : Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                              : const Text(
                                            'MASUK',
                                            style: TextStyle(
                                              fontSize     : 14,
                                              fontWeight   : FontWeight.w700,
                                              letterSpacing: 1.2,
                                              color        : Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            '© 2025 SMK Negeri 1 Sigumpar',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize  : 13,
      fontWeight: FontWeight.w600,
      color     : AppColors.textPrimary,
    ),
  );
}