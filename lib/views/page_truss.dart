import 'package:flutter/material.dart';
import 'package:kozo/components/decorations.dart';
import 'package:kozo/components/painter.dart';
import 'package:kozo/components/widgets.dart';
import 'package:kozo/models/canvas_data.dart';
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
  final CanvasData canvasData = CanvasData();
  static List<String> devTypeXYList = 
    ["X方向の正規応力","Y方向の正規応力"];
  int toolNum = 0, devTypeNum = 0;

  List<Node> nodeList = List.empty(growable: true); // 要素作成用
  Node? node; // 節点設定用
  Elem? elem; // 要素設定用 

  @override
  void initState() {
    super.initState();

    scaffoldKey = widget.scaffoldKey;
    data = Data(onDebug:(value){});
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      header: MyHeaderMenu(
        children:[
          // メニューボタン
          MyMenuIconButton(
            icon: Icons.menu, 
            onPressed: (){
              scaffoldKey.currentState!.openDrawer();
            },
          ),
          if(!data.isCalculation)...{
            // ツールメニュー
            MyMenuToggleButtons(
              icons: const [Icons.circle, Icons.square, Icons.circle_outlined, Icons.square_outlined], 
              value: toolNum, 
              onPressed: (value){
                setState(() {
                  toolNum = value;
                  nodeList = List.empty(growable: true);
                  node = null;
                  elem = null;
                });
              }
            )
          },
          const Expanded(child: SizedBox()),
          if(!data.isCalculation)...{
            // 解析開始ボタン
            MyMenuIconButton(
              icon: Icons.play_arrow,
              onPressed: (){
                setState(() {
                  data.calculationTruss();
                  devTypeNum = 0;
                  data.selectResult(devTypeNum);
                });
              },
            ),
          }else...{
            // 解析結果選択
            MyMenuDropdown(
              items: devTypeXYList,
              value: devTypeNum,
              onPressed: (value){
                devTypeNum = value;
                setState(() {
                  data.selectResult(value);
                });
              },
            ),
            // 再開ボタン
            MyMenuIconButton(
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
                  if(toolNum == 0){
                    data.addIntNode(canvasData.canvasPosToDataPos(position));
                  }else if(toolNum == 1){
                    Node? node = data.getIntNode(canvasData.canvasPosToDataPos(position));
                    if(node != null){
                      if(nodeList.isEmpty){
                        nodeList.add(node);
                      }else if(nodeList[0] != node){
                        nodeList.add(node);
                        data.addElem(nodeList);
                        nodeList = List.empty(growable: true);
                      }
                    }
                  }else if(toolNum == 2){
                    node = data.getIntNode(canvasData.canvasPosToDataPos(position));
                  }else if(toolNum == 3){
                    elem = data.getElem(canvasData.canvasPosToDataPos(position));
                    if(elem != null){
                      data.elemList.remove(elem);
                    }
                  }
                });
              }
            },
            painter: TrussPainter(data: data, canvasData: canvasData),
          ),

          if(toolNum == 2 && node != null && !data.isCalculation)...{
            NodeSet(
              node: node!, 
              endButtonName: "削除", 
              onUpdate: (){setState(() {
                setState(() {
                  data = data;
                });
              });},
              onEndButton: (){
                setState(() {
                  data.removeIntNode(node!);
                  node = null;
                });
              },
            ),
          }

        ],
      ),
    );
  }
}

class NodeSet extends StatelessWidget {
  const NodeSet({super.key, required this.node, required this.endButtonName, required this.onEndButton, required this.onUpdate});

  final Node node;
  final String endButtonName;
  final void Function() onUpdate, onEndButton;

