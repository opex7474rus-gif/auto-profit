import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool isLogin = true;
  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Введите email и пароль');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Некорректный email');
      return;
    }
    if (password.length < 6) {
      _showMessage('Пароль должен быть не менее 6 символов');
      return;
    }
    if (!isLogin && password != confirmController.text) {
      _showMessage('Пароли не совпадают');
      return;
    }

    setState(() => loading = true);
    try {
      if (isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (!mounted) return;
        _showMessage('Вы вошли');
      } else {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (!mounted) return;
        _showMessage(
          'Проверьте почту $email — там письмо для подтверждения',
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(_russianError(e.message));
    } catch (e) {
      if (!mounted) return;
      _showMessage('Ошибка: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _russianError(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login')) return 'Неверный email или пароль';
    if (m.contains('email not confirmed')) {
      return 'Email не подтверждён. Проверьте почту';
    }
    if (m.contains('user already registered')) {
      return 'Такой email уже зарегистрирован';
    }
    if (m.contains('password')) return 'Пароль слишком простой';
    if (m.contains('rate limit')) {
      return 'Слишком много попыток. Подождите минуту';
    }
    if (m.contains('network')) return 'Нет соединения с интернетом';
    return msg;
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Сначала введите email');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      _showMessage('Письмо для сброса пароля отправлено на $email');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Ошибка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1B2E),
                    const Color(0xFF14151A),
                  ]
                : [
                    kSeedColor.withValues(alpha: 0.16),
                    const Color(0xFFF6F7FB),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4A4FC7),
                            Color(0xFF6D72E0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: kSeedColor.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Авто Профит',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLogin
                          ? 'Войдите в аккаунт'
                          : 'Создайте новый аккаунт',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.06,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: passwordController,
                            obscureText: !showPassword,
                            textInputAction: isLogin
                                ? TextInputAction.done
                                : TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(
                                  () => showPassword = !showPassword,
                                ),
                              ),
                            ),
                          ),
                          if (!isLogin) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: confirmController,
                              obscureText: !showPassword,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Повторите пароль',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isLogin
                                        ? 'Войти'
                                        : 'Зарегистрироваться',
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() {
                                isLogin = !isLogin;
                                passwordController.clear();
                                confirmController.clear();
                              }),
                      child: Text(
                        isLogin
                            ? 'Нет аккаунта? Зарегистрироваться'
                            : 'Уже есть аккаунт? Войти',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isLogin)
                      TextButton(
                        onPressed: loading ? null : _resetPassword,
                        child: const Text('Забыли пароль?'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
