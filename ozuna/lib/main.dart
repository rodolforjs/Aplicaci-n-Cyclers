import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            color: Colors.white,
            onPressed: () {},
          ),
          title: const Text('Clase uno', style: TextStyle(color: Colors.white)),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'perfil',
                  child: Row(
                    children: [
                      Icon(Icons.account_circle),
                      SizedBox(width: 10),
                      Text('Perfil'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'config',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 10),
                      Text('Config'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              height: 570.0,
              width: double.infinity,
              color: Colors.blueGrey,
              child: const Text('ozunaaaa'),
            ),
            Container(
              height: 570.0,
              width: double.infinity,
              color: Colors.blueGrey,
              child: const Text('ozunaaaa'),
            ),
            Container(
              height: 570.0,
              width: double.infinity,
              color: Colors.blueGrey,
              child: const Text('ozunaaaa'),
            ),
          ],
        ),

        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Mensajes',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          ],
        ),
      ),
    );
  }
}
