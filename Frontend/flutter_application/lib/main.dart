import 'package:Ajial/add-child/add-child-flow.dart';
import 'package:Ajial/homepage/homepage.dart';
import 'package:Ajial/signup-login-pages/login.dart';
import 'package:flutter/material.dart';
import 'package:Ajial/child-app/child-sign-in.dart';
import 'package:Ajial/splash_screen.dart';
import 'package:Ajial/profile/parent_profile.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:Ajial/vaccinations/vaccination_reminder_service.dart';
import 'package:Ajial/vaccinations/local_notification_service.dart';
import 'package:Ajial/vaccinations/vaccination_alarm_screen.dart';
import 'package:alarm/alarm.dart';

// --- Provider Imports ---
import 'package:provider/provider.dart';
import 'package:Ajial/providers/login_provider.dart';
import 'package:Ajial/providers/signup_provider.dart';
import 'package:Ajial/providers/continue_signup_provider.dart';
import 'package:Ajial/providers/forgot_password_provider.dart';
import 'package:Ajial/providers/verify_email_provider.dart';
import 'package:Ajial/providers/home_provider.dart';
import 'package:Ajial/providers/add_child_flow_provider.dart';
import 'package:Ajial/providers/child_login_provider.dart';
import 'package:Ajial/providers/parent_profile_provider.dart';
import 'package:Ajial/providers/settings_provider.dart';
import 'package:Ajial/providers/family_provider.dart';
import 'package:Ajial/providers/child_profile_provider.dart';
import 'package:Ajial/providers/nav_bar_provider.dart';
import 'package:Ajial/providers/child_data_provider.dart';
import 'package:Ajial/child-app/home/child_home_provider.dart';
import 'package:Ajial/profile/settings_page.dart';
import 'package:Ajial/profile/my_child_profile.dart';
import 'package:Ajial/profile/child_data_profile.dart';
import 'package:Ajial/profile/child_data_profile_form.dart';
import 'package:Ajial/child-app/home/child_home_page.dart';
// --- Vaccination Feature ---
import 'package:Ajial/vaccinations/vaccination_welcome_provider.dart';
import 'package:Ajial/vaccinations/vaccination_welcome_page.dart';
import 'package:Ajial/vaccinations/vaccination_survey_provider.dart';
import 'package:Ajial/vaccinations/vaccination_survey_select_page.dart';
import 'package:Ajial/vaccinations/additional_vaccination_provider.dart';
import 'package:Ajial/vaccinations/additional_vaccination_survey_page.dart';
import 'package:Ajial/vaccinations/vaccination_success_page.dart';
import 'package:Ajial/vaccinations/kids_vaccination_home_page.dart';
import 'package:Ajial/vaccinations/vaccination_dashboard_page.dart';
import 'package:Ajial/family/family_page.dart';
import 'package:Ajial/providers/tasks_provider.dart';
import 'package:Ajial/tasks/tasks_welcome_page.dart';
import 'package:Ajial/tasks/tasks_main_page.dart';
import 'package:Ajial/tasks/tasks_done_page.dart';
import 'package:Ajial/tasks/tasks_categories_page.dart';
import 'package:Ajial/providers/health_unit_provider.dart';
import 'package:Ajial/health-units/health_unit_search_page.dart';

// Background handler is only supported on mobile (Android/iOS), not on web.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

/// Handles alarm ringing - navigates to the vaccination alarm screen.
/// Called by the alarm package when an alarm triggers (works even from background/killed state).
void _handleAlarmRinging(AlarmSettings alarmSettings) {
  debugPrint('🔔 Alarm ringing! ID: ${alarmSettings.id}');
  
  // Parse the notification body to extract child info
  // We use the notification settings to carry the payload info
  final title = alarmSettings.notificationSettings.title;
  final body = alarmSettings.notificationSettings.body;
  
  // Navigate to the alarm screen
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) => VaccinationAlarmScreen(
        childId: '', // Will be populated from alarm context
        milestoneId: 0,
        childName: _extractChildNameFromBody(body),
        healthUnit: _extractHealthUnitFromBody(body),
        vaccinationTitle: title,
        appointmentTime: alarmSettings.dateTime,
        alarmId: alarmSettings.id,
        onVaccinationCompleted: () {
          debugPrint('Vaccination marked as completed');
        },
        onSetAnotherTime: () {
          debugPrint('Set another time requested');
        },
      ),
    ),
  );
}

