import 'package:flutter/material.dart';
import 'package:kozo/apps/bridge/bridge_data.dart';
import 'package:kozo/components/my_painter.dart';

class BridgePainter extends CustomPainter {
  const BridgePainter({required this.data});

  final BridgeData data;

  @override
  void paint(Canvas canvas, Size size) {
    Rect dataRect = data.rect();
    data.updateCanvasPos(Rect.fromLTRB((size.width/10), (size.height/10), size.width-(size.width/10), size.height-(size.height/10)), 0);

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
          MyPainter.arrow(pos, Offset(pos.dx, pos.dy+data.canvasData.scale*1.5), 3, const Color.fromARGB(255, 0, 63, 95), canvas);
        }
      }else if(data.powerType == 1){ // 分布荷重
        paint.color = const Color.fromARGB(255, 0, 63, 95);
        paint.style = PaintingStyle.fill;
        paint.strokeWidth = 3.0;
        for(int i = 2; i < 69; i += 3){
          Offset pos = data.nodeList[i].canvasPos;
          MyPainter.arrow(pos, Offset(pos.dx, pos.dy+data.canvasData.scale*1.5), 3, const Color.fromARGB(255, 0, 63, 95), canvas);
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
            paint.color = MyPainter.getColor((data.resultList[i] - data.resultMin) / (data.resultMax - data.resultMin) * 100);
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
      if(size.width > size.height){
        Rect cRect = Rect.fromLTRB(size.width - 85, 50, size.width - 60, size.height - 50);
        if(cRect.height > 500){
          cRect = Rect.fromLTRB(cRect.left, size.height/2-250, cRect.right, size.height/2+250);
        }
        // 虹色
        MyPainter.rainbowBand(canvas, cRect, 50);

        // 最大最小
        MyPainter.text(canvas, Offset(cRect.right+5, cRect.top-10), 
          MyPainter.doubleToString(data.resultMax, 3), 14, Colors.black, false, size.width);
        MyPainter.text(canvas, Offset(cRect.right+5, cRect.bottom-10), 
          MyPainter.doubleToString(data.resultMin, 3), 14, Colors.black, false, size.width);
      }else{
        Rect cRect = Rect.fromLTRB(50, size.height - 75, size.width - 50, size.height - 50);
        if(cRect.width > 500){
          cRect = Rect.fromLTRB(size.width/2-250, cRect.top, size.width/2+250, cRect .bottom);
        }
        // 虹色
        MyPainter.rainbowBand(canvas, cRect, 50);

        // 最大最小
        MyPainter.text(canvas, Offset(cRect.right-20, cRect.bottom), 
          MyPainter.doubleToString(data.resultMax, 3), 14, Colors.black, false, size.width);
        MyPainter.text(canvas, Offset(cRect.left-20, cRect.bottom), 
          MyPainter.doubleToString(data.resultMin, 3), 14, Colors.black, false, size.width);
      }

    
      // 選択
      if(data.selectedNumber >= 0){
        if(data.elemList[data.selectedNumber].e > 0){
          MyPainter.text(canvas, data.elemList[data.selectedNumber].nodeList[0]!.canvasAfterPos, 
            MyPainter.doubleToString(data.resultList[data.selectedNumber], 3), 14, Colors.black, true, size.width);
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
    MyPainter.text(canvas, const Offset(10, 10), "体積：$count", 16, Colors.black, false, size.width, );
  }

  @override
  bool shouldRepaint(covariant BridgePainter oldDelegate) {
    return false;
  }
}