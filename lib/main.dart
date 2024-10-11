import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kozo/components/widgets.dart';
import 'package:kozo/views/page_analysis/page_analysis.dart';
import 'package:kozo/views/page_grid.dart';
// import 'package:kozo/views/page_truss.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // ステータスバーの背景色を透明にする
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return const MaterialApp(
      title: "kozo",
      debugShowCheckedModeBanner: false,
      home: MainView(),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => MainViewState();
}

class MainViewState extends State<MainView> {
  int pageNum = 0;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      drawer: MyDrawer(
        itemList: const ["トラス","橋",], 
        onTap: (number){
          setState(() {
            pageNum = number;
          });
        }
      ),

      body: Column(
        children: [
          if(pageNum == 1) PageGrid(scaffoldKey: scaffoldKey,)
          // else if(pageNum == 1) PageTruss(scaffoldKey: scaffoldKey,),
          else if(pageNum == 0) PageAnalysis(scaffoldKey: scaffoldKey,),
        ],
      ),
    );
  }
}