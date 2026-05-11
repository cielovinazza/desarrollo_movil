import 'package:flutter/material.dart';

import '../../../cliente/presentation/pages/registro_cliente_page.dart';

class HomePage extends StatelessWidget {

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          'Página Principal',
        ),

        centerTitle: true,

        actions: [

          IconButton(

            icon: const Icon(
              Icons.person_add,
            ),

            tooltip: 'Registrar cliente',

            onPressed: () {

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) =>
                      const RegistroClientePage(),
                ),
              );
            },
          ),
        ],
      ),

      body: Center(

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.home,
              size: 100,
            ),

            const SizedBox(height: 20),

            const Text(

              'Bienvenido al sistema',

              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Seleccione una opción del menú',
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(

              onPressed: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (context) =>
                        const RegistroClientePage(),
                  ),
                );
              },

              icon: const Icon(
                Icons.person_add,
              ),

              label: const Text(
                'Registrar Cliente',
              ),

              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}