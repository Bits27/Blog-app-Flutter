// Profile edit screen for username, password update, and avatar management.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/ink_card.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../auth/data/supabase_auth_repository.dart';
import '../../data/supabase_profile_repository.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _profileRepository = SupabaseProfileRepository();
  final _authRepository = SupabaseAuthRepository();
  final _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = await _profileRepository.fetchMyProfile();
      final currentUser = supabase.auth.currentUser;

      _usernameController.text =
          profile?.username ??
          (currentUser?.userMetadata?['username'] as String? ?? '');
      _avatarUrl = profile?.avatarUrl;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      final username = _usernameController.text.trim();
      final existing = await supabase
          .from('profiles')
          .select('id')
          .eq('username', username)
          .neq('id', userId)
          .maybeSingle();

      // Prevent duplicate usernames before upserting profile data.
      if (existing != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username is already taken.')),
        );
        return;
      }

      await _profileRepository.upsertProfile(
        username: username,
        avatarUrl: _avatarUrl,
      );
      await _authRepository.updateUsernameMetadata(username);

      final password = _passwordController.text.trim();
      if (password.isNotEmpty) {
        await _authRepository.updatePassword(password);
      }

      if (!mounted) return;
      showAppToast('Profile updated.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _changeProfilePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await picked.readAsBytes();
      final publicUrl = await _profileRepository.uploadAvatar(
        bytes: bytes,
        fileName: picked.name,
      );

      if (!mounted) return;
      setState(() => _avatarUrl = publicUrl);
      showAppToast('Profile photo changed. Save to apply.');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Photo upload failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _removePhoto() {
    setState(() => _avatarUrl = null);
    showAppToast('Photo removed. Save to apply.');
  }

  @override
  Widget build(BuildContext context) {
    final avatarRadius = Responsive.value(
      context,
      compact: Responsive.isLandscape(context) ? 34 : 42,
      medium: 48,
      expanded: 54,
    );

    if (_isLoading) {
      return const AppScaffold(
        title: 'Edit Profile',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: 'Edit Profile',
      maxContentWidth: 760,
      child: Form(
        key: _formKey,
        child: InkCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Edit Profile'),
                const SizedBox(height: 12),
                Center(
                  child: CircleAvatar(
                    radius: avatarRadius,
                    backgroundImage: _avatarUrl != null
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null
                        ? Icon(Icons.person, size: avatarRadius)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _isUploading ? null : _changeProfilePhoto,
                  child: Text(
                    _isUploading ? 'Uploading...' : 'Change Profile Photo',
                  ),
                ),
                if (_avatarUrl != null && _avatarUrl!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _removePhoto,
                    child: const Text('Remove Photo'),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password (Optional)',
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isNotEmpty && v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
