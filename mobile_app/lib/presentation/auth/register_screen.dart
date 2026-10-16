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
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Role Selector Tabs
                  const Text(
                    'Select Account Type:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = UserRole.passenger),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == UserRole.passenger
                                  ? AppColors.primaryTint
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedRole == UserRole.passenger
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: _selectedRole == UserRole.passenger ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person,
                                  color: _selectedRole == UserRole.passenger
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Passenger\n(যাত্রী)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRole == UserRole.passenger
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = UserRole.driver),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == UserRole.driver
                                  ? AppColors.primaryTint
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedRole == UserRole.driver
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: _selectedRole == UserRole.driver ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.electric_rickshaw,
                                  color: _selectedRole == UserRole.driver
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'TOTO Driver\n(চালক সাথী)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRole == UserRole.driver
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  const Text('Full Name *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Subir Karmakar',
                      prefixIcon: Icon(Icons.badge, color: AppColors.primary),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 14),

                  // Mobile Number
                  const Text('Phone Number *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '10-digit mobile number',
                      prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                    ),
                    validator: (v) => (v == null || v.trim().length < 10) ? 'Enter valid 10-digit number' : null,
                  ),
                  const SizedBox(height: 14),

                  // Email (Optional)
                  const Text('Email Address (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Optional email for receipts',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Driver-Specific Fields
                  if (_selectedRole == UserRole.driver) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFFE65100), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Driver Security: Your account requires administrator approval in Karimpur before taking passenger bookings.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('TOTO Vehicle Number / Registration *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _vehicleNumberController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. WB-52-TOTO-1042 or Municipal Reg No',
                        prefixIcon: Icon(Icons.directions_car, color: AppColors.primary),
                      ),
                      validator: (v) {
                        if (_selectedRole == UserRole.driver && (v == null || v.trim().isEmpty)) {
                          return 'Vehicle number is required for drivers';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    const Text('Aadhaar / Voter ID Number *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _licenseOrIdController,
                      decoration: const InputDecoration(
                        hintText: 'Identity verification document number',
                        prefixIcon: Icon(Icons.credit_card, color: AppColors.primary),
                      ),
                      validator: (v) {
                        if (_selectedRole == UserRole.driver && (v == null || v.trim().isEmpty)) {
                          return 'ID proof is required for driver verification';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  const SizedBox(height: 12),
                  CustomButton(
                    text: _selectedRole == UserRole.driver ? 'Register as TOTO Driver' : 'Register as Passenger',
                    isLoading: authService.isLoading,
                    onPressed: _handleRegister,
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
