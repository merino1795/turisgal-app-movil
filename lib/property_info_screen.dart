import 'package:flutter/material.dart';

class PropertyInfoScreen extends StatelessWidget {
  final String propertyName;
  final List<String> inventory;
  final String description;

  const PropertyInfoScreen({
    super.key,
    required this.propertyName,
    required this.inventory,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          propertyName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECCIÓN: DESCRIPCIÓN
            const Text(
              "Descripción",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.6,
                fontSize: 15,
              ),
            ),
            const Divider(height: 40),

            // SECCIÓN: LO QUE OFRECE
            const Text(
              "Lo que ofrece este alojamiento",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 20),

            // RENDERIZADO INTELIGENTE DE LA LISTA
            ...inventory.map((item) {
              // 1. ¿ES UN TÍTULO DE SECCIÓN? (Empieza por SECTION:)
              if (item.startsWith("SECTION:")) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
                  child: Text(
                    item
                        .replaceFirst("SECTION:", "")
                        .toUpperCase(), // Quitamos el prefijo
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4F46E5), // Color Indigo
                      letterSpacing: 1.0,
                    ),
                  ),
                );
              }

              // 2. ¿ES UN ELEMENTO NORMAL?
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 20, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // Espacio final para que no se corte
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
