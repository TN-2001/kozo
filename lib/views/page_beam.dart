import 'package:flutter/material.dart';
import 'package:kozo/components/painter.dart';
import 'package:kozo/components/widgets.dart';
import 'package:kozo/models/data.dart';

class PageBeam extends StatefulWidget {
  const PageBeam({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<PageBeam> createState() => _PageBeamState();
}

class _PageBeamState extends State<PageBeam> {
  late GlobalKey<ScaffoldState> scaffoldKey;
  late Data data;
  List<String> devTypes = ["せん断力","曲げモーメント","たわみ","たわみ角"];
  int devTypeNum = 0;
  int toolTypeNum = 0, toolNum = 0;


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
                  data.calculation(2);
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
                    data.selectElem(position, 0);
                  }
                }
                data.selectedNumber = data.selectedNumber;
              });
            },
            painter: BeamPainter(data: data, devTypeNum: devTypeNum),
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
            MySettingCheckbox(
              name: "回転", 
              value: node.constXYR[2],
              onChanged: (value){
                setState(() {
                  node.constXYR[2] = value;
                });
              }
            ),
            MySettingCheckbox(
              name: "ヒンジ", 
              value: node.constXYR[3],
              onChanged: (value){
                setState(() {
                  node.constXYR[3] = value;
                });
              }
            ),
          ],
        ),
        MySettingItem(
          titleName: "集中荷重",
          children: [
            MySettingTextField(
              name: "鉛直", 
              text: node.loadXY[1].toString(), 
              onChanged: (value){
                if(double.tryParse(value) != null){
                  node.loadXY[1] = double.parse(value);
                }
              }
            ),
            MySettingTextField(
              name: "モーメント", 
              text: node.loadXY[2].toString(), 
              onChanged: (value){
                if(double.tryParse(value) != null){
                  node.loadXY[2] = double.parse(value);
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
              name: "断面二次モーメント", 
              text: elem.v.toString(), 
              onChanged: (value){
                if(double.tryParse(value) != null){
                  elem.v = double.parse(value);
                }
              }
            ),
          ],
        ),
        MySettingItem(
          titleName: "分布荷重",
          children: [
            MySettingTextField(
              name: "鉛直", 
              text: elem.load.toString(), 
              onChanged: (value){
                if(double.tryParse(value) != null){
                  elem.load = double.parse(value);
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

class BeamPainter extends CustomPainter {
  const BeamPainter({required this.data, required this.devTypeNum});

  final Data data;
  final int devTypeNum;

  @override
  void paint(Canvas canvas, Size size) {
    Rect dataRect = data.rect();
    data.updateCanvasPos(Rect.fromLTRB(100+size.width/10, 100+size.height/10, size.width-100-size.width/10, size.height-100-size.height/10), 1);
    List<Node> nodes = data.allNodeList();
    List<Elem> elems = data.allElemList();

    Paint paint = Paint();

    if(!data.isCalculation){
      // 辺
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;
      if(elems.isNotEmpty){
        for(int i = 0; i < elems.length; i++){
          if(elems[i].nodeList[0] != null && elems[i].nodeList[1] != null){
            if(elems[i].isSelect){
              paint.color = Colors.red;
              canvas.drawLine(elems[i].nodeList[0]!.canvasPos, elems[i].nodeList[1]!.canvasPos, paint);
            }else{
              paint.color = const Color.fromARGB(255, 86, 86, 86);
              canvas.drawLine(elems[i].nodeList[0]!.canvasPos, elems[i].nodeList[1]!.canvasPos, paint);
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
          paint.style = PaintingStyle.fill;
          if(nodes[i].constXYR[0] && nodes[i].constXYR[1] && nodes[i].constXYR[2]){ // 壁
            if(nodes[i].pos.dx < dataRect.center.dx){
              Offset cpos = nodes[i].canvasPos;
              paint.color = const Color.fromARGB(255, 141, 141, 141);
              canvas.drawRect(Rect.fromLTRB(cpos.dx-50, size.height/2-100, cpos.dx, size.height/2+100), paint);
              paint.color = Colors.black;
              canvas.drawLine(Offset(cpos.dx, size.height/2-100), Offset(cpos.dx, size.height/2+100), paint);
            }
            else{
              Offset cpos = nodes[i].canvasPos;
              paint.color = const Color.fromARGB(255, 141, 141, 141);
              canvas.drawRect(Rect.fromLTRB(cpos.dx, size.height/2-100, cpos.dx+50, size.height/2+100), paint);
              paint.color = Colors.black;
              canvas.drawLine(Offset(cpos.dx, size.height/2-100), Offset(cpos.dx, size.height/2+100), paint);
              break;
            }
          }
          else if(nodes[i].constXYR[1]){
            Offset cpos = nodes[i].canvasPos;
            paint.style = PaintingStyle.stroke;
            Path path = Path();
            path.moveTo(cpos.dx, cpos.dy+5);
            path.lineTo(cpos.dx-10, cpos.dy+25);
            path.lineTo(cpos.dx+10, cpos.dy+25);
            path.close();
            canvas.drawPath(path, paint);

            if(!nodes[i].constXYR[0]){
              canvas.drawLine(Offset(cpos.dx-10, cpos.dy+30), Offset(cpos.dx+10, cpos.dy+30), paint);
            }
          }
          canvas.drawCircle(nodes[i].canvasPos, 5, paint);
        }
      }

      // 荷重
      paint = Paint()
        ..color = const Color.fromARGB(255, 0, 0, 0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      
      if(nodes.isNotEmpty){
        for(int i = 0; i < nodes.length; i++){
          Offset pos = nodes[i].canvasPos;
          if(nodes[i].loadXY[1] != 0){
            if(nodes[i].loadXY[1] < 0){
              Painter().arrow(Offset(pos.dx, pos.dy-75), Offset(pos.dx, pos.dy-5), 5, canvas);
            }else{
              Painter().arrow(Offset(pos.dx, pos.dy+75), Offset(pos.dx, pos.dy+5), 5, canvas);
            }
          }

          if(nodes[i].loadXY[2] != 0.0){ // 曲げモーメント
            paint.style = PaintingStyle.stroke;
            canvas.drawCircle(pos, 40, paint);
            paint.style = PaintingStyle.fill;
            if(nodes[i].loadXY[2] > 0){
              Painter().arrow(Offset(pos.dx, pos.dy-40), Offset(pos.dx-13, pos.dy-40), 5, canvas);
              Painter().arrow(Offset(pos.dx, pos.dy+40), Offset(pos.dx+13, pos.dy+40), 5, canvas);
            }else{
              Painter().arrow(Offset(pos.dx, pos.dy-40), Offset(pos.dx+13, pos.dy-40), 5, canvas);
              Painter().arrow(Offset(pos.dx, pos.dy+40), Offset(pos.dx-13, pos.dy+40), 5, canvas);
            }
          }
        }
      }

      if(elems.isNotEmpty){
        for(int i = 0; i < elems.length; i++){
          if(elems[i].nodeList[0] != null && elems[i].nodeList[1] != null && elems[i].load != 0.0){
            double left = 0.0;
            double right = 0.0;
            if(elems[i].nodeList[0]!.pos.dx > elems[i].nodeList[1]!.pos.dx){
              left = elems[i].nodeList[1]!.pos.dx;
              right = elems[i].nodeList[0]!.pos.dx;
            }else{
              left = elems[i].nodeList[0]!.pos.dx;
              right = elems[i].nodeList[1]!.pos.dx;
            }
            double width = right-left;
            int count = (width/(dataRect.width/10)).toInt();
            for(int j = 0; j <= count; j++){
              Offset cpos = data.canvasData.dToC(Offset(left+width/count*j, 0));
              if(elems[i].load < 0){
                Painter().arrow(Offset(cpos.dx, cpos.dy-50), Offset(cpos.dx, cpos.dy-5), 3, canvas);
              }
              else{
                Painter().arrow(Offset(cpos.dx, cpos.dy+50), Offset(cpos.dx, cpos.dy+5), 3, canvas);
              }
            }
            Offset cleftPos = data.canvasData.dToC(Offset(left, 0));
            Offset cRightPos = data.canvasData.dToC(Offset(right, 0));
            if(elems[i].load < 0){
              canvas.drawLine(Offset(cleftPos.dx, cleftPos.dy-50), Offset(cRightPos.dx, cRightPos.dy-50), paint);
            }else{
              canvas.drawLine(Offset(cleftPos.dx, cleftPos.dy+50), Offset(cRightPos.dx, cRightPos.dy+50), paint);
            }
          }
        }
      }

      // 節点
      paint = Paint()
        ..strokeWidth = 2;

      if(nodes.isNotEmpty){
        for(int i = 0; i < nodes.length; i++){
          paint.style = PaintingStyle.fill;
          if(nodes[i].constXYR[3]){ // ヒンジ
            paint.color = Colors.white;
          }
          else{
            paint.color = const Color.fromARGB(255, 79, 79, 79);
          }
          canvas.drawCircle(nodes[i].canvasPos, 7.5, paint);

          paint.style = PaintingStyle.stroke;
          if(nodes[i].isSelect){
            paint.color = Colors.red;
          }else{
            paint.color = const Color.fromARGB(255, 50, 50, 50);
          }
          canvas.drawCircle(nodes[i].canvasPos, 7.5, paint);
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
      // 結果
      if(devTypeNum == 0) // せん断力
      {
        paint = Paint()
          ..color = const Color.fromARGB(255, 0, 0, 0)
          ..style = PaintingStyle.fill;

        double max = 0.0;
        double min = 0.0;
        for(int i = 1; i < data.resultElemList.length; i++){
          if(max < data.resultElemList[i].result[4]) max = data.resultElemList[i].result[4];
          if(min > data.resultElemList[i].result[4]) min = data.resultElemList[i].result[4];
        }
        double maxAbs = 0.0;
        double scale = 1.0;
        if(max.abs() > min.abs()){
          maxAbs = max.abs();
        }else{
          maxAbs = min.abs();
        }
        scale = (size.height/data.canvasData.scale/6) / maxAbs;
        List<double> sList = List.filled(data.resultElemList.length, 0);
        for(int i = 0; i < data.resultElemList.length; i++){
          sList[i] = data.resultElemList[i].result[4]*scale;
        }

        for(int i = 0; i < data.resultElemList.length; i++){
          double topLeftY = 0;
          double topRightY = 0;
          if(i == 0){
            topLeftY = sList[i] + (sList[i]-sList[i+1]) / 2;
          }else{
            topLeftY = sList[i] + (sList[i-1]-sList[i]) / 2;
          }
          if(i == data.resultElemList.length-1){
            topRightY = sList[i] + (sList[i]-sList[i-1]) / 2;
          }else{
            topRightY = sList[i] + (sList[i+1]-sList[i]) / 2;
          }
          Offset topLeft = data.canvasData.dToC(Offset(data.resultElemList[i].nodeList[0]!.afterPos.dx, topLeftY));
          Offset topRight = data.canvasData.dToC(Offset(data.resultElemList[i].nodeList[1]!.afterPos.dx, topRightY));
          Offset bottomRight = data.canvasData.dToC(Offset(data.resultElemList[i].nodeList[1]!.afterPos.dx, 0));
          paint.color = const Color.fromARGB(255, 153, 194, 228);
          Path path = Path();
          path.moveTo(topLeft.dx, topLeft.dy);
          path.lineTo(topRight.dx, topRight.dy);
          path.lineTo(topRight.dx, bottomRight.dy);
          path.lineTo(topLeft.dx, bottomRight.dy);
          path.close();
          canvas.drawPath(path, paint);
          paint.color = Colors.black;
          canvas.drawLine(topLeft, topRight, paint);
        }

        drawm(max, min, scale, false, canvas, size);
      }
      else if(devTypeNum == 1) // 曲げモーメント
      {
        paint = Paint()
          ..color = const Color.fromARGB(255, 0, 0, 0)
          ..style = PaintingStyle.fill;

        double max = 0.0;
        double min = 0.0;
        for(int i = 1; i < data.resultElemList.length; i++){
          if(max < data.resultElemList[i].result[5]) max = data.resultElemList[i].result[5];
          if(min > data.resultElemList[i].result[5]) min = data.resultElemList[i].result[5];
          if(max < data.resultElemList[i].result[6]) max = data.resultElemList[i].result[6];
          if(min > data.resultElemList[i].result[6]) min = data.resultElemList[i].result[6];
        }
        double maxAbs = 0.0;
        double scale = 1.0;
        if(max.abs() > min.abs()){
          maxAbs = max.abs();
        }else{
          maxAbs = min.abs();
        }
        scale = (size.height/data.canvasData.scale/6) / maxAbs;
        List<List<double>> mList = List.generate(data.resultElemList.length, (_) => List<double>.filled(2, 0));
        for(int i = 0; i < data.resultElemList.length; i++){
          mList[i][0] = data.resultElemList[i].result[5]*scale;
          mList[i][1] = data.resultElemList[i].result[6]*scale;
        }

        for(int i = 0; i < data.resultElemList.length; i++){
          Offset left = Offset(data.resultElemList[i].nodeList[0]!.afterPos.dx, -mList[i][0]);
          Offset right = Offset(data.resultElemList[i].nodeList[1]!.afterPos.dx, -mList[i][1]);
          canvas.drawLine(data.canvasData.dToC(left), data.canvasData.dToC(right), paint);
          Offset topLeft = data.canvasData.dToC(Offset(data.resultElemList[i].nodeList[0]!.afterPos.dx, -mList[i][0]));
          Offset topRight = data.canvasData.dToC(Offset(data.resultElemList[i].nodeList[1]!.afterPos.dx, -mList[i][1]));
          Offset bottomRight = data.canvasData.dToC(Offset(data.resultElemList[i].nodeList[1]!.afterPos.dx, 0));
          paint.color = const Color.fromARGB(255, 222, 171, 167);
          Path path = Path();
          path.moveTo(topLeft.dx, topLeft.dy);
          path.lineTo(topRight.dx, topRight.dy);
          path.lineTo(topRight.dx, bottomRight.dy);
          path.lineTo(topLeft.dx, bottomRight.dy);
          path.close();
          canvas.drawPath(path, paint);
          paint.color = Colors.black;
          canvas.drawLine(topLeft, topRight, paint);
        }

        drawm(max, min, scale, true, canvas, size);
      }
      else{
        paint = Paint()
          ..color = const Color.fromARGB(255, 255, 13, 13)
          ..style = PaintingStyle.fill
          ..strokeWidth = 10;
        
        double max = data.resultNodeList[0].becPos.dy;
        double min = data.resultNodeList[0].becPos.dy;
        for(int i = 1; i < data.resultNodeList.length; i++){
          if(max < data.resultNodeList[i].becPos.dy) max = data.resultNodeList[i].becPos.dy;
          if(min > data.resultNodeList[i].becPos.dy) min = data.resultNodeList[i].becPos.dy;
        }
        double scale = 1.0;
        if(max.abs() > min.abs()){
          scale = (size.height/data.canvasData.scale/6) / max.abs();
        }else{
          scale = (size.height/data.canvasData.scale/6) / min.abs();
        }
        for(int i = 1; i < data.resultNodeList.length; i++){
          data.resultNodeList[i].afterPos = data.resultNodeList[i].pos + data.resultNodeList[i].becPos*scale;
        }

        for(int i = 0; i < data.resultElemList.length; i++){
          canvas.drawLine(data.canvasData.dToC(data.resultElemList[i].nodeList[0]!.afterPos), data.canvasData.dToC(data.resultElemList[i].nodeList[1]!.afterPos), paint);
        }


        List<Node> leftNodes = [];
        for(int i = 0; i < data.nodeList.length; i++){
          leftNodes.add(data.nodeList[i]);
        }
        leftNodes.sort((a, b) => a.pos.dx.compareTo(b.pos.dx));
        for(int i = 0; i < data.nodeList.length; i++){
          Offset cpos = data.canvasData.dToC(data.resultNodeList[i].afterPos);
          canvas.drawCircle(cpos, 7.5, paint);
          if(devTypeNum == 2){
            Painter().text(canvas, size.width, "v=${data.resultNodeList[i].result[0].toStringAsFixed(5)}", cpos, 20, Colors.black);
          }else{
            if(i == data.nodeList.length-1){
              Painter().text(canvas, size.width, "θ=${data.resultNodeList[i].result[2].toStringAsFixed(5)}", cpos, 20, Colors.black);
            }else if(i == 0){
              Painter().text(canvas, size.width, "θ=${data.resultNodeList[i].result[1].toStringAsFixed(5)}", cpos, 20, Colors.black);
            }else{
              if(leftNodes[i].constXYR[3]){
                Painter().text(canvas, size.width, 
                "θ1=${data.resultNodeList[i].result[1].toStringAsFixed(5)}\nθ2=${data.resultNodeList[i].result[2].toStringAsFixed(5)}", cpos, 20, Colors.black);
              }else{
                Painter().text(canvas, size.width, "θ=${data.resultNodeList[i].result[2].toStringAsFixed(5)}", cpos, 20, Colors.black);
              }
            }
          }
        }
      }

      // 辺
      paint = Paint()
        ..color = const Color.fromARGB(255, 86, 86, 86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;
      for(int i = 0; i < data.elemList.length; i++){
        if(data.elemList[i].nodeList[0] != null && data.elemList[i].nodeList[1] != null){
          canvas.drawLine(data.elemList[i].nodeList[0]!.canvasPos, elems[i].nodeList[1]!.canvasPos, paint);
        }
      }

      // 節点拘束
      paint = Paint()
        ..color = const Color.fromARGB(255, 0, 0, 0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for(int i = 0; i < data.nodeList.length; i++){
        paint.style = PaintingStyle.fill;
        if(data.nodeList[i].constXYR[0] && data.nodeList[i].constXYR[1] && data.nodeList[i].constXYR[2]){ // 壁
          if(data.nodeList[i].pos.dx < dataRect.center.dx){
            Offset cpos = data.nodeList[i].canvasPos;
            paint.color = const Color.fromARGB(255, 141, 141, 141);
            canvas.drawRect(Rect.fromLTRB(cpos.dx-50, size.height/2-100, cpos.dx, size.height/2+100), paint);
            paint.color = Colors.black;
            canvas.drawLine(Offset(cpos.dx, size.height/2-100), Offset(cpos.dx, size.height/2+100), paint);
          }
          else{
            Offset cpos = data.nodeList[i].canvasPos;
            paint.color = const Color.fromARGB(255, 141, 141, 141);
            canvas.drawRect(Rect.fromLTRB(cpos.dx, size.height/2-100, cpos.dx+50, size.height/2+100), paint);
            paint.color = Colors.black;
            canvas.drawLine(Offset(cpos.dx, size.height/2-100), Offset(cpos.dx, size.height/2+100), paint);
            break;
          }
        }
      }

      // 節点
      paint = Paint()
        ..strokeWidth = 2;

      for(int i = 0; i < data.nodeList.length; i++){
        paint.style = PaintingStyle.fill;
        if(data.nodeList[i].constXYR[3]){ // ヒンジ
          paint.color = Colors.white;
        }
        else{
          paint.color = const Color.fromARGB(255, 79, 79, 79);
        }
        canvas.drawCircle(data.nodeList[i].canvasPos, 7.5, paint);

        paint.style = PaintingStyle.stroke;
        paint.color = const Color.fromARGB(255, 50, 50, 50);
        canvas.drawCircle(data.nodeList[i].canvasPos, 7.5, paint);
      }

      // 節点番号
      for(int i = 0; i < data.nodeList.length; i++){
        Offset pos = data.nodeList[i].canvasPos;
        Painter().text(canvas, size.width, (i+1).toString(), Offset(pos.dx - 30, pos.dy - 30), 20, Colors.black);
      }

      
    }
  }

  // メモリ

  void drawm(double max, double min, double scale, bool reverse, Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    double maxAbs = max.abs() > min.abs() ? max.abs() * 2 : min.abs() * 2;

    double digitScale = 1.0;
    if(maxAbs > 10.0){
      while(maxAbs > 10.0){
        maxAbs /= 10.0;
        digitScale /= 10.0;
      }
    }else if(maxAbs < 1.0){
      while(maxAbs < 1.0){
        maxAbs *= 10.0;
        digitScale *= 10.0;
      }
    }

    double nextValue = 1.0;
    if(maxAbs < 1.25){
      maxAbs = 1.0;
      nextValue = 0.25;
    }else if(maxAbs < 1.5){
      maxAbs = 1.25;
      nextValue = 0.25;
    }else if(maxAbs < 2.0){
      maxAbs = 1.5;
      nextValue = 0.5;
    }else if(maxAbs < 5.0){
      maxAbs = maxAbs.floorToDouble();
      nextValue = 0.5;
    }else{
      maxAbs = maxAbs.floorToDouble();
      nextValue = 1.0;
    }

    maxAbs /= digitScale;
    nextValue /= digitScale;

    // 線を描く
    Offset top = data.canvasData.dToC(Offset(0, maxAbs * scale));
    Offset bottom = data.canvasData.dToC(Offset(0, -maxAbs * scale));
    canvas.drawLine(Offset(80, top.dy), Offset(80, bottom.dy), paint);

    for (double value = -maxAbs; value <= maxAbs; value += nextValue) {
      if (value.abs() <= maxAbs) {
        top = data.canvasData.dToC(Offset(0, value * scale));
        canvas.drawLine(Offset(70, top.dy), Offset(90, top.dy), paint);
        String label = "";
        if(maxAbs >= 10){
          label = reverse ? (-value).toStringAsFixed(0) : value.toStringAsFixed(0);
        }else if(maxAbs >= 0.1){
          label = reverse ? (-value).toStringAsFixed(2) : value.toStringAsFixed(2);
        }else{
          label = reverse ? (-value).toStringAsExponential(1) : value.toStringAsExponential(1);
        }
        Painter().text(canvas, size.width, label, Offset(100, top.dy - 15), 20, Colors.black);
      }
    }
  }

  
  @override
  bool shouldRepaint(covariant BeamPainter oldDelegate) {
    return false;
  }
}