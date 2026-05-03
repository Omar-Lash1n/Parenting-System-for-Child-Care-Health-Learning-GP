import 'package:flutter/material.dart';
import 'package:Ajial/homepage/models/current_vaccination_model.dart';

const Color _kPrimary = Color(0xFFBF092F);
const String _kFont = 'IBM Plex Sans Arabic';

class VaccinationCard extends StatelessWidget {
  final CurrentVaccinationModel vaccination;
  final VoidCallback? onSetReminder;
  final ValueChanged<bool>? onToggleCompleted;

  const VaccinationCard({
    super.key,
    required this.vaccination,
    this.onSetReminder,
    this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(right: BorderSide(color: _kPrimary, width: 4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 2.5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              vaccination.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              vaccination.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: _kFont,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xBF000000),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF9FAFB)),
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _ReminderButton(onTap: onSetReminder),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Text(
                          'تم؟',
                          style: TextStyle(
                            fontFamily: _kFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Switch(
                          value: vaccination.isCompleted,
                          onChanged: onToggleCompleted,
                          activeColor: Colors.white,
                          activeTrackColor: _kPrimary,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFD9D9D9),
                        ),
                      ],
                    ),
                  ],
                ),
                _SmallAvatar(
                  imageUrl: vaccination.childPhotoUrl,
                  name: vaccination.childName,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ReminderButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 102,
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alarm_rounded, size: 16),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                'وضع تذكير',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _kFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;

  const _SmallAvatar({
    required this.imageUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name != null && name!.isNotEmpty ? name!.substring(0, 1) : 'ط';
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Color(0x26FE8401),
        shape: BoxShape.circle,
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
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _kPrimary,
        ),
      ),
    );
  }
}
