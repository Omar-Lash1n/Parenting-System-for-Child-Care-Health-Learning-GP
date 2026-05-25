import 'package:flutter/material.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';

class ClinicStepper extends StatelessWidget {
  final int currentStep;
  const ClinicStepper({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(1, active: currentStep >= 1),
        _buildDashedLine(),
        _buildStepCircle(2, active: currentStep >= 2),
        _buildDashedLine(),
        _buildStepCircle(3, active: currentStep >= 3),
      ],
    );
  }

  Widget _buildStepCircle(int step, {required bool active}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? specialistGreen : Colors.white,
        border: active ? null : Border.all(color: Colors.grey.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            fontFamily: specialistFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDashedLine() {
    return Container(
      width: 40,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: List.generate(
              (constraints.constrainWidth() / 4).floor(),
              (index) => Container(
                width: 2,
                height: 1,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
            ),
          );
        },
      ),
    );
  }
}
