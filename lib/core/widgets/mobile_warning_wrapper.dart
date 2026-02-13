import 'package:flutter/material.dart';

class MobileWarningWrapper extends StatelessWidget {
  final Widget child;

  const MobileWarningWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.desktop_windows, size: 80, color: Colors.grey),
                    SizedBox(height: 24),
                    Text(
                      'Versão Desktop',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Este aplicativo não está otimizado para celulares.\nPor favor, acesse através de um computador para a melhor experiência.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}
