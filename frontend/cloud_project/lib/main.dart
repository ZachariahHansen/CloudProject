// import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'features/screens/createUser/createUser.dart';
import 'features/screens/login/loginScreen.dart';
// import 'features/screens/home/homeScreen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_project/features/scripts/session_check.dart';
// import 'features/scripts/session_check.dart';
// import 'package:form_field_validator/form_field_validator.dart';

void main() {
  runApp(MyApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Survive the Night',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 122, 0, 150)),
        ),
        debugShowCheckedModeBanner: false,
        home: FutureBuilder<bool>(
          future: hasValidSession(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            // } else if (snapshot.hasData && snapshot.data!) {
            //   return MyHomePage();
            } else {
              return MyIndexPage();
            }
          },
        ),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {}

class MyIndexPage extends StatefulWidget {
  @override
  State<MyIndexPage> createState() => _MyIndexPageState();
}

class _MyIndexPageState extends State<MyIndexPage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              color: Theme.of(context).colorScheme.background,
              width: constraints.maxWidth >= 1200 ? 370 : 0,
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(),
          SizedBox(height: 30),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LogInPage()),
                  );
                },
                child: Text('SIGN IN'),
              ),
              SizedBox(width: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CreateUserPage()),
                  );
                },
                child: Text('NEW USER'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final style = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(90.0),
        child: Text('Survive the Night', style: style),
      ),
    );
  }
}