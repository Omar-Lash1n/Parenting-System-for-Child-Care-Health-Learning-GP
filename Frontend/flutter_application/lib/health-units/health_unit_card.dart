import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kPrimary = Color(0xFFBF092F);
const Color _kGreen = Color(0xFF01A449);
const String _kFont = 'IBM Plex Sans Arabic';

class HealthUnitCard extends StatelessWidget {
  final Map<String, dynamic> unit;
  final VoidCallback? onInfoTap;

  const HealthUnitCard({
    super.key,
    required this.unit,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final String nameAr = unit['nameAr'] ?? '';
    final String addressAr = unit['addressAr'] ?? '';
    final String typeAr = unit['typeAr'] ?? '';
    final double? distanceKm = unit['distanceKm'] != null
        ? (unit['distanceKm'] as num).toDouble()
        : null;
    final bool isActive = unit['isActive'] == true;
    final double lat = (unit['latitude'] as num?)?.toDouble() ?? 0;
    final double lng = (unit['longitude'] as num?)?.toDouble() ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? _kGreen.withOpacity(0.1)
                      : _kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'مفتوح الان' : 'مغلق الان',
                  style: TextStyle(
                    fontFamily: _kFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? _kGreen : _kPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Name
              Text(
                nameAr,
                style: const TextStyle(
                  fontFamily: _kFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              if (typeAr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  typeAr,
                  style: const TextStyle(
                    fontFamily: _kFont,
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Address
              if (addressAr.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: _kPrimary, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        addressAr,
                        style: const TextStyle(
                          fontFamily: _kFont,
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),

              // Distance
              if (distanceKm != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _kPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'على بعد $distanceKm كم',
                      style: const TextStyle(
                        fontFamily: _kFont,
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // Bottom row: info button + directions button
              Row(
                children: [
                  // Info button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _kPrimary),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.info_outline,
                          color: _kPrimary, size: 18),
                      onPressed: onInfoTap,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Directions button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openDirections(lat, lng),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.near_me,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'الاتجاهات',
                        style: TextStyle(
                          fontFamily: _kFont,
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDirections(double lat, double lng) {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
