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

        body: ListView(
          children: [
            Container(
              height: 400.0,
              width: double.infinity,
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.only(
                left: 50.0,
                right: 50.0,
                top: 50.0,
                bottom: 50.0,
              ),
              color: Colors.blueGrey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Center(
                        child: Text(
                          'Izquierda',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Container(
                      color: const Color.fromARGB(255, 255, 206, 59),
                      child: const Center(
                        child: Text(
                          'Centro',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Container(
                      color: const Color.fromARGB(255, 35, 17, 240),
                      child: const Center(
                        child: Text(
                          'Derecha',
                          style: TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.0),
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
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.blueAccent,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Mensajes',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(
              icon: Icon(Icons.cabin_rounded),
              label: 'Comunidad',
            ),
          ],
        ),
      ),
    );
  }
}
