import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shop_app/views/search.dart';
import 'views/countryList.dart';
import 'views/homeScreen.dart';
import 'views/product.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHiveForFlutter(); // for cache
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}


class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Screens for each BottomNavigationBar item
  final List<Widget> _screens = [
    ProductListScreen(),
    SearchScreen(),
    ProductScreen(),
    CountryListScreen(),
  ];

  // Titles for the AppBar
  final List<String> _titles = [
    "Home",
    "Search",
    "Product",
    "Countries",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only( 
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          ),
        title: Text(_titles[_currentIndex], 
        style: const TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        ),
        centerTitle: true,
        leading:IconButton(onPressed:(){},
         icon: const Icon(Icons.menu,
             color: Colors.white,),),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: IconButton(onPressed: (){},
             icon: const Icon(Icons.settings,
             color: Colors.white,
             ),)
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Search",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Product",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag),
            label: "Countries",
          ),
        ],
      ),
    );
  }
}

// Dummy screens for the tabs