  @override
  Widget build(BuildContext context) {
    return MyAlign(
      alignment: Alignment.bottomCenter,
      isIntrinsicWidth: true,
      isIntrinsicHeight: true,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(5),
        decoration: myBoxDecoration,
        child: Column(
          children: [
            Container(
              height: 25,
              alignment: Alignment.center,
              child: Row(
                children: [
                  Container(width: 75, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("拘束"),),
                  Container(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("x"),),
                  Container(width: 100, alignment: Alignment.centerLeft, 
                    child: Checkbox(
                      value: node.constXY[0],
                      onChanged: (value) {
                        node.constXY[0] = value!;
                        onUpdate();
                      },
                    )
                  ),
                  Container(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("y"),),
                  Container(width: 100, alignment: Alignment.centerLeft, child: Checkbox(
                    value: node.constXY[1],
                    onChanged: (value) {
                      node.constXY[1] = value!;
                      onUpdate();
                    },
                  )),
                ],
              )
            ),
            const SizedBox(height: 2.5,),
            Container(
              height: 25,
              alignment: Alignment.center,
              child: Row(
                children: [
                  Container(width: 75, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("強制変位"),),
                  Container(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("x"),),
                  SizedBox(width: 100, child: TextField(
                    controller: TextEditingController(text: node.loadXY[0].toString()),
                    inputFormatters: myInputFormattersNumber,
                    decoration: myInputDecoration,
                    onSubmitted: (value) {
                      if(double.tryParse(value) != null){
                        node.loadXY[0] = double.parse(value);
                        onUpdate();
                      }
                    },
                  )),
                  Container(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("y"),),
                  SizedBox(width: 100, child: TextField(
                    controller: TextEditingController(text: node.loadXY[1].toString()), 
                    inputFormatters: myInputFormattersNumber,
                    decoration: myInputDecoration,
                    onSubmitted: (value) {
                      if(double.tryParse(value) != null){
                        node.loadXY[1] = double.parse(value);
                        onUpdate();
                      }
                    },
                  )),
                ],
              )
            ),
            const SizedBox(height: 2.5,),
            SizedBox(
              width: double.infinity,
              height: 25,
              child: Row(
                children: [
                  const Expanded(
                    child: SizedBox(), 
                  ),
                  ElevatedButton(
                    onPressed: () {
                      onEndButton();
                    },
                    style: myButtonStyleBorder,
                    child: Text(endButtonName),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class TrussPainter extends CustomPainter {
  const TrussPainter({required this.data, required this.canvasData});

  final Data data;
  final CanvasData canvasData;

  @override
  void paint(Canvas canvas, Size size) {
    canvasData.setScale(size.width, size.height, -0.5, -0.5, 50.5, 25.5);

    Paint paint = Paint();

    // 線
    paint.color = const Color.fromARGB(30, 0, 0, 0);
    for(int x = 0; x < 51; x++){
      canvas.drawLine(canvasData.dataPosToCanvasPos(Offset(x.toDouble(), 0)), canvasData.dataPosToCanvasPos(Offset(x.toDouble(), 25)), paint);
    }
    for(int y = 0; y < 26; y++){
      canvas.drawLine(canvasData.dataPosToCanvasPos(Offset(0, y.toDouble())), canvasData.dataPosToCanvasPos(Offset(50, y.toDouble())), paint);
    }

    if(!data.isCalculation || data.resultList.isEmpty){

      // 節点
      paint.color = const Color.fromARGB(255, 0, 0, 0);
      if(data.nodeList.isNotEmpty){
        for(int i = 0; i < data.nodeList.length; i++){
          canvas.drawCircle(canvasData.dataPosToCanvasPos(data.nodeList[i].pos), 5, paint);
        }
      }

      // 節点拘束
      paint = Paint()
        ..color = const Color.fromARGB(255, 0, 0, 0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      if(data.nodeList.isNotEmpty){
        for(int i = 0; i < data.nodeList.length; i++){
          Offset pos = canvasData.dataPosToCanvasPos(data.nodeList[i].pos);
          if(data.nodeList[i].constXY[0]){
            canvas.drawLine(Offset(pos.dx-5, pos.dy-5), Offset(pos.dx-5, pos.dy+5), paint);
            canvas.drawLine(Offset(pos.dx+5, pos.dy-5), Offset(pos.dx+5, pos.dy+5), paint);
          }
          if(data.nodeList[i].constXY[1]){
            canvas.drawLine(Offset(pos.dx-5, pos.dy-5), Offset(pos.dx+5, pos.dy-5), paint);
            canvas.drawLine(Offset(pos.dx-5, pos.dy+5), Offset(pos.dx+5, pos.dy+5), paint);
          }
        }
      }

      // 節点強制変位
      paint = Paint()
        ..color = const Color.fromARGB(255, 0, 0, 0)
        ..strokeWidth = 2;
      
      if(data.nodeList.isNotEmpty){
        for(int i = 0; i < data.nodeList.length; i++){
          Offset pos = canvasData.dataPosToCanvasPos(data.nodeList[i].pos);
          if(data.nodeList[i].loadXY[0] != 0){
            if(data.nodeList[i].loadXY[0] > 0){
              Painter().arrow(Offset(pos.dx+5, pos.dy), Offset(pos.dx+20, pos.dy), paint, canvas);
            }else{
              Painter().arrow(Offset(pos.dx-5, pos.dy), Offset(pos.dx-20, pos.dy), paint, canvas);
            }
          }
          if(data.nodeList[i].loadXY[1] != 0){
            if(data.nodeList[i].loadXY[1] > 0){
              Painter().arrow(Offset(pos.dx, pos.dy-5), Offset(pos.dx, pos.dy-20), paint, canvas);
            }else{
              Painter().arrow(Offset(pos.dx, pos.dy+5), Offset(pos.dx, pos.dy+20), paint, canvas);
            }
          }
        }
      }

      // 辺
      paint = Paint()
        ..color = const Color.fromARGB(255, 49, 49, 49)
        ..style = PaintingStyle.stroke;

      if(data.elemList.isNotEmpty){
        for(int i = 0; i < data.elemList.length; i++){
          Painter().angleRectangle(canvas, canvasData.dataPosToCanvasPos(data.elemList[i].nodes[0].pos),
            canvasData.dataPosToCanvasPos(data.elemList[i].nodes[1].pos), size.height/20, const Color.fromARGB(255, 49, 49, 49), false);
        }
      }
    }
    else{
      // 面
      final result = data.getValue();
      double max = result.$1;
      double min = result.$2;

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

        Painter().angleRectangle(canvas, canvasData.dataPosToCanvasPos(data.elemList[i].nodes[0].afterPos),
        canvasData.dataPosToCanvasPos(data.elemList[i].nodes[1].afterPos), size.height/20, color, true);
      }

      // 辺
      paint = Paint()
        ..color = const Color.fromARGB(255, 49, 49, 49)
        ..style = PaintingStyle.stroke;

      for(int i = 0; i < data.elemList.length; i++){
        Painter().angleRectangle(canvas, canvasData.dataPosToCanvasPos(data.elemList[i].nodes[0].afterPos),
          canvasData.dataPosToCanvasPos(data.elemList[i].nodes[1].afterPos), size.height/20, const Color.fromARGB(255, 49, 49, 49), false);
      }

      // 節点
      paint = Paint()
        ..color = const Color.fromARGB(255, 0, 0, 0);

      for(int i = 0; i < data.nodeList.length; i++){
        canvas.drawCircle(canvasData.dataPosToCanvasPos(data.nodeList[i].afterPos), 5, paint);
      }

      // 虹色
      Painter().rainbowBand(canvas, Offset(size.width - 60, 50), Offset(size.width - 100, size.height - 50), 50);

      // 最大最小
      Painter().text(canvas, size.width, data.resultMax.toStringAsFixed(5), Offset(size.width - 55, 40), 16, Colors.black);
      Painter().text(canvas, size.width, data.resultMin.toStringAsFixed(5), Offset(size.width - 55, size.height - 60), 16, Colors.black);
    
      // 選択
      if(data.selectedNumber >= 0){
        if(data.elemList[data.selectedNumber].e > 0){
          Painter().text(canvas, size.width, data.resultList[data.selectedNumber].toStringAsFixed(5), canvasData.dataPosToCanvasPos(data.elemList[data.selectedNumber].nodes[0].afterPos), 16, Colors.black);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TrussPainter oldDelegate) {
    return false;
  }
}