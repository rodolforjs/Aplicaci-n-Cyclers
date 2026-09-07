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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_left),
            color: Colors.black,
            onPressed: () {},
          ),
          title: const Text(
            'Letterboxd',
            style: TextStyle(
              color: Colors.black,
              backgroundColor: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.keyboard_arrow_right, color: Colors.black),
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
              height: 520.0,
              width: double.infinity,
              color: Colors.grey,
            ),
            SizedBox(height: 96.0),
            Container(
              height: 50.0,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(color: Colors.grey),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(color: Colors.grey),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(color: Colors.grey),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 120.0,
              width: double.infinity,
              margin: const EdgeInsets.only(
                left: 6.0,
                right: 0,
                top: 8.0,
                bottom: 16.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(123, 255, 0, 0),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 81, 81, 82),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(117, 177, 24, 111),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(169, 81, 71, 63),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 48.0),

            Container(
              height: 50.0,
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: const Border(
                          bottom: BorderSide(color: Colors.black, width: 5.0),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'FILTROS',
                          style: TextStyle(color: Colors.black, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Container(
                      child: const Center(
                        child: Text(
                          'EDITAR',
                          style: TextStyle(color: Colors.black, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 48.0),
          ],
        ),

        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.rectangle),
              label: 'Mensajes',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.circle), label: 'Buscar'),
            BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
