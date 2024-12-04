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
  late GlobalKey<ScaffoldState> scaffoldKey; // メニュー用キー
  late Data data; // データ
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
                  data.calculation(1);
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
                  if(value == 0){
                    data.selectResult(0);
                  }else{
                    data.selectResult(5);
                  }
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
              if(!data.isCalculation){
                setState(() {
                  if(toolNum == 1){
                    if(toolTypeNum == 0){
                      data.selectNode(position);
                    }
                    else if(toolTypeNum == 1){
                      data.selectElem(position,0);
                    }
                  }
                  data.selectedNumber = data.selectedNumber;
                });
              }
            },
            painter: TrussPainter(data: data),
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
              value: node.constXYR[0], 
              onChanged: (value){
                setState(() {
                  node.constXYR[0] = value;
                });
              }
            ),
            MySettingCheckbox(
              name: "y", 
              value: node.constXYR[1],
              onChanged: (value){
                setState(() {
                  node.constXYR[1] = value;
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
              text: (elem.nodeList[0] != null) ? (elem.nodeList[0]!.number+1).toString() : "", 
              onChanged: (value){
                if(int.tryParse(value) != null){
                  if(int.parse(value)-1 < data.nodeList.length){
                    elem.nodeList[0] = data.nodeList[int.parse(value)-1];
                  }
                }
              }
            ),
            MySettingTextField(
              name: "b", 
              text: (elem.nodeList[1] != null) ? (elem.nodeList[1]!.number+1).toString() : "",
              onChanged: (value){
                if(double.tryParse(value) != null){
                  if(int.parse(value)-1 < data.nodeList.length){
                    elem.nodeList[1] = data.nodeList[int.parse(value)-1];
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
    data.updateCanvasPos(Rect.fromLTRB(100+size.width/10, 100+size.height/10, size.width-100-size.width/10, size.height-100-size.height/10), 1);
    List<Node> nodes = data.allNodeList();
    List<Elem> elems = data.allElemList();

    Paint paint = Paint();

    if(!data.isCalculation){
      // 辺
      if(elems.isNotEmpty){
        for(int i = 0; i < elems.length; i++){
          if(elems[i].nodeList[0] != null && elems[i].nodeList[1] != null){
            Offset p0 = elems[i].nodeList[0]!.canvasPos;
            Offset p1 = elems[i].nodeList[1]!.canvasPos;
            if(elems[i].isSelect){
              Painter().angleRectangle(canvas, p0, p1, data.canvasData.percentToCWidth(5), Colors.red, false);
            }else{
              Painter().angleRectangle(canvas, p0, p1, data.canvasData.percentToCWidth(5), const Color.fromARGB(255, 49, 49, 49), false);
            }
          }
        }
      }

      // 節点拘束
      paint = Paint()
        ..color = const Color.fromARGB(255, 0, 0, 0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      if(nodes.isNotEmpty){
        for(int i = 0; i < nodes.length; i++){
          if(nodes[i].isSelect){
            paint.color = Colors.red;
          }else{
            paint.color = Colors.black;
          }
          paint.style = PaintingStyle.fill;
          if(nodes[i].constXYR[0] && nodes[i].constXYR[1]){
            paint.color = const Color.fromARGB(255, 0, 0, 0);
          }
          else if(nodes[i].constXYR[0]){
            paint.color = Colors.green;
          }
          else if(nodes[i].constXYR[1]){
            paint.color = Colors.blue;
          }
          else{
            paint.color = Colors.white;
          }
          canvas.drawCircle(nodes[i].canvasPos, 5, paint);
        }
      }

      // 節点強制変位
      paint = Paint()
        ..color = const Color.fromARGB(255, 0, 0, 0)
        ..strokeWidth = 4;
      
      if(nodes.isNotEmpty){
        for(int i = 0; i < nodes.length; i++){
          if(nodes[i].isSelect){
            paint.color = Colors.red;
          }else{
            paint.color = Colors.black;
          }
          Offset pos = nodes[i].canvasPos;
          if(nodes[i].loadXY[0] != 0){
            if(nodes[i].loadXY[0] > 0){
              Painter().arrow(Offset(pos.dx+5, pos.dy), Offset(pos.dx+30, pos.dy), 3, canvas);
            }else{
              Painter().arrow(Offset(pos.dx-5, pos.dy), Offset(pos.dx-30, pos.dy), 3, canvas);
            }
          }
          if(nodes[i].loadXY[1] != 0){
            if(nodes[i].loadXY[1] > 0){
              Painter().arrow(Offset(pos.dx, pos.dy-5), Offset(pos.dx, pos.dy-30), 3, canvas);
            }else{
              Painter().arrow(Offset(pos.dx, pos.dy+5), Offset(pos.dx, pos.dy+30), 3, canvas);
            }
          }
        }
      }

      // 節点
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      if(nodes.isNotEmpty){
        for(int i = 0; i < nodes.length; i++){
          if(nodes[i].isSelect){
            paint.color = Colors.red;
          }else{
            paint.color = const Color.fromARGB(255, 50, 50, 50);
          }
          canvas.drawCircle(nodes[i].canvasPos, 5, paint);
        }
      }

      // 節点番号
      if(nodes.isNotEmpty){
        for(int i = 0; i < nodes.length; i++){
          Offset pos = nodes[i].canvasPos;
          if(nodes[i].isSelect){
            Painter().text(canvas, size.width, (i+1).toString(), Offset(pos.dx - 30, pos.dy - 30), 20, Colors.red);
          }else{
            Painter().text(canvas, size.width, (i+1).toString(), Offset(pos.dx - 30, pos.dy - 30), 20, Colors.black);
          }
        }
      }
    }
    else{
      // 要素
      for(int i = 0; i < data.elemList.length; i++){
        Color color = const Color.fromARGB(0, 255, 255, 255);
        if(data.resultMax != 0 || data.resultMin != 0){
          color = Painter().getColor((data.resultList[i] - data.resultMin) / (data.resultMax - data.resultMin) * 100);
        }

        Offset p0 = data.elemList[i].nodeList[0]!.canvasAfterPos;
        Offset p1 = data.elemList[i].nodeList[1]!.canvasAfterPos;
        Painter().angleRectangle(canvas, p0, p1, data.canvasData.percentToCWidth(5), color, true);
        Painter().angleRectangle(canvas, p0, p1, data.canvasData.percentToCWidth(5), const Color.fromARGB(255, 49, 49, 49), false);
      }

      // 節点
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for(int i = 0; i < data.nodeList.length; i++){
        Offset p = data.nodeList[i].canvasAfterPos;
        paint.style = PaintingStyle.fill;
        paint.color = Colors.white;
        canvas.drawCircle(p, 5, paint);
        paint.style = PaintingStyle.stroke;
        paint.color = Colors.black;
        canvas.drawCircle(p, 5, paint);
      }

      // 虹色
      Painter().rainbowBand(canvas, Offset(size.width - 60, 50), Offset(size.width - 100, size.height - 50), 50);

      // 最大最小
      Painter().text(canvas, size.width, data.resultMax.toStringAsFixed(2), Offset(size.width - 55, 40), 16, Colors.black);
      Painter().text(canvas, size.width, data.resultMin.toStringAsFixed(2), Offset(size.width - 55, size.height - 60), 16, Colors.black);

      // 値
      for(int i = 0; i < data.elemList.length; i++){
        if(data.elemNode == 2){
          Offset pos1 = data.elemList[i].nodeList[0]!.canvasAfterPos;
          Offset pos2 = data.elemList[i].nodeList[1]!.canvasAfterPos;
          Painter().text(canvas, size.width, data.resultList[i].toStringAsFixed(2), Offset((pos1.dx+pos2.dx)/2, (pos1.dy+pos2.dy)/2), 16, Colors.black);
        }
      }

      // 変位
      for(int i = 0; i < data.nodeList.length; i++){
        if(data.nodeList[i].loadXY[0] != 0 || data.nodeList[i].loadXY[1] != 0){
          String text = "変位\nx：${data.nodeList[i].becPos.dx.toStringAsFixed(2)}\ny：${data.nodeList[i].becPos.dy.toStringAsFixed(2)}";
          Painter().text(canvas, size.width, text, data.nodeList[i].canvasAfterPos, 16, Colors.black);
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant TrussPainter oldDelegate) {
    return false;
  }
}