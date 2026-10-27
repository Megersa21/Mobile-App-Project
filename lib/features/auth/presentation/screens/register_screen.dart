import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Accept exactly 10 digits beginning with 09 or 07.
  static final RegExp _phonePattern = RegExp(r'^(09|07)\d{8}$');

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final error = _requiredValidator(value, 'Phone number');
    if (error != null) return error;

    final phone = value!.trim();

    if (!_phonePattern.hasMatch(phone)) {
      return 'Enter a 10-digit number starting with 09 or 07';
    }

    return null;
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and privacy notice.'),
        ),
      );
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.137.5:5000/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final dynamic data = jsonDecode(response.body);

      if (!mounted) return;

      final message = data is Map ? data['message']?.toString() : null;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message ?? 'Registration successful! Please sign in.',
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'Registration failed. Please try again.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot connect to the server. Please try again.'),
        ),
      );

      debugPrint('Registration error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: colors.primary,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Join Digital Ekub',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Create your account to start your savings journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF718075),
                  ),
                ),
                const SizedBox(height: 30),

                const _FieldLabel('Full name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    final error = _requiredValidator(value, 'Full name');
                    if (error != null) return error;

                    if (value!.trim().length < 2) {
                      return 'Please enter your full name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),
                const _FieldLabel('Email address'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final error = _requiredValidator(value, 'Email');
                    if (error != null) return error;

                    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                    if (!emailPattern.hasMatch(value!.trim())) {
                      return 'Enter a valid email address';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),
                const _FieldLabel('Phone number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                    hintText: '0955362184 or 0755362184',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: _validatePhone,
                ),

                const SizedBox(height: 20),
                const _FieldLabel('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    hintText: 'At least 8 characters',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final error = _requiredValidator(value, 'Password');
                    if (error != null) return error;

                    if (value!.length < 8) {
                      return 'Password must be at least 8 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),
                const _FieldLabel('Confirm password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmPassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final error = _requiredValidator(value, 'Confirm password');
                    if (error != null) return error;

                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptedTerms = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I agree to the Terms of Service and Privacy Notice.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Identity verification and account approval '
                  'will follow the applicable verification process.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF718075),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF24382A),
      ),
    );
  }
}
