import 'package:flutter/material.dart';
import 'package:kozo/components/painter.dart';
import 'package:kozo/components/widgets.dart';
import 'package:kozo/models/canvas_data.dart';
import 'package:kozo/models/data.dart';

class PageGrid extends StatefulWidget {
  const PageGrid({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<PageGrid> createState() => _PageGridState();
}

class _PageGridState extends State<PageGrid> {
  late GlobalKey<ScaffoldState> scaffoldKey;
  late Data data;
  final CanvasData canvasData = CanvasData();
  static List<String> mathTpeList = ["集中荷重", "分布荷重", "自重"];
  static List<String> devTypeXYList = 
    ["X方向応力","Y方向応力","せん断応力","最大主応力","最小主応力","X方向ひずみ","y方向ひずみ","せん断ひずみ","なし"];
  int toolNum = 0, devTypeNum = 0;

  @override
  void initState() {
    super.initState();

    scaffoldKey = widget.scaffoldKey;
    data = Data(onDebug: (value){});
    data.elemNode = 4;
    int countX = 70;
    int countY = 25;
    for(int i = 0; i <= countY; i++){
      for(int j = 0; j <= countX; j++){
        Node node = Node();
        node.pos = Offset(j.toDouble(), i.toDouble());
        data.nodeList.add(node);
      }
    }
    for(int i = 0; i < countY; i++){
      for(int j = 0; j < countX; j++){
        Elem elem = Elem();
        elem.nodes = [data.nodeList[i*(countX+1)+j],data.nodeList[i*(countX+1)+j+1],data.nodeList[(i+1)*(countX+1)+j+1],data.nodeList[(i+1)*(countX+1)+j]];
        data.elemList.add(elem);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold (
      // ヘッダーメニュー
      header: MyHeader(
        children: [
          //メニューボタン
          MyIconButton(
            icon: Icons.menu, 
            onPressed: (){
              scaffoldKey.currentState!.openDrawer();
            },
          ),
          if(!data.isCalculation)...{
            // ツールメニュー
            MyIconToggleButtons(
              icons: const [Icons.edit, Icons.edit_outlined], 
              value: toolNum, 
              onPressed: (value){
                setState(() {
                  toolNum = value;
                });
              }
            ),
            // 荷重タイプ
            MyMenuDropdown(
              items: mathTpeList,
              value: data.powerType,
              onPressed: (value){
                setState(() {
                  data.powerType = value;
                });
              },
            ),
          },
          const Expanded(child: SizedBox()),
          if(!data.isCalculation)...{
            // 解析開始ボタン
            MyIconButton(
              icon: Icons.play_arrow,
              onPressed: (){
                setState(() {
                  data.calculationDes();
                  devTypeNum = 0;
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

      // メインビュー
      body: MyCustomPaint(
        onTap: (position) {
          if(data.isCalculation){
            setState(() {
              data.selectElem(canvasData.cToD(position));
              if(data.selectedNumber >= 0){
                data.selectedNumber = data.selectedNumber;
              }
            });
          }
        },
        onDrag: (position) {
          if(!data.isCalculation){
            setState(() {
              data.selectElem(canvasData.cToD(position));
              if(data.selectedNumber >= 0){
                if(toolNum == 0 && data.elemList[data.selectedNumber].e < 1){
                  data.elemList[data.selectedNumber].e = 1;
                }
                else if(toolNum == 1 && data.elemList[data.selectedNumber].e > 0){
                  data.elemList[data.selectedNumber].e = 0;
                }
              }
            });
          }
        },
        painter: GridPainter(data: data, canvasData: canvasData),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  const GridPainter({required this.data, required this.canvasData});

  final Data data;
  final CanvasData canvasData;

  @override
  void paint(Canvas canvas, Size size) {
    double nodeMinX = data.getNodeMinX();
    double nodeMinY = data.getNodeMinY();
    double nodeMaxX = data.getNodeMaxX();
    double nodeMaxY = data.getNodeMaxY();
    canvasData.setScale(125, 100, size.width-125, size.height-100, nodeMinX, nodeMinY, nodeMaxX, nodeMaxY);

    Paint paint = Paint();

    // 絵
    paint.color = const Color.fromARGB(255, 0, 0, 0);
    var path = Path();
    path.moveTo(canvasData.dToC(Offset(nodeMinX, nodeMinY)).dx, canvasData.dToC(Offset(nodeMinX, nodeMinY)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMinX+2, nodeMinY)).dx, canvasData.dToC(Offset(nodeMinX+2, nodeMinY)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMinX+2, nodeMinY-1)).dx, canvasData.dToC(Offset(nodeMinX+2, nodeMinY-1)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMinX, nodeMinY-1)).dx, canvasData.dToC(Offset(nodeMinX, nodeMinY-1)).dy);
    path.close();
    path.moveTo(canvasData.dToC(Offset(nodeMaxX-2, nodeMinY)).dx, canvasData.dToC(Offset(nodeMaxX-2, nodeMinY)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMaxX, nodeMinY)).dx, canvasData.dToC(Offset(nodeMaxX, nodeMinY)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMaxX, nodeMinY-1)).dx, canvasData.dToC(Offset(nodeMaxX, nodeMinY-1)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMaxX-2, nodeMinY-1)).dx, canvasData.dToC(Offset(nodeMaxX-2, nodeMinY-1)).dy);
    path.close();
    canvas.drawPath(path, paint);

    paint.color = const Color.fromARGB(255, 96, 205, 255);
    path = Path();
    path.moveTo(canvasData.dToC(Offset(nodeMinX, nodeMinY-2)).dx, canvasData.dToC(Offset(nodeMinX, nodeMinY-2)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMaxX, nodeMinY-2)).dx, canvasData.dToC(Offset(nodeMaxX, nodeMinY-2)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMaxX, nodeMinY-50)).dx, canvasData.dToC(Offset(nodeMaxX, nodeMinY-50)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMinX, nodeMinY-50)).dx, canvasData.dToC(Offset(nodeMinX, nodeMinY-50)).dy);
    path.close();
    canvas.drawPath(path, paint);

    paint.color = const Color.fromARGB(255, 103, 103, 103);
    path = Path();
    path.moveTo(canvasData.dToC(Offset(nodeMinX-50, nodeMinY-1)).dx, canvasData.dToC(Offset(nodeMinX-50, nodeMinY-1)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMinX+4, nodeMinY-1)).dx, canvasData.dToC(Offset(nodeMinX+4, nodeMinY-1)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMinX+4, nodeMinY-50)).dx, canvasData.dToC(Offset(nodeMinX+4, nodeMinY-50)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMinX-50, nodeMinY-50)).dx, canvasData.dToC(Offset(nodeMinX-50, nodeMinY-50)).dy);
    path.close();
    path.moveTo(canvasData.dToC(Offset(nodeMaxX-4, nodeMinY-1)).dx, canvasData.dToC(Offset(nodeMaxX-4, nodeMinY-1)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMaxX+50, nodeMinY-1)).dx, canvasData.dToC(Offset(nodeMaxX+50, nodeMinY-1)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMaxX+50, nodeMinY-50)).dx, canvasData.dToC(Offset(nodeMaxX+50, nodeMinY-50)).dy);
    path.lineTo(canvasData.dToC(Offset(nodeMaxX-4, nodeMinY-50)).dx, canvasData.dToC(Offset(nodeMaxX-4, nodeMinY-50)).dy);
    path.close();
    canvas.drawPath(path, paint);

    if(!data.isCalculation || data.resultList.isEmpty){
      // 面
      paint = Paint()
        ..color = const Color.fromARGB(255, 255, 0, 0);

      if(data.elemList.isNotEmpty){
        for(int i = 0; i < data.elemList.length; i++){
          if(data.elemList[i].e > 0){
            final path = Path();
            for(int j = 0; j < data.elemNode; j++){
              if(j == 0){
                Offset pos = canvasData.dToC(data.elemList[i].nodes[j]!.pos);
                path.moveTo(pos.dx, pos.dy);
              }else{
                Offset pos = canvasData.dToC(data.elemList[i].nodes[j]!.pos);
                path.lineTo(pos.dx, pos.dy);
              }
            }
            path.close();
            canvas.drawPath(path, paint);
          }
        }
      }

      // 辺
      paint = Paint()
        ..color = const Color.fromARGB(255, 132, 132, 132)
        ..style = PaintingStyle.stroke;

      if(data.elemList.isNotEmpty){
        for(int i = 0; i < data.elemList.length; i++){
          final path = Path();
          for(int j = 0; j < data.elemNode; j++){
            if(j == 0){
              Offset pos = canvasData.dToC(data.elemList[i].nodes[j]!.pos);
              path.moveTo(pos.dx, pos.dy);
            }else{
              Offset pos = canvasData.dToC(data.elemList[i].nodes[j]!.pos);
              path.lineTo(pos.dx, pos.dy);
            }
          }
          path.close();
          canvas.drawPath(path, paint);
        }
      }

      // 矢印
      if(data.powerType == 0){ // 集中荷重
        paint.color = const Color.fromARGB(255, 0, 0, 0);
        paint.style = PaintingStyle.fill;
        paint.strokeWidth = 3.0;
        for(int i = 34; i < 37; i++){
          Offset pos = data.nodeList[i].pos;
          Painter().arrow(canvasData.dToC(pos), canvasData.dToC(Offset(pos.dx, pos.dy-1.5)), paint, canvas);
        }
      }else if(data.powerType == 1){ // 分布荷重
        paint.color = const Color.fromARGB(255, 0, 0, 0);
        paint.style = PaintingStyle.fill;
        paint.strokeWidth = 3.0;
        for(int i = 2; i < 69; i += 3){
          Offset pos = data.nodeList[i].pos;
          Painter().arrow(canvasData.dToC(pos), canvasData.dToC(Offset(pos.dx, pos.dy-1.5)), paint, canvas);
        }
        Offset pos1 = data.nodeList[2].pos;
        Offset pos2 = data.nodeList[68].pos;
        canvas.drawLine(canvasData.dToC(Offset(pos1.dx, pos1.dy-1.5)), canvasData.dToC(Offset(pos2.dx, pos2.dy-1.5)), paint);
      }
    }
    else{
      // 面
      paint = Paint()
        ..color = const Color.fromARGB(255, 49, 49, 49);

      for(int i = 0; i < data.elemList.length; i++){
        if(data.elemList[i].e > 0){
          if(data.resultMax != 0 || data.resultMin != 0){
            paint.color = Painter().getColor((data.resultList[i] - data.resultMin) / (data.resultMax - data.resultMin) * 100);
          }

          final path = Path();
          for(int j = 0; j < data.elemNode; j++){
            if(j == 0){
              Offset pos = canvasData.dToC(data.elemList[i].nodes[j]!.afterPos());
              path.moveTo(pos.dx, pos.dy);
            }else{
              Offset pos = canvasData.dToC(data.elemList[i].nodes[j]!.afterPos());
              path.lineTo(pos.dx, pos.dy);
            }
          }
          path.close();
          canvas.drawPath(path, paint);
        }
      }

      // 辺
      paint = Paint()
        ..color = const Color.fromARGB(255, 49, 49, 49)
        ..style = PaintingStyle.stroke;

      if(data.elemList.isNotEmpty){
        for(int i = 0; i < data.elemList.length; i++){
          if(data.elemList[i].e > 0){
            final path = Path();
            for(int j = 0; j < data.elemNode; j++){
              if(j == 0){
                Offset pos = canvasData.dToC(data.elemList[i].nodes[j]!.afterPos());
                path.moveTo(pos.dx, pos.dy);
              }else{
                Offset pos = canvasData.dToC(data.elemList[i].nodes[j]!.afterPos());
                path.lineTo(pos.dx, pos.dy);
              }
            }
            path.close();
            canvas.drawPath(path, paint);
          }
        }
      }

      // 虹色
      Painter().rainbowBand(canvas, Offset(size.width - 80, 50), Offset(size.width - 120, size.height - 50), 50);

      // 最大最小
      Painter().text(canvas, size.width, data.resultMax.toStringAsFixed(5), Offset(size.width - 75, 40), 16, Colors.black);
      Painter().text(canvas, size.width, data.resultMin.toStringAsFixed(5), Offset(size.width - 75, size.height - 60), 16, Colors.black);
    
      // 選択
      if(data.selectedNumber >= 0){
        if(data.elemList[data.selectedNumber].e > 0){
          Painter().text(canvas, size.width, data.resultList[data.selectedNumber].toStringAsFixed(5), canvasData.dToC(data.elemList[data.selectedNumber].nodes[0]!.afterPos()), 16, Colors.black);
        }
      }
      paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      if(data.selectedNumber >= 0){
        if(data.elemList[data.selectedNumber].e > 0){
          final path = Path();
          for(int j = 0; j < data.elemNode; j++){
            if(j == 0){
              Offset pos = canvasData.dToC(data.elemList[data.selectedNumber].nodes[j]!.afterPos());
              path.moveTo(pos.dx, pos.dy);
            }else{
              Offset pos = canvasData.dToC(data.elemList[data.selectedNumber].nodes[j]!.afterPos());
              path.lineTo(pos.dx, pos.dy);
            }
          }
          path.close();
          canvas.drawPath(path, paint);
        }
      }
    }

    // 最大最小
    int count = 0;
    for(int i = 0; i < data.elemList.length; i++){
      if(data.elemList[i].e > 0){
        count ++;
      }
    }
    Painter().text(canvas, size.width, "体積：$count", const Offset(10, 10), 16, Colors.black);
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return false;
  }
}