/// Extracts child name from alarm notification body.
/// Body format examples:
/// - "حان موعد تطعيم أحمد الآن - الوحدة الصحية"
/// - "موعد تطعيم أحمد غداً في 10:00 ص - الوحدة الصحية"
String _extractChildNameFromBody(String body) {
  // Try to extract name between "تطعيم " and the next space/word
  final regex = RegExp(r'تطعيم (.+?)(?:\s+الآن|\s+غداً|\s+بعد|\s+في)');
  final match = regex.firstMatch(body);
  return match?.group(1) ?? 'طفلك';
}

/// Extracts health unit from alarm notification body.
/// Body format: "... - الوحدة الصحية"
String _extractHealthUnitFromBody(String body) {
  final dashIndex = body.lastIndexOf(' - ');
  if (dashIndex != -1 && dashIndex + 3 < body.length) {
    return body.substring(dashIndex + 3);
  }
  return '';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is only configured for Android in this project.
  // Attempting to initialize on web throws an UnsupportedError.
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ----- Mobile Only (Android / iOS) -----
    // Initialize local notification/alarm service for vaccination alarms
    // Uses the alarm package for real alarm behavior (sound, full-screen intent)
    await LocalNotificationService().initialize(
      onRing: _handleAlarmRinging,
    );

    // Request notification permission (Android 13+ / iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // Register the device FCM token with our backend
    unawaited(VaccinationReminderService.registerDeviceToken());

    // Handle notifications when the app is in the background/terminated
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notifications when the app is open (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        print('Notification Title: ${message.notification?.title}');
        print('Notification Body: ${message.notification?.body}');

        // Show an in-app Snackbar for foreground notifications
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${message.notification?.title}\n${message.notification?.body}',
                style: const TextStyle(fontFamily: 'IBM Plex Sans Arabic'),
              ),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => ContinueSignupProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
        ChangeNotifierProvider(create: (_) => VerifyEmailProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => AddChildFlowProvider()),
        ChangeNotifierProvider(create: (_) => ChildLoginProvider()),
        ChangeNotifierProvider(create: (_) => ParentProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChildHomeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => VaccinationWelcomeProvider()),
        ChangeNotifierProvider(create: (_) => VaccinationSurveyProvider()),
        ChangeNotifierProvider(create: (_) => AdditionalVaccinationProvider()),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => ChildProfileProvider()),
        ChangeNotifierProvider(create: (_) => NavBarProvider()),
        ChangeNotifierProvider(create: (_) => ChildDataProvider()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
        ChangeNotifierProvider(create: (_) => HealthUnitProvider()),
      ],
      child: const AjialApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AjialApp extends StatelessWidget {
  const AjialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      // تهيئة دعم اللغة العربية
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('ar', '')],
      locale: const Locale('ar'), // (هذا يضبط الاتجاه RTL للتطبيق كله)

      theme: ThemeData(
        fontFamily: 'IBM Plex Sans Arabic', // (ممتاز، هذا صحيح)
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      initialRoute: '/splash', // (يمكنك تغيير هذه الصفحة الافتراضية حسب الحاجة)
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/child-login': (context) => const ChildLoginScreen(),
        '/child-home': (context) => const ChildHomePage(),
        '/home': (context) => HomeScreen(),
        '/add-child': (context) => const AddChildFlow(),
        '/profile': (context) => const ParentProfilePage(),
        '/settings': (context) => const SettingsPage(),
        '/vaccination-welcome': (context) => const VaccinationWelcomePage(),
        '/vaccination-survey': (context) => const VaccinationSurveySelectPage(),
        '/additional-vaccination-survey': (context) =>
            const AdditionalVaccinationSurveyPage(),
        '/vaccination-success': (context) => const VaccinationSuccessPage(),
        '/kids-vaccination-home': (context) => const KidsVaccinationHomePage(),
        '/vaccination-dashboard': (context) => const VaccinationDashboardPage(),
        '/family': (context) => const FamilyPage(),
        '/tasks-welcome': (context) => const TasksWelcomePage(),
        '/tasks': (context) => const TasksMainPage(),
        '/tasks-done': (context) => const TasksDonePage(),
        '/tasks-categories': (context) => const TasksCategoriesPage(),
        '/child-profile': (context) => const MyChildProfilePage(),
        '/child-data': (context) => const ChildDataProfilePage(),
        '/child-data-form': (context) => const ChildDataProfileFormPage(),
        '/health-unit-search': (context) => const HealthUnitSearchPage(),
      },
    );
  }
}
