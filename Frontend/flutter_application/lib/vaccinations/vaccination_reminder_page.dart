import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'vaccination_reminder_service.dart';
import 'local_notification_service.dart';

const Color _kPrimaryColor = Color(0xFFBF092F);
const Color _kPrimaryLight = Color(0x0DBF092F);
const Color _kOrange = Color(0xFFFE8401);
const Color _kTextPrimary = Color(0xFF1E293B);
const Color _kTextSecondary = Color(0xFF64748B);
const Color _kCardBorder = Color(0x26000000);
const Color _kDividerColor = Color(0x1A000000);
const Color _kDisabled = Color(0xFFD9D9D9);
const String _kFontFamily = 'IBM Plex Sans Arabic';

class VaccinationReminderPage extends StatefulWidget {
  final String vaccinationTitle;
  final String vaccineSubtitle;
  final String statusLabel;
  final DateTime reminderDate;
  final DateTime appointmentDate;
  final Color? statusColor;
  final Color? statusBackgroundColor;
  final Color? accentColor;
  final String childId;
  final int milestoneId;
  final String childName;

  const VaccinationReminderPage({
    super.key,
    required this.vaccinationTitle,
    required this.vaccineSubtitle,
    required this.statusLabel,
    required this.reminderDate,
    required this.appointmentDate,
    this.statusColor,
    this.statusBackgroundColor,
    this.accentColor,
    required this.childId,
    required this.milestoneId,
    this.childName = 'طفلك',
  });

  @override
  State<VaccinationReminderPage> createState() =>
      _VaccinationReminderPageState();
}

class _VaccinationReminderPageState extends State<VaccinationReminderPage> {
  late DateTime selectedDate;
  late String hospitalName;
  TimeOfDay? appointmentTime;
  bool reminderDayBefore = true;
  bool reminder3HoursBefore = true;
  bool customReminderEnabled = false;
  TimeOfDay? customReminderTime;
  bool alarmEnabled = true;
  bool notificationEnabled = true;

  bool _isLoading = true;
  bool _isSaving = false;

  late final TextEditingController _hospitalController;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final apptOnly = DateTime(widget.appointmentDate.year,
        widget.appointmentDate.month, widget.appointmentDate.day);
    selectedDate = apptOnly.isBefore(todayOnly) ? todayOnly : apptOnly;
    hospitalName = 'الوحدة الصحية بسوهاج';
    appointmentTime = const TimeOfDay(hour: 10, minute: 0);
    customReminderTime = const TimeOfDay(hour: 10, minute: 0);
    _hospitalController = TextEditingController(text: hospitalName);
    _hospitalController.addListener(_handleHospitalChanged);
    _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    setState(() => _isLoading = true);
    final data = await VaccinationReminderService.getReminderSettings(
        widget.childId, widget.milestoneId);

