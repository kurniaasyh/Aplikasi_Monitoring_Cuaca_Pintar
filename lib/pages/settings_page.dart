
import 'package:flutter/material.dart';
import 'package:flutter_aplikasi_cuaca/main.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MyApp.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // BAGIAN TAMPILAN
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Tampilan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Card(
            child: SwitchListTile(
              secondary: Icon(
                app.isDarkMode
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              title: const Text('Mode Gelap'),
              subtitle: Text(
                app.isDarkMode
                    ? 'Tema gelap sedang digunakan'
                    : 'Tema terang sedang digunakan',
              ),
              value: app.isDarkMode,
              onChanged: (value) {
                app.toggleTheme();
              },
            ),
          ),

          const SizedBox(height: 20),

          // BAGIAN PREFERENSI CUACA
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Preferensi Cuaca',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.thermostat),
              title: const Text('Satuan Suhu'),
              subtitle: const Text(
                'Pilih satuan temperatur yang digunakan',
              ),
              trailing: DropdownButton<bool>(
                value: app.isCelsius,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: Text('°C'),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text('°F'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    app.setTemperatureUnit(value);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // INFORMASI APLIKASI
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Tentang',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Card(
            child: ListTile(
              leading: Icon(Icons.cloud),
              title: Text('Smart Weather'),
              subtitle: Text(
                'Aplikasi pemantauan cuaca berbasis Flutter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
