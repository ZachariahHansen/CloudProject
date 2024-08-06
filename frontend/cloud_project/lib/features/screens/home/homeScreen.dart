import 'package:flutter/material.dart';
import 'package:cloud_project/features/screens/home/homeGenerator.dart';
// import 'package:cloud_project/features/screens/location/locationScreen.dart';
// import 'package:cloud_project/features/screens/messages/messages/messageScreen.dart';
// import 'package:cloud_project/features/screens/profile/view/profileScreen.dart';
// import 'package:cloud_project/features/screens/search/searchScreen.dart';

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GenerateHomePage();
        break;
      // case 1:
      //   page = LocationPage();
      //   break;
      // case 2:
      //   page = MessagesPage();
      //   break;
      // case 3:
      //   page = SearchPage();
      //   break;
      // case 4:
      //   page = ProfilePage();
      //   break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.15,
            child: NavigationRail(
              extended: true,
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add_location_sharp),
                  label: Text('Location'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.message_rounded),
                  label: Text('Messages'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_box_rounded),
                  label: Text('Search'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_box_rounded),
                  label: Text('Profile'),
                ),
              ],
            ),
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
  }
}
