import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gacha_guard/features/auth/data/firebase_auth_repo.dart';
import 'package:gacha_guard/features/auth/presentation/components/loading.dart';
import 'package:gacha_guard/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:gacha_guard/features/auth/presentation/cubits/auth_states.dart';
import 'package:gacha_guard/features/auth/presentation/pages/auth_page.dart';
import 'package:gacha_guard/features/home/home_page.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final firebaseAuthRepo = FirebaseAuthRepo();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
    providers: [
      //auth cubit
      BlocProvider<AuthCubit>(
        create: (context) => AuthCubit(authRepo: firebaseAuthRepo)..checkAuth(),
      ),
    ], 

    //app
    child: MaterialApp(
      debugShowCheckedModeBanner: false,

      //Bloc consumer - auth
      home: BlocConsumer<AuthCubit, AuthState>(
        builder: (context, state) {
          print(state);

          //unauthenticated -> auth page (login/register)
          if (state is Unauthenticated) {
            return const AuthPage();
          }

          //authenticated -> homepage
          if (state is Authenticated) {
            return const HomePage();
          }

          //loading
          else {
            return const Loading();
          }
          }, 
          //listen for state changes
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).
              showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        )
      )
    );
  }
}
