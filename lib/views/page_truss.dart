import 'package:flutter/material.dart';
import 'package:kozo/components/painter.dart';
import 'package:kozo/components/widgets.dart';
import 'package:kozo/models/data.dart';

class PageTruss extends StatefulWidget {
  const PageTruss({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<PageTruss> createState() => _PageTrussState();
}

class _PageTrussState extends State<PageTruss> {
  late GlobalKey<ScaffoldState> scaffoldKey;
  late Data data;
  List<String> devTypes = ["応力","ひずみ"];
  int toolTypeNum = 0, toolNum = 0, devTypeNum = 0;


  @override
  void initState() {
    super.initState();

    scaffoldKey = widget.scaffoldKey;
    data = Data(onDebug: (value){},);
    data.node = Node();
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      header: MyHeader(
        children: [
          // メニューボタン
          MyIconButton(
            icon: Icons.menu, 
            onPressed: (){
              scaffoldKey.currentState!.openDrawer();
            },
          ),
          if(!data.isCalculation)...{
            // ツールタイプ
            MyIconToggleButtons(
              icons: const [Icons.circle, Icons.square], 
              value: toolTypeNum, 
              onPressed: (value){
                setState(() {
                  toolTypeNum = value;
                  data.node = null;
                  data.elem = null;
                  if(toolTypeNum == 0 && toolNum == 0){
                    data.node = Node();
                    data.node!.number = data.nodeList.length;
                  }else if(toolTypeNum == 1 && toolNum == 0){
                    data.elem = Elem();
                    data.elem!.number = data.elemList.length;
                  }
                  data.initSelect();
                });
              }
            ),
            // ツール
            if(toolTypeNum < 2)...{
              MyIconToggleButtons(
                icons: const [Icons.add, Icons.touch_app], 
                value: toolNum, 
                onPressed: (value){
                  setState(() {
                    toolNum = value;
                    data.node = null;
                    data.elem = null;
                    if(toolTypeNum == 0 && toolNum == 0){
                      data.node = Node();
                      data.node!.number = data.nodeList.length;
                    }else if(toolTypeNum == 1 && toolNum == 0){
                      data.elem = Elem();
                      data.elem!.number = data.elemList.length;
                    }
                    data.initSelect();
                  });
                }
              ),
            }
          },
          const Expanded(child: SizedBox()),
          if(!data.isCalculation)...{
            // 解析開始ボタン
            MyIconButton(
              icon: Icons.play_arrow,
              onPressed: (){
                setState(() {
                  data.calculationTruss();
                });
              },
            ),
          }else...{
            // 解析結果選択
            MyMenuDropdown(
              items: devTypes,
              value: devTypeNum,
              onPressed: (value){
                setState(() {
                  devTypeNum = value;
                  data.selectResult(value);
                });
              },
            ),
            // 再開ボタン
            MyIconButton(
              icon: Icons.restart_alt,
              onPressed: (){
                setState(() {
                  data.resetCalculation();
                });
              },
            ),
          }
        ]
      ),

      body: Stack(
        children: [
          // メインビュー
          MyCustomPaint(
            onTap: (position) {
              setState(() {
                if(toolNum == 1){
                  if(toolTypeNum == 0){
                    data.selectNode(position);
                  }
                  else if(toolTypeNum == 1){
                    data.selectElem(position);
                  }
                }
                data.selectedNumber = data.selectedNumber;
              });
            },
            painter: TrussPainter(data: data,),
          ),
          if(!data.isCalculation)...{
            if(toolTypeNum == 0)...{
              if(toolNum == 0)...{
                // ノード追加
                nodeSetting(true),
              }
              else if(data.selectedNumber >= 0)...{
                // ノード選択
                nodeSetting(false),
              }
            }
            else if(toolTypeNum == 1)...{
              if(toolNum == 0)...{
                // 要素の追加
                elemSetting(true),
              }
              else if(data.selectedNumber >= 0)...{
                // 要素の削除
                elemSetting(false),
              }
            }
          },
        ]
      ),
    );
  }

  Widget nodeSetting(bool isAdd){
    // 共通部分
    List<MySettingItem> items(Node node){
      return [
        MySettingItem(
          titleName: "座標",
          children: [
            MySettingTextField(
              name: "x", 
              text: node.pos.dx.toString(), 
              onChanged: (value){
                if(double.tryParse(value) != null){
                  node.pos = Offset(double.parse(value), node.pos.dy);
                }
              }
            ),
            MySettingTextField(
              name: "y", 
              text: node.pos.dy.toString(), 
              onChanged: (value){
                if(double.tryParse(value) != null){
                  node.pos = Offset(node.pos.dx, double.parse(value));
                }
              }
            ),
          ],
        ),
        MySettingItem(
          titleName: "拘束",
          children: [
            MySettingCheckbox(
              name: "x", 
              value: node.constXY[0], 
              onChanged: (value){
                setState(() {
                  node.constXY[0] = value;
                });
              }
            ),
            MySettingCheckbox(
              name: "y", 
              value: node.constXY[1],
              onChanged: (value){
                setState(() {
                  node.constXY[1] = value;
                });
              }
            ),
          ],
        ),
        MySettingItem(
          titleName: "集中荷重",
          children: [
            MySettingTextField(
              name: "x", 
              text: node.loadXY[0].toString(), 
              onChanged: (value){
                if(double.tryParse(value) != null){
                  node.loadXY[0] = double.parse(value);
                }
              }
            ),
            MySettingTextField(
              name: "y", 
              text: node.loadXY[1].toString(), 
              onChanged: (value){
                if(double.tryParse(value) != null){
                  node.loadXY[1] = double.parse(value);
                }
              }
            ),
          ],
        ),
      ];
    }

    if(isAdd){
      // 追加時
      return MySetting(
        titleName: "No.${data.node!.number+1}",
        buttonName: "追加",
        onPressed: () {
          setState(() {
            data.addNode();
            data.initSelect();
          });
        },
        children: items(data.node!),
      );
    }
    else{
      // タッチ時
      return MySetting(
        titleName: "No.${data.nodeList[data.selectedNumber].number+1}",
        buttonName: "削除",
        onPressed: () {
          setState(() {
            data.removeNode(data.selectedNumber);
            data.initSelect();
          });
        },
        children: items(data.nodeList[data.selectedNumber]),
      );
    }
  }

  Widget elemSetting(bool isAdd){
    // 共通部分
    List<MySettingItem> items(Elem elem){
      return [
        MySettingItem(
          titleName: "節点番号",
          children: [
            MySettingTextField(
              name: "a", 
              text: (elem.nodes[0] != null) ? (elem.nodes[0]!.number+1).toString() : "", 
              onChanged: (value){
                if(int.tryParse(value) != null){
                  if(int.parse(value)-1 < data.nodeList.length){
                    elem.nodes[0] = data.nodeList[int.parse(value)-1];
                  }
                }
              }
            ),
            MySettingTextField(
              name: "b", 
              text: (elem.nodes[1] != null) ? (elem.nodes[1]!.number+1).toString() : "",
              onChanged: (value){
                if(double.tryParse(value) != null){
                  if(int.parse(value)-1 < data.nodeList.length){
                    elem.nodes[1] = data.nodeList[int.parse(value)-1];
                  }
                }
              }
            ),
          ],
        ),
        MySettingItem(
          titleName: "パラメータ",
          children: [
            MySettingTextField(
              name: "ヤング率", 
              text: elem.e.toString(), 
              onChanged: (value){
                if(double.tryParse(value) != null){
                  elem.e = double.parse(value);
                }
              }
            ),
            MySettingTextField(
              name: "断面積", 
              text: elem.v.toString(), 
              onChanged: (value){
                if(double.tryParse(value) != null){
                  elem.v = double.parse(value);
                }
              }
            ),
          ],
        ),
      ];
    }

    if(isAdd){
      // 追加時
      return MySetting(
        titleName: "No.${data.elem!.number+1}",
        buttonName: "追加",
        onPressed: () {
          setState(() {
            data.addElem();
            data.initSelect();
          });
        },
        children: items(data.elem!),
      );
    }
    else{
      // タッチ時
      return MySetting(
        titleName: "No.${data.elemList[data.selectedNumber].number+1}",
        buttonName: "削除",
        onPressed: () {
          setState(() {
            data.removeElem(data.selectedNumber);
            data.initSelect();
          });
        },
        children: items(data.elemList[data.selectedNumber]),
      );
    }
  }
}

class TrussPainter extends CustomPainter {
  const TrussPainter({required this.data});

