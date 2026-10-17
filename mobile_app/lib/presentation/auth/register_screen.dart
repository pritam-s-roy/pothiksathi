import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../models/user_model.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  UserRole _selectedRole = UserRole.passenger;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _licenseOrIdController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vehicleNumberController.dispose();
    _licenseOrIdController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.register(
      name: _nameController.text,
      phoneNumber: _phoneController.text,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      role: _selectedRole,
      vehicleNumber: _selectedRole == UserRole.driver ? _vehicleNumberController.text : null,
      licenseOrId: _selectedRole == UserRole.driver ? _licenseOrIdController.text : null,
    );

    if (success && mounted) {
      Navigator.pop(context); // Returns to AuthGate which routes properly
    } else if (mounted && authService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage!),
          backgroundColor: AppColors.statusCancelled,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'I want to register as:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // inDrive Role Selector Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleCard(
                          title: 'Passenger',
                          bengali: 'যাত্রী',
                          role: UserRole.passenger,
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRoleCard(
                          title: 'Captain / Driver',
                          bengali: 'চালক',
                          role: UserRole.driver,
                          icon: Icons.electric_rickshaw,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Full Name
                  const Text('Full Name (পুরো নাম)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'e.g. Sourav Mondal'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  const Text('Phone Number (ফোন নম্বর)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: 'e.g. 9876543210'),
                    validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid 10-digit number' : null,
                  ),
                  const SizedBox(height: 16),

                  // Optional Email
                  const Text('Email Address (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'e.g. name@example.com'),
                  ),
                  const SizedBox(height: 16),

                  // Driver-specific fields
                  if (_selectedRole == UserRole.driver) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTO Vehicle Verification',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Admin approval is strictly required before receiving automatic dispatch orders.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          const Text('Vehicle Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _vehicleNumberController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. WB-52-TOTO-1234',
                              fillColor: Colors.white,
                            ),
                            validator: (v) => _selectedRole == UserRole.driver && (v == null || v.trim().isEmpty)
                                ? 'Vehicle number is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          const Text('Municipal Badge or ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _licenseOrIdController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. KRM-TOTO-789',
                              fillColor: Colors.white,
                            ),
                            validator: (v) => _selectedRole == UserRole.driver && (v == null || v.trim().isEmpty)
                                ? 'Driver registration ID is required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Register Button
                  CustomButton(
                    text: 'Complete Registration',
                    isLime: true,
                    isLoading: authService.isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String bengali,
    required UserRole role,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandBlack : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.brandBlack : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? AppColors.brandLime : AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              '($bengali)',
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