    if (data != null && mounted) {
      setState(() {
        hospitalName = data['healthUnit'] ?? hospitalName;
        _hospitalController.text = hospitalName;

        if (data['appointmentDate'] != null) {
          selectedDate =
              DateTime.tryParse(data['appointmentDate']) ?? selectedDate;
        }

        if (data['appointmentTime'] != null) {
          final parts = data['appointmentTime'].toString().split(':');
          if (parts.length >= 2) {
            appointmentTime = TimeOfDay(
                hour: int.tryParse(parts[0]) ?? 10,
                minute: int.tryParse(parts[1]) ?? 0);
          }
        }

        reminderDayBefore = data['notifyOneDayBefore'] ?? reminderDayBefore;
        reminder3HoursBefore =
            data['notifyThreeHoursBefore'] ?? reminder3HoursBefore;
        customReminderEnabled =
            data['customReminderEnabled'] ?? customReminderEnabled;
        alarmEnabled = data['isAlarmEnabled'] ?? alarmEnabled;
        notificationEnabled = data['isPushEnabled'] ?? notificationEnabled;

        if (data['customReminderDateTime'] != null) {
          final parsed = DateTime.tryParse(data['customReminderDateTime']);
          if (parsed != null) {
            customReminderTime =
                TimeOfDay(hour: parsed.hour, minute: parsed.minute);
          }
        }
      });
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveReminderSettings() async {
    setState(() => _isSaving = true);

    String formatTime(TimeOfDay? time) {
      if (time == null) return "10:00:00";
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }

    String formatDate(DateTime date) {
      return DateFormat('yyyy-MM-dd').format(date);
    }

    String? customDateTimeStr;
    if (customReminderEnabled && customReminderTime != null) {
      final customDt = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          customReminderTime!.hour,
          customReminderTime!.minute);
      customDateTimeStr = customDt.toUtc().toIso8601String();
    }

    final (success, message) = await VaccinationReminderService.upsertReminder(
      childId: widget.childId,
      milestoneId: widget.milestoneId,
      hospitalName: hospitalName,
      appointmentDate: formatDate(selectedDate),
      appointmentTime: formatTime(appointmentTime),
      notifyOneDayBefore: reminderDayBefore,
      notifyThreeHoursBefore: reminder3HoursBefore,
      customReminderEnabled: customReminderEnabled,
      customReminderDateTime: customDateTimeStr,
      isAlarmEnabled: alarmEnabled,
      isPushEnabled: notificationEnabled,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: _kFontFamily),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      // Handle local alarm scheduling based on toggle state
      if (success) {
        await _handleLocalAlarmScheduling();
        Navigator.pop(context);
      }
    }
  }

  /// Schedules or cancels local alarms based on the alarm toggle state.
  Future<void> _handleLocalAlarmScheduling() async {
    final notificationService = LocalNotificationService();

    // Check permissions first
    final permissions = await notificationService.checkPermissions();
    debugPrint('📋 Permission check before scheduling:');
    debugPrint(
        '   Notifications enabled: ${permissions['notificationsEnabled']}');
    debugPrint('   Exact alarms allowed: ${permissions['exactAlarmsAllowed']}');

    if (permissions['notificationsEnabled'] == false) {
      debugPrint('⚠️ Cannot schedule alarms - notifications not enabled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'يرجى تفعيل الإشعارات من إعدادات الجهاز لتلقي تنبيهات التطعيم',
              style: TextStyle(fontFamily: _kFontFamily),
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    if (alarmEnabled) {
      // Build the appointment DateTime
      final apptDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        appointmentTime?.hour ?? 10,
        appointmentTime?.minute ?? 0,
      );

      debugPrint('📅 Scheduling alarms for:');
      debugPrint('   Child: ${widget.childName} (${widget.childId})');
      debugPrint('   Milestone: ${widget.milestoneId}');
      debugPrint('   Appointment: $apptDateTime');
      debugPrint('   Hospital: $hospitalName');
      debugPrint('   Day before: $reminderDayBefore');
      debugPrint('   3 hours before: $reminder3HoursBefore');
      debugPrint('   Custom reminder: $customReminderEnabled');

      // Build custom reminder DateTime if enabled
      DateTime? customDateTime;
      if (customReminderEnabled && customReminderTime != null) {
        customDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          customReminderTime!.hour,
          customReminderTime!.minute,
        );
        debugPrint('   Custom time: $customDateTime');
      }

      // Schedule the local alarms
      await notificationService.scheduleVaccinationAlarms(
        childId: widget.childId,
        milestoneId: widget.milestoneId,
        childName: widget.childName,
        healthUnit: hospitalName,
        appointmentDateTime: apptDateTime,
        notifyOneDayBefore: reminderDayBefore,
        notifyThreeHoursBefore: reminder3HoursBefore,
        customReminderEnabled: customReminderEnabled,
        customReminderDateTime: customDateTime,
      );

      // Verify scheduled alarms
      final pending = await notificationService.getScheduledAlarms();
      debugPrint('✅ Local alarms scheduled. Total pending: ${pending.length}');
    } else {
      // Cancel any existing local alarms for this reminder
      await notificationService.cancelVaccinationAlarms(
        childId: widget.childId,
        milestoneId: widget.milestoneId,
      );

      debugPrint('🗑️ Local alarms cancelled for vaccination reminder');
    }
  }

  @override
  void dispose() {
    _hospitalController
      ..removeListener(_handleHospitalChanged)
      ..dispose();
    super.dispose();
  }

  void _handleHospitalChanged() {
    setState(() {
      hospitalName = _hospitalController.text;
    });
  }

  Future<void> _pickAppointmentTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: appointmentTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        appointmentTime = picked;
      });
    }
  }

  Future<void> _pickCustomReminderTime() async {
    if (!customReminderEnabled) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: customReminderTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        customReminderTime = picked;
      });
    }
  }

  Future<void> _pickDateFromCalendar() async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isBefore(todayOnly) ? todayOnly : selectedDate,
      firstDate: todayOnly,
      lastDate: todayOnly.add(const Duration(days: 365 * 5)),
      locale: const Locale('ar'),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: _kPrimaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: _kTextPrimary,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: _kPrimaryColor),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _monthYearLabel(DateTime date) {
    return DateFormat('MMMM yyyy', 'ar').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: _kPrimaryColor))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          VaccinationSummaryCard(
                            statusLabel: widget.statusLabel,
                            title: widget.vaccinationTitle,
                            subtitle: widget.vaccineSubtitle,
                            reminderDate: widget.reminderDate,
                            appointmentDate: widget.appointmentDate,
                            statusColor: widget.statusColor ?? _kOrange,
                            statusBackgroundColor:
                                widget.statusBackgroundColor ??
                                    _kOrange.withValues(alpha: 0.1),
                            accentColor: widget.accentColor ?? _kOrange,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: _pickDateFromCalendar,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  foregroundColor: _kPrimaryColor,
                                ),
                                child: const Text(
                                  'عرض التقويم',
                                  style: TextStyle(
                                    fontFamily: _kFontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _monthYearLabel(selectedDate),
                                    style: const TextStyle(
                                      fontFamily: _kFontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _kTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          InfiniteCalendarStrip(
                            selectedDate: selectedDate,
                            onDateSelected: (date) {
                              setState(() {
                                selectedDate = date;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          AppointmentDetailsCard(
                            hospitalController: _hospitalController,
                            appointmentTime: appointmentTime,
                            onTimeTap: _pickAppointmentTime,
                          ),
                          const SizedBox(height: 24),
                          ReminderSettingsCard(
                            reminderDayBefore: reminderDayBefore,
                            reminder3HoursBefore: reminder3HoursBefore,
                            customReminderEnabled: customReminderEnabled,
                            customReminderTime: customReminderTime,
                            onReminderDayBeforeChanged: (value) {
                              setState(() {
                                reminderDayBefore = value;
                              });
                            },
                            onReminder3HoursChanged: (value) {
                              setState(() {
                                reminder3HoursBefore = value;
                              });
                            },
                            onCustomReminderChanged: (value) {
                              setState(() {
                                customReminderEnabled = value;
                              });
                            },
                            onCustomTimeTap: _pickCustomReminderTime,
                          ),
                          const SizedBox(height: 24),
                          NotificationTypeCard(
                            alarmEnabled: alarmEnabled,
                            notificationEnabled: notificationEnabled,
                            onAlarmChanged: (value) {
                              setState(() {
                                alarmEnabled = value;
                              });
                            },
                            onNotificationChanged: (value) {
                              setState(() {
                                notificationEnabled = value;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label:
                                _isSaving ? 'جاري الحفظ...' : 'حفظ الإعدادات',
                            onPressed:
                                _isSaving ? () {} : _saveReminderSettings,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text(
                                'إلغاء',
                                style: TextStyle(
                                  fontFamily: _kFontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              Positioned(
                top: 0,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(19),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VaccinationSummaryCard extends StatelessWidget {
  final String statusLabel;
  final String title;
  final String subtitle;
  final DateTime reminderDate;
  final DateTime appointmentDate;
  final Color statusColor;
  final Color statusBackgroundColor;
  final Color accentColor;

  const VaccinationSummaryCard({
    super.key,
    required this.statusLabel,
    required this.title,
    required this.subtitle,
    required this.reminderDate,
    required this.appointmentDate,
    required this.statusColor,
    required this.statusBackgroundColor,
    required this.accentColor,
  });

  String _formatDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'ar').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 5,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(
            right: BorderSide(color: accentColor, width: 4),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: _kFontFamily,
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBackgroundColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _SummaryInfoItem(
                  icon: Icons.notifications_active_outlined,
                  label: 'التذكير',
                  value: _formatDate(reminderDate),
                  accentColor: accentColor,
                ),
                const SizedBox(width: 22),
                _SummaryInfoItem(
                  icon: Icons.vaccines_outlined,
                  label: 'الموعد',
                  value: _formatDate(appointmentDate),
                  accentColor: accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _SummaryInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 12,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(icon, size: 16, color: accentColor),
        ),
      ],
    );
  }
}

class CalendarStrip extends StatelessWidget {
  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarStrip({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  bool _isSelected(DateTime date) {
    return date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
  }

  String _weekdayLabel(DateTime date) {
    return DateFormat('EEEE', 'ar').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSelected(date);

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 56,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected ? _kPrimaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _kPrimaryColor : const Color(0xFFF1F5F9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? _kPrimaryColor.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: isSelected ? 15 : 3,
                    offset:
                        isSelected ? const Offset(0, 10) : const Offset(0, 1),
                    spreadRadius: isSelected ? -3 : 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayLabel(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : _kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class InfiniteCalendarStrip extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const InfiniteCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<InfiniteCalendarStrip> createState() => _InfiniteCalendarStripState();
}

class _InfiniteCalendarStripState extends State<InfiniteCalendarStrip> {
  static const int _totalDays = 365 * 5; // 5 years ahead
  final ScrollController _scrollController = ScrollController();
  final double _itemWidth = 56;
  final double _itemSpacing = 12;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(InfiniteCalendarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    final diff = widget.selectedDate.difference(_today).inDays;
    if (diff < 0 || diff >= _totalDays) return;
    final offset = diff * (_itemWidth + _itemSpacing);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isSelected(DateTime date) {
    return date.year == widget.selectedDate.year &&
        date.month == widget.selectedDate.month &&
        date.day == widget.selectedDate.day;
  }

  String _weekdayLabel(DateTime date) {
    return DateFormat('EEEE', 'ar').format(date);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _totalDays,
        separatorBuilder: (_, __) => SizedBox(width: _itemSpacing),
        itemBuilder: (context, index) {
          final date = _today.add(Duration(days: index));
          final isSelected = _isSelected(date);

          return GestureDetector(
            onTap: () => widget.onDateSelected(date),
            child: Container(
              width: _itemWidth,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected ? _kPrimaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _kPrimaryColor : const Color(0xFFF1F5F9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? _kPrimaryColor.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: isSelected ? 15 : 3,
                    offset:
                        isSelected ? const Offset(0, 10) : const Offset(0, 1),
                    spreadRadius: isSelected ? -3 : 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayLabel(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : _kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppointmentDetailsCard extends StatelessWidget {
  final TextEditingController hospitalController;
  final TimeOfDay? appointmentTime;
  final VoidCallback onTimeTap;

  const AppointmentDetailsCard({
    super.key,
    required this.hospitalController,
    required this.appointmentTime,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'تفاصيل الموعد',
      icon: Icons.calendar_month_outlined,
      child: Column(
        children: [
          const _SectionDivider(),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'اسم الوحدة الصحية / المستشفى',
              style: TextStyle(
                fontFamily: _kFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: hospitalController,
            textAlign: TextAlign.right,
            decoration: _fieldDecoration(),
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const _SectionDivider(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: RichText(
              textDirection: TextDirection.rtl,
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(text: 'الوقت'),
                  TextSpan(
                      text: '*', style: TextStyle(color: Color(0xFFEF4444))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _TimeSelectionField(
            label: _formatTime(appointmentTime),
            enabled: true,
            onTap: onTimeTap,
          ),
        ],
      ),
    );
  }
}

class ReminderSettingsCard extends StatelessWidget {
  final bool reminderDayBefore;
  final bool reminder3HoursBefore;
  final bool customReminderEnabled;
  final TimeOfDay? customReminderTime;
  final ValueChanged<bool> onReminderDayBeforeChanged;
  final ValueChanged<bool> onReminder3HoursChanged;
  final ValueChanged<bool> onCustomReminderChanged;
  final VoidCallback onCustomTimeTap;

  const ReminderSettingsCard({
    super.key,
    required this.reminderDayBefore,
    required this.reminder3HoursBefore,
    required this.customReminderEnabled,
    required this.customReminderTime,
    required this.onReminderDayBeforeChanged,
    required this.onReminder3HoursChanged,
    required this.onCustomReminderChanged,
    required this.onCustomTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'إعدادات التنبيه',
      icon: Icons.settings_outlined,
      child: Column(
        children: [
          const _SectionDivider(),
          const SizedBox(height: 16),
          ToggleRow(
            label: 'قبل الموعد بيوم',
            value: reminderDayBefore,
            onChanged: onReminderDayBeforeChanged,
          ),
          const SizedBox(height: 16),
          const _SectionDivider(),
          const SizedBox(height: 16),
          ToggleRow(
            label: 'قبل الموعد ب 3 ساعات',
            value: reminder3HoursBefore,
            onChanged: onReminder3HoursChanged,
          ),
          const SizedBox(height: 16),
          const _SectionDivider(),
          const SizedBox(height: 16),
          ToggleRow(
            label: 'ضبط موعد اخر',
            value: customReminderEnabled,
            onChanged: onCustomReminderChanged,
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: customReminderEnabled ? 1 : 0.5,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'الوقت',
                      style: TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withValues(
                          alpha: customReminderEnabled ? 1 : 0.45,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TimeSelectionField(
                    label: _formatTime(customReminderTime),
                    enabled: customReminderEnabled,
                    onTap: customReminderEnabled ? onCustomTimeTap : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationTypeCard extends StatelessWidget {
  final bool alarmEnabled;
  final bool notificationEnabled;
  final ValueChanged<bool> onAlarmChanged;
  final ValueChanged<bool> onNotificationChanged;

  const NotificationTypeCard({
    super.key,
    required this.alarmEnabled,
    required this.notificationEnabled,
    required this.onAlarmChanged,
    required this.onNotificationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'نوع التنبيه',
      icon: Icons.notifications_none_rounded,
      child: Column(
        children: [
          const _SectionDivider(),
          const SizedBox(height: 16),
          ToggleRow(
            label: 'منبه',
            value: alarmEnabled,
            onChanged: onAlarmChanged,
          ),
          const SizedBox(height: 16),
          const _SectionDivider(),
          const SizedBox(height: 16),
          ToggleRow(
            label: 'إشعارات',
            value: notificationEnabled,
            onChanged: onNotificationChanged,
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryColor,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: _kFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Transform.scale(
          scale: 0.86,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _kPrimaryColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _kDisabled,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kPrimaryLight,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(icon, color: _kPrimaryColor, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: _kFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _TimeSelectionField extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _TimeSelectionField({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(50),
      child: InputDecorator(
        decoration: _fieldDecoration(
          enabled: enabled,
          prefixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          label,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: _kFontFamily,
            fontSize: 14,
            color:
                enabled ? Colors.black : Colors.black.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: _kDividerColor,
    );
  }
}

InputDecoration _fieldDecoration({
  bool enabled = true,
  Widget? prefixIcon,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(50),
    borderSide: BorderSide(
      color: Colors.black.withValues(alpha: 0.25),
    ),
  );

  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    prefixIcon: prefixIcon,
    prefixIconColor: Colors.black.withValues(alpha: 0.5),
    enabled: enabled,
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: _kPrimaryColor),
    ),
    disabledBorder: border,
  );
}

String _formatTime(TimeOfDay? time) {
  if (time == null) return '--:--';
  final now = DateTime.now();
  final dateTime =
      DateTime(now.year, now.month, now.day, time.hour, time.minute);
  return DateFormat('h:mm a', 'ar').format(dateTime);
}
