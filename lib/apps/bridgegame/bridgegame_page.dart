import 'package:flutter/material.dart';
import 'package:kozo/apps/bridgegame/bridgegame_data.dart';
import 'package:kozo/apps/bridgegame/bridgegame_painter.dart';
import 'package:kozo/components/my_widgets.dart';
import 'package:kozo/main.dart';

class BridgegamePage extends StatefulWidget {
  const BridgegamePage({super.key});

  @override
  State<BridgegamePage> createState() => _BridgegamePageState();
}

class _BridgegamePageState extends State<BridgegamePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // メニュー用キー
  late BridgegameData data; // データ
  int toolNum = 0;

  @override
  void initState() {
    super.initState();

    data = BridgegameData(onDebug: (value){});
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold (
      scaffoldKey: _scaffoldKey,

      drawer: drawer(context),

      // ヘッダーメニュー
      header: MyHeader(
        isBorder: true,

        left: [
          //メニューボタン
          MyIconButton(
            icon: Icons.menu, 
            message: "メニュー",
            onPressed: (){
              _scaffoldKey.currentState!.openDrawer();
            },
          ),
          if(!data.isCalculation)...{
            // ツールメニュー
            MyIconToggleButtons(
              icons: const [Icons.edit, Icons.auto_fix_normal], 
              messages: const ['ペン','消しゴム'],
              value: toolNum, 
              onPressed: (value){
                setState(() {
                  toolNum = value;
                });
              }
            ),
            // 対称化ボタン
            MyIconButton(
              icon: Icons.switch_right,
              message: "対称化（左を右にコピー）",
              onPressed: () {
                setState(() {
                  data.symmetrical();
                });
              },
            ),
          },
        ],

        right: [
          if(!data.isCalculation)...{
            // 解析開始ボタン
            MyIconButton(
              icon: Icons.play_arrow,
              message: "計算",
              onPressed: (){
                if(data.elemCount() <= 1000){
                  setState(() {
                    data.calculation();
                  });
                }else{
                  snacbar();
                }
              },
            ),
          }else...{
            // 再開ボタン
            MyIconButton(
              icon: Icons.restart_alt,
              message: "再編集",
              onPressed: (){
                setState(() {
                  data.resetCalculation();
                });
              },
            ),
          }
        ],
      ),

      // メインビュー
      body: MyCustomPaint(
        onTap: (position) {
          if(data.isCalculation){
            setState(() {
              data.selectElem(position,0);
              if(data.selectedNumber >= 0){
                data.selectedNumber = data.selectedNumber;
              }
            });
          }
        },
        onDrag: (position) {
          if(!data.isCalculation){
            setState(() {
              data.selectElem(position,0);
              if(data.selectedNumber >= 0){
                if(data.elemList[data.selectedNumber].isCanPaint){
                  if(toolNum == 0 && data.elemList[data.selectedNumber].e < 1){
                    data.elemList[data.selectedNumber].e = 1;
                  }
                  else if(toolNum == 1 && data.elemList[data.selectedNumber].e > 0){
                    data.elemList[data.selectedNumber].e = 0;
                  }
                }
              }
            });
          }
        },
        painter: BridgegamePainter(data: data),
      ),
    );
  }

  // メッセージ
  void snacbar(){
    final snackBar = SnackBar(
      content: const Text('体積は1000以下にしよう'),
      action: SnackBarAction(
        label: '閉じる', 
        onPressed: () {  },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}