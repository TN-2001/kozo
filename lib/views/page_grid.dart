import 'package:flutter/material.dart';
import 'package:kozo/components/painter.dart';
import 'package:kozo/components/widgets.dart';
import 'package:kozo/models/data.dart';

class PageGrid extends StatefulWidget {
  const PageGrid({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<PageGrid> createState() => _PageGridState();
}

class _PageGridState extends State<PageGrid> {
  late GlobalKey<ScaffoldState> scaffoldKey; // メニュー用キー
  late Data data; // データ
  static List<String> mathTpeList = ["中央荷重", "分布荷重", "自重"];
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
        elem.nodeList = [data.nodeList[i*(countX+1)+j],data.nodeList[i*(countX+1)+j+1],data.nodeList[(i+1)*(countX+1)+j+1],data.nodeList[(i+1)*(countX+1)+j]];
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
                  data.calculation(0);
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
        painter: GridPainter(data: data),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  const GridPainter({required this.data});

  final Data data;

  @override
  void paint(Canvas canvas, Size size) {
    Rect dataRect = data.rect();
    data.updateCanvasPos(Rect.fromLTRB(125, 100, size.width-125, size.height-100), 0);

    Paint paint = Paint();

    // 絵
    Rect canvasRect = data.canvasData.dToCRect(dataRect);
    double scale = data.canvasData.scale;
    paint.color = const Color.fromARGB(255, 0, 0, 0);
    var path = Path();
    path.moveTo(canvasRect.left, canvasRect.bottom);
    path.lineTo(canvasRect.left+2*scale, canvasRect.bottom);
    path.lineTo(canvasRect.left+2*scale, canvasRect.bottom+1*scale);
    path.lineTo(canvasRect.left, canvasRect.bottom+1*scale);
    path.close();
    path.moveTo(canvasRect.right-2*scale, canvasRect.bottom);
    path.lineTo(canvasRect.right, canvasRect.bottom);
    path.lineTo(canvasRect.right, canvasRect.bottom+1*scale);
    path.lineTo(canvasRect.right-2*scale, canvasRect.bottom+1*scale);
    path.close();
    canvas.drawPath(path, paint);

    paint.color = const Color.fromARGB(255, 96, 205, 255);
    path = Path();
    path.moveTo(canvasRect.left, canvasRect.bottom+2*scale);
    path.lineTo(canvasRect.right, canvasRect.bottom+2*scale);
    path.lineTo(canvasRect.right, canvasRect.bottom+100*scale);
    path.lineTo(canvasRect.left, canvasRect.bottom+100*scale);
    path.close();
    canvas.drawPath(path, paint);

    paint.color = const Color.fromARGB(255, 103, 103, 103);
    path = Path();
    path.moveTo(canvasRect.left-100*scale, canvasRect.bottom+1*scale);
    path.lineTo(canvasRect.left+4*scale, canvasRect.bottom+1*scale);
    path.lineTo(canvasRect.left+4*scale, canvasRect.bottom+100*scale);
    path.lineTo(canvasRect.left-100*scale, canvasRect.bottom+100*scale);
    path.close();
    path.moveTo(canvasRect.right-4*scale, canvasRect.bottom+1*scale);
    path.lineTo(canvasRect.right+100*scale, canvasRect.bottom+1*scale);
    path.lineTo(canvasRect.right+100*scale, canvasRect.bottom+100*scale);
    path.lineTo(canvasRect.right-4*scale, canvasRect.bottom+100*scale);
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
              Offset pos = data.elemList[i].canvasPosList[j];
              if(j == 0){
                path.moveTo(pos.dx, pos.dy);
              }else{
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
            Offset pos = data.elemList[i].canvasPosList[j];
            if(j == 0){
              path.moveTo(pos.dx, pos.dy);
            }else{
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
          Offset pos = data.nodeList[i].canvasPos;
          Painter().arrow(pos, Offset(pos.dx, pos.dy+data.canvasData.scale*1.5), 3, canvas);
        }
      }else if(data.powerType == 1){ // 分布荷重
        paint.color = const Color.fromARGB(255, 0, 0, 0);
        paint.style = PaintingStyle.fill;
        paint.strokeWidth = 3.0;
        for(int i = 2; i < 69; i += 3){
          Offset pos = data.nodeList[i].canvasPos;
          Painter().arrow(pos, Offset(pos.dx, pos.dy+data.canvasData.scale*1.5), 3, canvas);
        }
        Offset pos1 = data.nodeList[2].canvasPos;
        Offset pos2 = data.nodeList[68].canvasPos;
        canvas.drawLine(Offset(pos1.dx, pos1.dy+data.canvasData.scale*1.5), Offset(pos2.dx, pos2.dy+data.canvasData.scale*1.5), paint);
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
            Offset pos = data.elemList[i].nodeList[j]!.canvasAfterPos;
            if(j == 0){
              path.moveTo(pos.dx, pos.dy);
            }else{
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
              Offset pos = data.elemList[i].nodeList[j]!.canvasAfterPos;
              if(j == 0){
                path.moveTo(pos.dx, pos.dy);
              }else{
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
          Painter().text(canvas, size.width, data.resultList[data.selectedNumber].toStringAsFixed(5), data.elemList[data.selectedNumber].nodeList[0]!.canvasAfterPos, 16, Colors.black);
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
            Offset pos = data.elemList[data.selectedNumber].nodeList[j]!.canvasAfterPos;
            if(j == 0){
              path.moveTo(pos.dx, pos.dy);
            }else{
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
