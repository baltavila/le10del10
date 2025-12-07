import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'album_screen.dart';
import 'auth_gate.dart';
import 'fotos_screen.dart';
import 'videos_screen.dart';
import 'creditos_screen.dart';
import 'tienda_screen.dart';
import 'redes_screen.dart';

/// 🔥 Inicialización de Firebase y arranque de la app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const Le10Del10App());
}

class Le10Del10App extends StatelessWidget {
  const Le10Del10App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Le 10 del 10',
      debugShowCheckedModeBanner: false,
      initialRoute: '/portada',
      routes: {
        '/portada': (_) => const PortadaScreen(),
        '/auth': (_) => const AuthGate(),
        '/menu': (_) => const MenuScreen(),
      },
    );
  }
}

/// 🖼️ Portada inicial
class PortadaScreen extends StatelessWidget {
  const PortadaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          Navigator.pushReplacementNamed(context, '/menu');
        } else {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            image: DecorationImage(
              image: AssetImage('assets/portada.PNG'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

/// 📜 Menú con botones invisibles perfectamente alineados y proporcionales
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/portada', (r) => false);
          }
        },
        child: const Icon(Icons.logout),
      ),
      body: Stack(
        children: [
          // 🖼 Fondo del menú
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/menu_bg.png'),
              fit: BoxFit.cover,
            ),
          ),

          // 🎵 Botón "Álbum"
          Positioned(
            left: width * 0.18,
            top: height * 0.30,
            width: width * 0.64,
            height: height * 0.08,
            child: _invisibleButton(context, const AlbumScreen()),
          ),

          // 🖼 Botón "Fotos"
          Positioned(
            left: width * 0.17,
            top: height * 0.41,
            width: width * 0.66,
            height: height * 0.085,
            child: _invisibleButton(context, const FotosScreen()),
          ),

          // 🎬 Botón "Videos"
          Positioned(
            left: width * 0.17,
            top: height * 0.50,
            width: width * 0.66,
            height: height * 0.085,
            child: _invisibleButton(context, const VideosScreen()),
          ),

          // 🌐 Botón "Redes"
          Positioned(
            left: width * 0.17,
            top: height * 0.60,
            width: width * 0.66,
            height: height * 0.085,
            child: _invisibleButton(context, const RedesScreen()),
          ),

          // 🛍 Botón "Tienda"
          Positioned(
            left: width * 0.17,
            top: height * 0.71,
            width: width * 0.66,
            height: height * 0.085,
            child: _invisibleButton(context, const TiendaScreen()),
          ),
        ],
      ),
    );
  }

  /// 🔘 Botón invisible que lleva a otra pantalla
  Widget _invisibleButton(BuildContext context, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Container(color: Colors.transparent),
    );
  }
}
