import 'package:flutter/material.dart';
import 'package:kozo/components/painter.dart';
import 'package:kozo/models/data.dart';

class MyPainter extends CustomPainter {
  const MyPainter({required this.data, required this.isUpdate});

  final Data data;
  final bool isUpdate;

  @override
  void paint(Canvas canvas, Size size) {
    List<Node> canvasNodeList = data.getCanvasNodeList(size.width, size.height);

    Paint paint = Paint();

    if(!data.isCalculation){
    // 辺
    paint = Paint()
      ..color = const Color.fromARGB(255, 49, 49, 49)
      ..style = PaintingStyle.stroke;

    if(data.elemList.isNotEmpty){
      for(int i = 0; i < data.elemList.length; i++){
        if(data.elemNode == 2){
          Painter().angleRectangle(canvas, canvasNodeList[data.elemList[i].nodeList[0]].pos, 
            canvasNodeList[data.elemList[i].nodeList[1]].pos, size.height/20, const Color.fromARGB(255, 49, 49, 49), false);
        }
        else{
          for(int j = 0; j < data.elemNode; j++){
            if(j == 0){
              canvas.drawLine(canvasNodeList[data.elemList[i].nodeList[j]].pos, 
                canvasNodeList[data.elemList[i].nodeList[data.elemNode-1]].pos, paint);
            }
            else{
              canvas.drawLine(canvasNodeList[data.elemList[i].nodeList[j]].pos, 
                canvasNodeList[data.elemList[i].nodeList[j-1]].pos, paint);
            }
          }
        }
      }
    }

    // 節点
    paint = Paint()
      ..color = const Color.fromARGB(255, 50, 50, 50);

    if(data.nodeList.isNotEmpty){
      for(int i = 0; i < data.nodeList.length; i++){
        canvas.drawCircle(canvasNodeList[i].pos, 5, paint);
      }
    }

    // 節点拘束
    paint = Paint()
      ..color = const Color.fromARGB(255, 0, 0, 0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if(data.nodeList.isNotEmpty){
      for(int i = 0; i < data.nodeList.length; i++){
        Offset pos = canvasNodeList[i].pos;
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
      ..strokeWidth = 4;
    
    if(data.nodeList.isNotEmpty){
      for(int i = 0; i < data.nodeList.length; i++){
        Offset pos = canvasNodeList[i].pos;
        if(data.nodeList[i].loadXY[0] != 0){
          if(data.nodeList[i].loadXY[0] > 0){
            Painter().arrow(Offset(pos.dx+5, pos.dy), Offset(pos.dx+30, pos.dy), paint, canvas);
          }else{
            Painter().arrow(Offset(pos.dx-5, pos.dy), Offset(pos.dx-30, pos.dy), paint, canvas);
          }
        }
        if(data.nodeList[i].loadXY[1] != 0){
          if(data.nodeList[i].loadXY[1] > 0){
            Painter().arrow(Offset(pos.dx, pos.dy-5), Offset(pos.dx, pos.dy-30), paint, canvas);
          }else{
            Painter().arrow(Offset(pos.dx, pos.dy+5), Offset(pos.dx, pos.dy+30), paint, canvas);
          }
        }
      }
    }

    // 節点番号
    if(data.nodeList.isNotEmpty){
      for(int i = 0; i < data.nodeList.length; i++){
        Painter().text(canvas, size.width, (i+1).toString(), Offset(canvasNodeList[i].pos.dx - 30, canvasNodeList[i].pos.dy - 30), 20, Colors.black);
      }
    }
    }
    else{

    final result = data.getValue();
    double max = result.$1;
    double min = result.$2;

    // 面
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

      if(data.elemNode == 2){
        Painter().angleRectangle(canvas, canvasNodeList[data.elemList[i].nodeList[0]].afterPos,
          canvasNodeList[data.elemList[i].nodeList[1]].afterPos, size.height/20, color, true);
      }
      else{
        List<Offset> offsetList = List.empty(growable: true);
        for(int j = 0; j < data.elemNode; j++){
          offsetList.add(Offset(canvasNodeList[data.elemList[i].nodeList[j]].afterPos.dx, canvasNodeList[data.elemList[i].nodeList[j]].afterPos.dy));
        }
        Painter().polygon(canvas, offsetList, color, true);
      }
    }

    // 辺
    paint = Paint()
      ..color = const Color.fromARGB(255, 49, 49, 49)
      ..style = PaintingStyle.stroke;

    for(int i = 0; i < data.elemList.length; i++){
      if(data.elemNode == 2){
        Painter().angleRectangle(canvas, canvasNodeList[data.elemList[i].nodeList[0]].afterPos,
          canvasNodeList[data.elemList[i].nodeList[1]].afterPos, size.height/20, const Color.fromARGB(255, 49, 49, 49), false);
      }
      else{
        for(int j = 0; j < data.elemNode; j++){
          if(j == 0){
            canvas.drawLine(canvasNodeList[data.elemList[i].nodeList[j]].afterPos,
              canvasNodeList[data.elemList[i].nodeList[data.elemNode-1]].afterPos, paint);
          }
          else{
            canvas.drawLine(canvasNodeList[data.elemList[i].nodeList[j]].afterPos,
              canvasNodeList[data.elemList[i].nodeList[j-1]].afterPos, paint);
          }
        }
      }
    }

    // 節点
    paint = Paint()
      ..color = const Color.fromARGB(255, 0, 0, 0);

    for(int i = 0; i < data.nodeList.length; i++){
      canvas.drawCircle(canvasNodeList[i].afterPos, 5, paint);
    }

    // 虹色
    Painter().rainbowBand(canvas, Offset(size.width - 60, 50), Offset(size.width - 100, size.height - 50), 50);

    // 最大最小
    Painter().text(canvas, size.width, max.toStringAsFixed(2), Offset(size.width - 55, 40), 16, Colors.black);
    Painter().text(canvas, size.width, min.toStringAsFixed(2), Offset(size.width - 55, size.height - 60), 16, Colors.black);

    // 値
    for(int i = 0; i < data.elemList.length; i++){
      if(data.elemNode == 2){
        Offset pos1 = canvasNodeList[data.elemList[i].nodeList[0]].afterPos;
        Offset pos2 = canvasNodeList[data.elemList[i].nodeList[1]].afterPos;
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
        Painter().text(canvas, size.width, text, canvasNodeList[i].pos, 16, Colors.black);
      }
    }
    }
  }
  
  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return false;
  }
}

