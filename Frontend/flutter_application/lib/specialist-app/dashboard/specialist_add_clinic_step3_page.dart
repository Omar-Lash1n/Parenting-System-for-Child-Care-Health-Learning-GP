import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Ajial/specialist-app/application-tracking/widgets/specialist_application_widgets.dart';
import 'package:Ajial/specialist-app/dashboard/widgets/clinic_stepper.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_add_clinic_success_page.dart';
import 'package:Ajial/specialist-app/dashboard/specialist_clinic_data_page.dart';

class SpecialistAddClinicStep3Page extends StatefulWidget {
  const SpecialistAddClinicStep3Page({super.key});

  @override
  State<SpecialistAddClinicStep3Page> createState() => _SpecialistAddClinicStep3PageState();
}

class _SpecialistAddClinicStep3PageState extends State<SpecialistAddClinicStep3Page> {
  // Store the picked image for each requirement
  final Map<String, XFile?> _uploadState = {
    'license': null,
    'syndicate': null,
    'waste': null,
    'exterior': null,
    'interior': null,
  };

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (globalDraftClinic != null) {
      if (globalDraftClinic!.imagePaths.isNotEmpty) {
        if (globalDraftClinic!.imagePaths['license'] != null) {
          _uploadState['license'] = XFile(globalDraftClinic!.imagePaths['license']!);
        }
        if (globalDraftClinic!.imagePaths['syndicate'] != null) {
          _uploadState['syndicate'] = XFile(globalDraftClinic!.imagePaths['syndicate']!);
        }
        if (globalDraftClinic!.imagePaths['waste'] != null) {
          _uploadState['waste'] = XFile(globalDraftClinic!.imagePaths['waste']!);
        }
        if (globalDraftClinic!.imagePaths['exterior'] != null) {
          _uploadState['exterior'] = XFile(globalDraftClinic!.imagePaths['exterior']!);
        }
        if (globalDraftClinic!.imagePaths['interior'] != null) {
          _uploadState['interior'] = XFile(globalDraftClinic!.imagePaths['interior']!);
        }
      }
    }
  }

  void _onNext() {
    if (globalDraftClinic != null) {
      globalDraftClinic!.imagePaths = {
        'license': _uploadState['license']?.path,
        'syndicate': _uploadState['syndicate']?.path,
        'waste': _uploadState['waste']?.path,
        'exterior': _uploadState['exterior']?.path,
        'interior': _uploadState['interior']?.path,
      };
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SpecialistAddClinicSuccessPage(),
      ),
    );
  }

  void _onPrevious() {
    Navigator.of(context).pop();
  }

  Future<void> _pickImage(String key) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _uploadState[key] = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        // Pop back to main
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'اضافة عيادة',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stepper UI
                      const ClinicStepper(currentStep: 3),
                      const SizedBox(height: 32),
                      
                      // Titles
                      const Center(
                        child: Text(
                          'بيانات ترخيص العيادة',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'نحتاج لمعلومات صحيحة لضمان أمان المنصة',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 14,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Upload Fields
                      _buildUploadField('صورة ترخيص العيادة*', 'license'),
                      const SizedBox(height: 16),
                      _buildUploadField('صورة شهادة تسجيل العيادة بالنقابة*', 'syndicate'),
                      const SizedBox(height: 16),
                      _buildUploadField('صورة إيصال سداد رسوم النفايات الخطرة*', 'waste'),
                      const SizedBox(height: 16),
                      _buildUploadField('صورة العيادة من الخارج*', 'exterior'),
                      const SizedBox(height: 16),
                      _buildUploadField('صورة العيادة من الداخل*', 'interior'),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Bottom Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: specialistGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'التالي',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _onPrevious,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.black.withValues(alpha: 0.8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'السابق',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadField(String label, String key) {
    bool isUploaded = _uploadState[key] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, right: 4),
          child: RichText(
            text: TextSpan(
              text: label.replaceAll('*', ''),
              style: const TextStyle(
                fontFamily: specialistFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              children: [
                if (label.contains('*'))
                  const TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Text(
                isUploaded ? 'تم تحميل الصورة' : 'اضغط تحميل الصورة',
                style: TextStyle(
                  fontFamily: specialistFont,
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
              const Spacer(),
              if (!isUploaded)
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => _pickImage(key),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text(
                      'تحميل صورة',
                      style: TextStyle(
                        fontFamily: specialistFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => _pickImage(key), // Open picker again to edit
                        style: ElevatedButton.styleFrom(
                          backgroundColor: specialistGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          'تعديل',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () {
                          final file = _uploadState[key];
                          if (file != null) {
                            showDialog(
                              context: context,
                              builder: (ctx) => Dialog(
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AppBar(
                                      title: const Text('عرض الصورة', style: TextStyle(fontFamily: specialistFont, fontSize: 16)),
                                      automaticallyImplyLeading: false,
                                      elevation: 0,
                                      backgroundColor: Colors.white,
                                      actions: [
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.black),
                                          onPressed: () => Navigator.pop(ctx),
                                        ),
                                      ],
                                    ),
                                    Flexible(
                                      child: kIsWeb 
                                          ? Image.network(
                                              file.path,
                                              fit: BoxFit.contain,
                                            )
                                          : Image.file(
                                              File(file.path),
                                              fit: BoxFit.contain,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.black.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text(
                          'فتح',
                          style: TextStyle(
                            fontFamily: specialistFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
