import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const UserProfile _mockProfile = UserProfile(
    id: 'user-001',
    email: 'user@example.com',
    displayName: 'Username',
    photoUrl: null,
    phoneNumber: null,
    dateOfBirth: null,
    language: 'id',
    currency: 'IDR',
    createdAt: null,
    updatedAt: null,
    points: 0,
    membershipLevel: 'Bronze',
    postCount: 0,
    followerCount: 0,
    followingCount: 0,
  );


  late final TextEditingController _displayNameController;
  late final TextEditingController _cityController;
  DateTime? _selectedBirthDate;
  String _selectedGender = 'Laki-laki';

  @override
  void initState() {
    super.initState();

    _displayNameController = TextEditingController(text: _mockProfile.displayName);
    _cityController = TextEditingController();
    _selectedBirthDate = DateTime(2005, 11, 13);
  }

  @override
  void dispose() {

    _displayNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray0,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.gray5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Info Akun',
          style: TextStyle(
            color: AppColors.gray5,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileAvatar(
              profile: _mockProfile,
              onEdit: () {},
            ),

            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Data Pribadi',
              actionText: 'Ubah',
              onAction: () {},
            ),
            const SizedBox(height: 12),
            _FormCard(
              child: Column(
                children: [
                  _LabeledField(
                    label: 'Username',
                    child: TextField(
                      controller: _displayNameController,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'Tanggal Lahir',
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _selectedBirthDate != null
                                    ? _formatDate(_selectedBirthDate!)
                                    : 'Pilih tanggal',
                                style: TextStyle(
                                  color: _selectedBirthDate != null
                                      ? AppColors.gray5
                                      : AppColors.gray3,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LabeledField(
                          label: 'Kelamin',
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            items: const [
                              DropdownMenuItem(
                                value: 'Laki-laki',
                                child: Text('Laki-laki'),
                              ),
                              DropdownMenuItem(
                                value: 'Perempuan',
                                child: Text('Perempuan'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'Kota Tempat Tinggal',
                    child: TextField(
                      controller: _cityController,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Email',
            ),
            const SizedBox(height: 8),
            _InfoBlock(
              message:
                  'Email digunakan untuk login dan menerima notifikasi.',
              value: _mockProfile.email,
              statusLabel: 'Penerima notifikasi',
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'No. Handphone',
            ),
            const SizedBox(height: 8),
            _InfoBlock(
              message:
                  'No. handphone digunakan untuk login dan menerima notifikasi.',
              value: _mockProfile.phoneNumber ?? '-',
              statusLabel: 'Utama',
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    required this.onEdit,
  });

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Material(
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onEdit,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.displayName ?? 'Traveler',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.gray4,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.gray5,
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.message,
    required this.value,
    required this.statusLabel,
  });

  final String message;
  final String value;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.gray3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

