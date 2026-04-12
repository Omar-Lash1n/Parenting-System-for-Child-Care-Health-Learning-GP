import 'package:flutter/material.dart';
import 'package:Ajial/health-units/health_unit_card.dart';
import 'package:Ajial/health-units/health_unit_no_results.dart';

const String _kFont = 'IBM Plex Sans Arabic';

class HealthUnitResultsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> units;
  final String title;
  final String searchKeyword;
  final VoidCallback onClose;
  final VoidCallback onSearchAgain;
  final VoidCallback onShowNearest;
  final DraggableScrollableController? controller;

  const HealthUnitResultsSheet({
    super.key,
    required this.units,
    required this.title,
    required this.searchKeyword,
    required this.onClose,
    required this.onSearchAgain,
    required this.onShowNearest,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.35,
      minChildSize: 0.1,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.1, 0.35, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: _kFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onClose,
                        child: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: units.isEmpty
                    ? SingleChildScrollView(
                        controller: scrollController,
                        child: HealthUnitNoResults(
                          keyword: searchKeyword,
                          onSearchAgain: onSearchAgain,
                          onShowNearest: onShowNearest,
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        itemCount: units.length,
                        itemBuilder: (context, index) {
                          return HealthUnitCard(unit: units[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
