import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:kozo/components/my_widgets.dart';
import 'package:kozo/main.dart';

Future<String> _loadHtmlFromAssets() async {
  return await rootBundle.loadString('assets/privacy.html');
}

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>(); // Drawer表示用のキー

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      scaffoldKey: scaffoldKey,
      header: MyHeader(
        left: [
          MyIconButton(
            icon: Icons.menu, 
            message: "メニュー", 
            onPressed: (){
              scaffoldKey.currentState!.openDrawer();
            },
          ),
          const Text("kozo", style: TextStyle(fontSize: 24),),
        ],
      ),

      drawer: drawer(context),

      body: FutureBuilder<String>(
        future: _loadHtmlFromAssets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return SingleChildScrollView( // スクロールが必要な場合に備えて
                child: SizedBox(
                  width: double.infinity,
                  child:Align(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1000,
                      ),
                      child: Html(data: snapshot.data!),
                    ),
                  )
                )
              );
            } else {
              return const Center(child: Text('Error loading HTML'));
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}