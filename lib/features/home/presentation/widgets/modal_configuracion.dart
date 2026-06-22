import 'package:flutter/material.dart';

class ConfiguracionModal extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback? onCerrarSesion;

  const ConfiguracionModal({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    this.onCerrarSesion,
  });

  @override
  State<ConfiguracionModal> createState() => _ConfiguracionModalState();
}

class _ConfiguracionModalState extends State<ConfiguracionModal> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Text(
            'Configuración',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          SwitchListTile(
            title: const Text('Modo Oscuro'),
            secondary: Icon(
              _isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
              widget.onThemeChanged(value);
            },
          ),

          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sincronizar datos'),
            subtitle: const Text('Sincronización manual con Firebase'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronización manual seleccionada'),
                ),
              );
            },
          ),

          const Divider(height: 24),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
           
            onTap: () => _confirmarCerrarSesion(context),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context); 
              widget.onCerrarSesion?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}