  final Data data;

  @override
  void paint(Canvas canvas, Size size) {
    data.updateCanvasPos(const Offset(100, 0), Offset(size.width-100, size.height-100));

    Paint paint = Paint();

    if(!data.isCalculation){
      // 辺
      if(data.allElemList().isNotEmpty){
        for(int i = 0; i < data.allElemList().length; i++){
          if(data.allElemList()[i].nodes[0] != null && data.allElemList()[i].nodes[1] != null){
            if(data.allElemList()[i].isSelect){
              Painter().angleRectangle(canvas, data.allElemList()[i].nodes[0]!.canvasPos, 
                data.allElemList()[i].nodes[1]!.canvasPos, size.height/20, Colors.red, false);
            }else{
              Painter().angleRectangle(canvas, data.allElemList()[i].nodes[0]!.canvasPos, 
                data.allElemList()[i].nodes[1]!.canvasPos, size.height/20, const Color.fromARGB(255, 49, 49, 49), false);
            }
          }
        }
      }

      // 節点拘束
      paint = Paint()
        ..color = const Color.fromARGB(255, 0, 0, 0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      if(data.allNodeList().isNotEmpty){
        for(int i = 0; i < data.allNodeList().length; i++){
          if(data.allNodeList()[i].isSelect){
            paint.color = Colors.red;
          }else{
            paint.color = Colors.black;
          }
          Offset pos = data.allNodeList()[i].canvasPos;
          if(data.allNodeList()[i].constXY[0]){
            canvas.drawLine(Offset(pos.dx-5, pos.dy-5), Offset(pos.dx-5, pos.dy+5), paint);
            canvas.drawLine(Offset(pos.dx+5, pos.dy-5), Offset(pos.dx+5, pos.dy+5), paint);
          }
          if(data.allNodeList()[i].constXY[1]){
            canvas.drawLine(Offset(pos.dx-5, pos.dy-5), Offset(pos.dx+5, pos.dy-5), paint);
            canvas.drawLine(Offset(pos.dx-5, pos.dy+5), Offset(pos.dx+5, pos.dy+5), paint);
          }
        }
      }

      // 節点強制変位
      paint = Paint()
        ..color = const Color.fromARGB(255, 0, 0, 0)
        ..strokeWidth = 4;
      
      if(data.allNodeList().isNotEmpty){
        for(int i = 0; i < data.allNodeList().length; i++){
          if(data.allNodeList()[i].isSelect){
            paint.color = Colors.red;
          }else{
            paint.color = Colors.black;
          }
          Offset pos = data.allNodeList()[i].canvasPos;
          if(data.allNodeList()[i].loadXY[0] != 0){
            if(data.allNodeList()[i].loadXY[0] > 0){
              Painter().arrow(Offset(pos.dx+5, pos.dy), Offset(pos.dx+30, pos.dy), paint, canvas);
            }else{
              Painter().arrow(Offset(pos.dx-5, pos.dy), Offset(pos.dx-30, pos.dy), paint, canvas);
            }
          }
          if(data.allNodeList()[i].loadXY[1] != 0){
            if(data.allNodeList()[i].loadXY[1] > 0){
              Painter().arrow(Offset(pos.dx, pos.dy-5), Offset(pos.dx, pos.dy-30), paint, canvas);
            }else{
              Painter().arrow(Offset(pos.dx, pos.dy+5), Offset(pos.dx, pos.dy+30), paint, canvas);
            }
          }
        }
      }

      // 節点
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      if(data.allNodeList().isNotEmpty){
        for(int i = 0; i < data.allNodeList().length; i++){
          paint.style = PaintingStyle.fill;
          paint.color = Colors.white;
          canvas.drawCircle(data.allNodeList()[i].canvasPos, 5, paint);
          paint.style = PaintingStyle.stroke;
          if(data.allNodeList()[i].isSelect){
            paint.color = Colors.red;
          }else{
            paint.color = const Color.fromARGB(255, 50, 50, 50);
          }
          canvas.drawCircle(data.allNodeList()[i].canvasPos, 5, paint);
        }
      }

      // 節点番号
      if(data.allNodeList().isNotEmpty){
        for(int i = 0; i < data.allNodeList().length; i++){
          if(data.allNodeList()[i].isSelect){
            Painter().text(canvas, size.width, (i+1).toString(), Offset(data.allNodeList()[i].canvasPos.dx - 30, data.allNodeList()[i].canvasPos.dy - 30), 20, Colors.red);
          }else{
            Painter().text(canvas, size.width, (i+1).toString(), Offset(data.allNodeList()[i].canvasPos.dx - 30, data.allNodeList()[i].canvasPos.dy - 30), 20, Colors.black);
          }
        }
      }
    }
    else{

      final result = data.getValue();
      double max = result.$1;
      double min = result.$2;

      // 要素
      for(int i = 0; i < data.elemList.length; i++){
        Color color = const Color.fromARGB(0, 255, 255, 255);
        if(max != 0 || min != 0){
          if(data.type == 0){
            color = Painter().getColor((data.elemList[i].stlessXY[0] - min) / (max - min) * 100);
          }
          else if(data.type == 1){
            color = Painter().getColor((data.elemList[i].stlessXY[1] - min) / (max - min) * 100);
          }
          else if(data.type == 2){
            color = Painter().getColor((data.elemList[i].strainXY[0] - min) / (max - min) * 100);
          }
          else if(data.type == 3){
            color = Painter().getColor((data.elemList[i].strainXY[1] - min) / (max - min) * 100);
          }
        }

        Painter().angleRectangle(canvas, data.elemList[i].nodes[0]!.canvasAfterPos(),
          data.elemList[i].nodes[1]!.canvasAfterPos(), size.height/20, color, true);
        Painter().angleRectangle(canvas, data.elemList[i].nodes[0]!.canvasAfterPos(),
          data.elemList[i].nodes[1]!.canvasAfterPos(), size.height/20, const Color.fromARGB(255, 49, 49, 49), false);
      }

      // 節点
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for(int i = 0; i < data.nodeList.length; i++){
        paint.style = PaintingStyle.fill;
        paint.color = Colors.white;
        canvas.drawCircle(data.nodeList[i].canvasAfterPos(), 5, paint);
        paint.style = PaintingStyle.stroke;
        paint.color = Colors.black;
        canvas.drawCircle(data.nodeList[i].canvasAfterPos(), 5, paint);
      }

      // 虹色
      Painter().rainbowBand(canvas, Offset(size.width - 60, 50), Offset(size.width - 100, size.height - 50), 50);

      // 最大最小
      Painter().text(canvas, size.width, max.toStringAsFixed(2), Offset(size.width - 55, 40), 16, Colors.black);
      Painter().text(canvas, size.width, min.toStringAsFixed(2), Offset(size.width - 55, size.height - 60), 16, Colors.black);

      // 値
      for(int i = 0; i < data.elemList.length; i++){
        if(data.elemNode == 2){
          Offset pos1 = data.elemList[i].nodes[0]!.canvasAfterPos();
          Offset pos2 = data.elemList[i].nodes[1]!.canvasAfterPos();
          if(data.type == 0){
            Painter().text(canvas, size.width, data.elemList[i].stlessXY[0].toStringAsFixed(2), Offset((pos1.dx+pos2.dx)/2, (pos1.dy+pos2.dy)/2), 16, Colors.black);
          }else if(data.type == 2){
            Painter().text(canvas, size.width, data.elemList[i].strainXY[0].toStringAsFixed(2), Offset((pos1.dx+pos2.dx)/2, (pos1.dy+pos2.dy)/2), 16, Colors.black);
          }
        }
      }

      // 変位
      for(int i = 0; i < data.nodeList.length; i++){
        if(data.nodeList[i].loadXY[0] != 0 || data.nodeList[i].loadXY[1] != 0){
          String text = "変位\nx：${data.nodeList[i].becPos.dx.toStringAsFixed(2)}\ny：${data.nodeList[i].becPos.dy.toStringAsFixed(2)}";
          Painter().text(canvas, size.width, text, data.nodeList[i].canvasAfterPos(), 16, Colors.black);
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant TrussPainter oldDelegate) {
    return false;
  }
}