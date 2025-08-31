import 'package:flutter/material.dart';
import 'package:fyp/report/page/report_page.dart';
import 'package:fyp/chat/page/chat_list.dart';
import 'package:fyp/profile/page/profile_page.dart';
import 'package:fyp/Map/page/relief_centers_page.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  const MainScaffold({super.key, this.initialIndex = 1});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return; // Do nothing if already on the selected tab
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    // log
    // print('XXX selected index test: $_selectedIndex');
    switch (_selectedIndex) {
      case 0:
        body = ChatListPage(mainScaffoldContext: context, onTabChange: _onTabTapped);
        break;
      case 1:
        body = HomeContent();
        break;
      case 2:
        body = ProfilePage(mainScaffoldContext: context, onTabChange: _onTabTapped);
        break;
      default:
        body = HomeContent();
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flood Track'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.location_on),
                label: const Text('Relief Centers Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ReliefCentersPage(),
                    ),
                  );
                },
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.report),
              label: const Text('Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const ReportPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
