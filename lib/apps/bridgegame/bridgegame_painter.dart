import 'package:flutter/material.dart';
import 'package:kozo/apps/bridgegame/bridgegame_data.dart';
import 'package:kozo/components/my_painter.dart';

class BridgegamePainter extends CustomPainter {
  const BridgegamePainter({required this.data});

  final BridgegameData data;

  @override
  void paint(Canvas canvas, Size size) {
    Rect dataRect = data.rect();
    data.updateCanvasPos(Rect.fromLTRB((size.width/10), (size.height/6), size.width-(size.width/10), size.height-(size.height/6)), 0);

    Paint paint = Paint();

    Rect canvasRect = data.canvasData.dToCRect(dataRect);
    // 絵
    _drawBackground(canvasRect, canvas);

    if(!data.isCalculation || data.resultList.isEmpty){
      _drawElem(false, canvas); // 要素
      _drawElemEdge(false, canvas); // 要素の辺

      // 矢印
      double arrowSize = canvasRect.width/70 / 5;

      if(data.powerType == 0){ // 集中荷重
        paint.color = const Color.fromARGB(255, 0, 0, 0);
        paint.style = PaintingStyle.fill;
        paint.strokeWidth = 3.0;
        for(int i = 34; i < 37; i++){
          Offset pos = data.nodeList[i].canvasPos;
          MyPainter.arrow(pos, Offset(pos.dx, pos.dy+data.canvasData.scale*1.5), arrowSize, const Color.fromARGB(255, 0, 63, 95), canvas);
        }
      }else if(data.powerType == 1){ // 分布荷重
        paint.color = const Color.fromARGB(255, 0, 63, 95);
        paint.style = PaintingStyle.fill;
        paint.strokeWidth = 3.0;
        for(int i = 2; i < 69; i += 3){
          Offset pos = data.nodeList[i].canvasPos;
          MyPainter.arrow(pos, Offset(pos.dx, pos.dy+data.canvasData.scale*1.5), arrowSize, const Color.fromARGB(255, 0, 63, 95), canvas);
        }
        Offset pos1 = data.nodeList[2].canvasPos;
        Offset pos2 = data.nodeList[68].canvasPos;
        canvas.drawLine(Offset(pos1.dx, pos1.dy+data.canvasData.scale*1.5), Offset(pos2.dx, pos2.dy+data.canvasData.scale*1.5), paint);
      }

      // 体積
      int elemLength = data.elemCount();
      Color color = Colors.black;
      if(elemLength > 1000){
        color = Colors.red;
      }
      MyPainter.text(canvas, const Offset(10, 10), "体積：$elemLength", 16, color, true, size.width, );
    }
    else{
      _drawElem(true, canvas); // 要素
      _drawElemEdge(true, canvas); // 要素の辺
    
      // 選択
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
      if(data.selectedNumber >= 0){
        if(data.elemList[data.selectedNumber].e > 0){
          MyPainter.text(canvas, data.elemList[data.selectedNumber].nodeList[0]!.canvasAfterPos, 
            MyPainter.doubleToString(data.resultList[data.selectedNumber], 3), 14, Colors.black, true, size.width);
        }
      }

      // 虹色
      if(size.width > size.height){
        Rect cRect = Rect.fromLTRB(size.width - 85, 50, size.width - 60, size.height - 50);
        if(cRect.height > 500){
          cRect = Rect.fromLTRB(cRect.left, size.height/2-250, cRect.right, size.height/2+250);
        }
        // 虹色
        MyPainter.rainbowBand(canvas, cRect, 50);

        // 最大最小
        MyPainter.text(canvas, Offset(cRect.left+5, cRect.top-20), 
          "大", 14, Colors.black, true, size.width);
        MyPainter.text(canvas, Offset(cRect.left+5, cRect.bottom+5), 
          "小", 14, Colors.black, true, size.width);
        
        // ラベル
        MyPainter.text(canvas, Offset(cRect.right+5, cRect.center.dy-40), "引張の力", 14, Colors.black, true, 14);
      }else{
        Rect cRect = Rect.fromLTRB(50, size.height - 75, size.width - 50, size.height - 50);
        if(cRect.width > 500){
          cRect = Rect.fromLTRB(size.width/2-250, cRect.top, size.width/2+250, cRect .bottom);
        }
        // 虹色
        MyPainter.rainbowBand(canvas, cRect, 50);

        // 最大最小
        MyPainter.text(canvas, Offset(cRect.right+5, cRect.top+3), 
          "大", 14, Colors.black, true, size.width);
        MyPainter.text(canvas, Offset(cRect.left-20, cRect.top+3), 
          "小", 14, Colors.black, true, size.width);
        
        // ラベル
        MyPainter.text(canvas, Offset(cRect.center.dx-20, cRect.bottom+5), "引張の力", 14, Colors.black, true, size.width);
      }

      // 点数
      MyPainter.text(canvas, const Offset(10, 10), "${data.resultPoint.toStringAsFixed(2)}点", 32, Colors.black, true, size.width, );

      // 体積
      MyPainter.text(canvas, const Offset(10, 50), "体積：${data.elemCount()}", 16, Colors.black, true, size.width, );
    }
  }

