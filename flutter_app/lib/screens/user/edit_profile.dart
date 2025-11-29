import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_profile.dart';
import '../../providers/user_profile_provider.dart';

// Model untuk avatar option
class AvatarOption {
  final String id;
  final String? assetPath; // Path ke asset (jika dari assets)
  final String? imageUrl; // URL gambar (jika dari internet)
  
  const AvatarOption({
    required this.id,
    this.assetPath,
    this.imageUrl,
  }) : assert(assetPath != null || imageUrl != null, 'Harus ada assetPath atau imageUrl');
  
  // Helper untuk mendapatkan image provider
  ImageProvider get imageProvider {
    if (assetPath != null) {
      return AssetImage(assetPath!);
    } else {
      return NetworkImage(imageUrl!);
    }
  }
  
  // Helper untuk mendapatkan string identifier (untuk disimpan di database)
  String get identifier => assetPath ?? imageUrl!;
}

// List avatar yang tersedia (4 avatar)
class AvatarOptions {
  static const List<AvatarOption> avatars = [
    // Avatar 1: Dari URL (DiceBear PNG format)
    AvatarOption(
      id: 'avatar_1',
      imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Alex',
    ),
    // Avatar 2: Dari URL (DiceBear PNG format)
    AvatarOption(
      id: 'avatar_2',
      imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Jordan',
    ),
    // Avatar 3: Dari URL (DiceBear PNG format)
    AvatarOption(
      id: 'avatar_3',
      imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Taylor',
    ),
    // Avatar 4: Dari URL (DiceBear PNG format)
    AvatarOption(
      id: 'avatar_4',
      imageUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Casey',
    ),
  ];
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _cityController;
  DateTime? _selectedBirthDate;
  String _selectedGender = 'Laki-laki';
  String? _selectedAvatarUrl; // State untuk avatar yang dipilih

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _cityController = TextEditingController();

    // Initialize with current profile data or fetch it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = ref.read(userProfileProvider);
      if (provider.profile == null) {
        provider.loadProfile();
      } else {
        _populateFields(provider.profile!);
      }
    });
  }

  void _populateFields(UserProfile profile) {
    _displayNameController.text = profile.displayName ?? '';
    if (profile.dateOfBirth != null) {
      setState(() {
        _selectedBirthDate = profile.dateOfBirth;
        _selectedAvatarUrl = profile.photoUrl; // Set avatar dari profile
      });
    } else {
      setState(() {
        _selectedAvatarUrl = profile.photoUrl; // Set avatar dari profile
      });
    }
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

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.gray2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Pilih Avatar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray5,
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 kolom untuk 4 avatar (2x2)
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: AvatarOptions.avatars.length,
                itemBuilder: (context, index) {
                  final avatar = AvatarOptions.avatars[index];
                  final avatarIdentifier = avatar.identifier;
                  final isSelected = _selectedAvatarUrl == avatarIdentifier;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatarUrl = avatarIdentifier;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.gray1,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: AppColors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: ClipOval(
                        child: avatar.assetPath != null
                            ? Image(
                                image: avatar.imageProvider as AssetImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.gray1,
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.gray3,
                                    ),
                                  );
                                },
                              )
                            : Image.network(
                                avatar.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.gray1,
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.gray3,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final provider = ref.read(userProfileProvider);
    
    // Construct payload - always include displayName (even if empty)
    final payload = <String, dynamic>{
      'displayName': _displayNameController.text.trim(),
    };
    
    // Only add dateOfBirth if it's selected
    if (_selectedBirthDate != null) {
      payload['dateOfBirth'] = _selectedBirthDate!.toIso8601String();
    }
    
    // Add photoURL if avatar is selected
    if (_selectedAvatarUrl != null) {
      payload['photoURL'] = _selectedAvatarUrl;
    }

    try {
      await provider.updateProfile(payload);
      if (mounted) {
        // Refresh profile to get updated data
        await provider.refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui profil: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserProfileProvider>(userProfileProvider, (previous, next) {
      if (previous?.profile != next.profile && next.profile != null) {
        _populateFields(next.profile!);
      }
    });

    final provider = ref.watch(userProfileProvider);
    final profile = provider.profile;
    final isLoading = provider.isLoading;

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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile != null)
                    _ProfileAvatar(
                      profile: profile,
                      selectedAvatarUrl: _selectedAvatarUrl,
                      onEdit: _showAvatarPicker,
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
                  if (profile != null)
                    _InfoBlock(
                      message:
                          'Email digunakan untuk login dan menerima notifikasi.',
                      value: profile.email,
                      statusLabel: 'Penerima notifikasi',
                    ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'No. Handphone',
                  ),
                  const SizedBox(height: 8),
                  if (profile != null)
                    _InfoBlock(
                      message:
                          'No. handphone digunakan untuk login dan menerima notifikasi.',
                      value: profile.phoneNumber ?? '-',
                      statusLabel: 'Utama',
                    ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveProfile,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan Perubahan'),
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
    this.selectedAvatarUrl,
    required this.onEdit,
  });

  final UserProfile profile;
  final String? selectedAvatarUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    // Prioritize selected avatar, then profile photoUrl, then default icon
    final displayUrl = selectedAvatarUrl ?? profile.photoUrl;
    final isAssetPath = displayUrl != null && displayUrl.startsWith('assets/');
    
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
                child: displayUrl != null
                    ? ClipOval(
                        child: isAssetPath
                            ? Image(
                                image: AssetImage(displayUrl),
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              )
                            : Image.network(
                                displayUrl,
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                      )
                    : const Icon(
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

