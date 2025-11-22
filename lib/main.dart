import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gacha_guard/features/auth/data/firebase_auth_repo.dart';
import 'package:gacha_guard/features/auth/presentation/components/loading.dart';
import 'package:gacha_guard/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:gacha_guard/features/auth/presentation/cubits/auth_states.dart';
import 'package:gacha_guard/features/auth/presentation/pages/auth_page.dart';
import 'package:gacha_guard/features/home/home_page.dart';
import 'package:gacha_guard/features/insights/insights_page.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/scheduled_notification_service.dart';

// Timezone packages for scheduled notifications
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// GLOBAL navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Timezones for scheduled notifications
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

  // Initialize notifications
  await NotificationService().init();
  await NotificationService().requestPermissions();

  // Handle notification that launched the app from terminated state
  final launchDetails = await NotificationService().getLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp ?? false) {
    final payload = launchDetails?.notificationResponse?.payload;
    if (payload != null) {
      NotificationService.handlePayload(payload);
    }
  }


  // Initialize scheduled notifications
  await ScheduledNotificationService().initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final firebaseAuthRepo = FirebaseAuthRepo();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) =>
              AuthCubit(authRepo: firebaseAuthRepo)..checkAuth(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,

        routes: {
          '/insights': (context) => const InsightsPage(),
          '/home': (context) => const HomePage(),
        },

        home: BlocConsumer<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is Unauthenticated) return const AuthPage();
            if (state is Authenticated) return const HomePage();
            return const Loading();
          },
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
        ),
      ),
    );
  }
}