  // 背景
  void _drawBackground(Rect rect, Canvas canvas){
    Paint paint = Paint();

    // 絵
    double scale = data.canvasData.scale;
    paint.color = const Color.fromARGB(255, 0, 0, 0);
    var path = Path();
    path.moveTo(rect.left, rect.bottom);
    path.lineTo(rect.left+2*scale, rect.bottom);
    path.lineTo(rect.left+2*scale, rect.bottom+1*scale);
    path.lineTo(rect.left, rect.bottom+1*scale);
    path.close();
    path.moveTo(rect.right-2*scale, rect.bottom);
    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.right, rect.bottom+1*scale);
    path.lineTo(rect.right-2*scale, rect.bottom+1*scale);
    path.close();
    canvas.drawPath(path, paint);

    paint.color = const Color.fromARGB(255, 96, 205, 255);
    path = Path();
    path.moveTo(rect.left, rect.bottom+2*scale);
    path.lineTo(rect.right, rect.bottom+2*scale);
    path.lineTo(rect.right, rect.bottom+100*scale);
    path.lineTo(rect.left, rect.bottom+100*scale);
    path.close();
    canvas.drawPath(path, paint);

    paint.color = const Color.fromARGB(255, 103, 103, 103);
    path = Path();
    path.moveTo(rect.left-100*scale, rect.bottom+1*scale);
    path.lineTo(rect.left+4*scale, rect.bottom+1*scale);
    path.lineTo(rect.left+4*scale, rect.bottom+100*scale);
    path.lineTo(rect.left-100*scale, rect.bottom+100*scale);
    path.close();
    path.moveTo(rect.right-4*scale, rect.bottom+1*scale);
    path.lineTo(rect.right+100*scale, rect.bottom+1*scale);
    path.lineTo(rect.right+100*scale, rect.bottom+100*scale);
    path.lineTo(rect.right-4*scale, rect.bottom+100*scale);
    path.close();
    canvas.drawPath(path, paint);
  }

  // 要素の辺
  void _drawElemEdge(bool isAfter, Canvas canvas){
    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 132, 132, 132)
      ..style = PaintingStyle.stroke;

    if(data.elemList.isNotEmpty){
      for(int i = 0; i < data.elemList.length; i++){
        if((data.elemList[i].e > 0 && isAfter) || !isAfter){
          final path = Path();
          for(int j = 0; j < data.elemNode; j++){
            Offset pos;
            if(!isAfter){
              pos = data.elemList[i].canvasPosList[j];
            }else{
              pos = data.elemList[i].nodeList[j]!.canvasAfterPos;
            }

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
  }

  // 要素
  void _drawElem(bool isAfter, Canvas canvas){
    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 49, 49, 49);

    if(!isAfter){
      paint.color = const Color.fromARGB(255, 255, 0, 0);
    }

    for(int i = 0; i < data.elemList.length; i++){
      if(data.elemList[i].e > 0){
        if(isAfter && (data.resultMax != 0 || data.resultMin != 0)){
          paint.color = MyPainter.getColor((data.resultList[i] - data.resultMin) / (data.resultMax - data.resultMin) * 100);
        }

        final path = Path();
        for(int j = 0; j < data.elemNode; j++){
          Offset pos;
          if(!isAfter){
            pos = data.elemList[i].canvasPosList[j];
          }else{
            pos = data.elemList[i].nodeList[j]!.canvasAfterPos;
          }
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


  @override
  bool shouldRepaint(covariant BridgegamePainter oldDelegate) {
    return false;
  }
}