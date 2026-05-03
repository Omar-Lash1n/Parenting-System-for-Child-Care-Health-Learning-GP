import 'package:flutter/material.dart';
import 'package:Ajial/providers/family_provider.dart';
import 'package:Ajial/providers/parent_profile_provider.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class HomeHeader extends StatelessWidget {
  final ParentProfileProvider profileProvider;
  final FamilyProvider familyProvider;

  const HomeHeader({
    super.key,
    required this.profileProvider,
    required this.familyProvider,
  });

  @override
  Widget build(BuildContext context) {
    final parentName =
        profileProvider.fullName.trim().isEmpty ? 'حازم محمد' : profileProvider.fullName.trim();
    final childrenNames = familyProvider.children
        .take(2)
        .map((child) => child.fullName.split(' ').first)
        .where((name) => name.isNotEmpty)
        .join(' و ');
    final subtitle = childrenNames.isEmpty ? 'أب' : 'أب $childrenNames';

    return SizedBox(
      height: 75,
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            textDirection: TextDirection.ltr,
            children: [
              _HeaderIconButton(
                icon: Icons.settings_outlined,
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('قريبًا')),
                  );
                },
              ),
            ],
          ),
          Row(
            textDirection: TextDirection.ltr,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً، $parentName',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _kFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0x80000000),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              _ParentAvatar(
                imageUrl: profileProvider.profileImageUrl,
                name: parentName,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0x0DBF092F),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: _kPrimary),
      ),
    );
  }
}

class _ParentAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;

  const _ParentAvatar({
    required this.imageUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.substring(0, 1) : 'أ';
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarInitial(initial: initial),
            )
          : _AvatarInitial(initial: initial),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  final String initial;

  const _AvatarInitial({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: _kFont,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      ),
    );
  }
}
