import 'package:flutter/material.dart';
import 'package:kozo/apps/truss/truss_data.dart';
import 'package:kozo/components/my_painter.dart';


class TrussPainter extends CustomPainter {
  const TrussPainter({required this.data});

  final TrussData data;

  @override
  void paint(Canvas canvas, Size size) {
    Rect dataRect = data.rect();
    // キャンバスの広さ
    double width = size.width-(size.width/2);
    double heigh = size.height-(size.height/2);
    if(size.width - width < 200){
      width = size.width - 200;
    }
    if(size.height - heigh < 200){
      heigh = size.height - 200;
    }
    Rect rect = Rect.fromLTRB((size.width-width)/2, (size.height-heigh)/2, size.width-(size.width-width)/2, size.height - (size.height-heigh)/2);

    // 要素の太さ
    double elemWidth = rect.width/50;
    if(elemWidth > 15) {
      elemWidth = 15;
    } else if(elemWidth < 6.5) {
      elemWidth = 6.5;
    }
    // 節点の半径
    double nodeWidth = elemWidth*0.6;

    data.updateCanvasPos(rect, nodeWidth, elemWidth);

    List<Node> nodes = data.allNodeList();
    List<Elem> elems = data.allElemList();

    if(!data.isCalculation){
      _drawElem(elems, true, false, elemWidth, canvas); // 要素
      _drawConst(nodes, dataRect, rect, canvas); // 節点拘束拘束
      _drawPower(nodes, dataRect, canvas); // 接点荷重
      _drawNode(nodes, true, false, nodeWidth, canvas); // 節点
      _drawNodeNumber(nodes, true, canvas); // 節点番号
    }
    else{
      _drawElem(data.elemList, false, true, elemWidth, canvas); // 要素
      _drawNode(data.nodeList, false, true, nodeWidth, canvas); // 節点

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

      // 値
      for(int i = 0; i < data.elemList.length; i++){
        if(data.elemNode == 2){
          Offset pos1 = data.elemList[i].nodeList[0]!.canvasAfterPos;
          Offset pos2 = data.elemList[i].nodeList[1]!.canvasAfterPos;
          MyPainter.text(canvas, Offset((pos1.dx+pos2.dx)/2-20, (pos1.dy+pos2.dy)/2-10),
            MyPainter.doubleToString(data.resultList[i], 3), 14, Colors.black, true, size.width);
        }
      }

      // 変位
      for(int i = 0; i < data.nodeList.length; i++){
        if(data.nodeList[i].loadXY[0] != 0 || data.nodeList[i].loadXY[1] != 0){
          String text = "変位\nx：${MyPainter.doubleToString(data.nodeList[i].becPos.dx, 3)}";
          text += "\ny：${MyPainter.doubleToString(data.nodeList[i].becPos.dy, 3)}";
          MyPainter.text(canvas, data.nodeList[i].canvasAfterPos, text, 16, Colors.black, true, size.width);
        }
      }
    }
  }


  // 節点
  void _drawNode(List<Node> nodes, bool isSelect, bool isAfter, double width, Canvas canvas) {
    // バグ対策
    if(nodes.isEmpty){
      return;
    }

    Paint paint = Paint()
      ..strokeWidth = 2;

    for(int i = 0; i < nodes.length; i++){
      Offset pos = nodes[i].canvasPos;
      if(isAfter){
        pos = nodes[i].canvasAfterPos;
      }

      // 丸を描画
      paint.style = PaintingStyle.fill;
      paint.color = const Color.fromARGB(255, 234, 234, 234);
      canvas.drawCircle(pos, width, paint);

      // 丸枠を描画
      paint.style = PaintingStyle.stroke;
      if(nodes[i].isSelect && isSelect){
        paint.color = Colors.red;
      }else{
        paint.color = const Color.fromARGB(255, 0, 0, 0);
      }
      canvas.drawCircle(pos, width, paint);
    }
  }

  // 節点番号
  void _drawNodeNumber(List<Node> nodes, bool isSelect, Canvas canvas) {
    // バグ対策
    if(nodes.isEmpty){
      return;
    }

    for(int i = 0; i < nodes.length; i++){
      Offset pos = nodes[i].canvasPos;
      Color color = Colors.red;
      if(nodes[i].isSelect && isSelect){
        color = Colors.red;
      }else{
        color = Colors.black;
      }
      MyPainter.text(canvas, Offset(pos.dx - 30, pos.dy - 30), (i+1).toString(), 20, color, true, 100);
    }
  }

  // 拘束
  void _drawConst(List<Node> nodes, Rect dataRect, Rect rect, Canvas canvas) {
    // バグ対策
    if(nodes.isEmpty){
      return;
    }

    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 0, 0, 0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for(int i = 0; i < nodes.length; i++){
      Offset pos = nodes[i].canvasPos;
      if(nodes[i].constXY[0]){
        if(pos.dx > rect.center.dx){
          canvas.drawCircle(Offset(pos.dx+20, pos.dy), 7.5, paint);
          canvas.drawLine(Offset(pos.dx+30, pos.dy-15), Offset(pos.dx+30, pos.dy+15), paint);
        }else{
          canvas.drawCircle(Offset(pos.dx-20, pos.dy), 7.5, paint);
          canvas.drawLine(Offset(pos.dx-30, pos.dy-15), Offset(pos.dx-30, pos.dy+15), paint);
        }
      }
      if(nodes[i].constXY[1]){
        if(pos.dy >= rect.center.dy){
          canvas.drawCircle(Offset(pos.dx, pos.dy+20), 7.5, paint);
          canvas.drawLine(Offset(pos.dx-15, pos.dy+30), Offset(pos.dx+15, pos.dy+30), paint);
        }else{
          canvas.drawCircle(Offset(pos.dx, pos.dy-20), 7.5, paint);
          canvas.drawLine(Offset(pos.dx-15, pos.dy-30), Offset(pos.dx+15, pos.dy-30), paint);
        }
      }
    }
  }

  // 荷重
  void _drawPower(List<Node> nodes, Rect dataRect, Canvas canvas) {  
    // バグ対策
    if(nodes.isEmpty){
      return;
    }
  
    for(int i = 0; i < nodes.length; i++){
      Offset pos = nodes[i].canvasPos;
      if(nodes[i].loadXY[0] != 0){
        if(nodes[i].loadXY[0] < 0){
          MyPainter.arrow(Offset(pos.dx-5, pos.dy), Offset(pos.dx-50, pos.dy), 2.5, const Color.fromARGB(255, 0, 63, 95), canvas);
        }else{
          MyPainter.arrow(Offset(pos.dx+5, pos.dy), Offset(pos.dx+50, pos.dy), 2.5, const Color.fromARGB(255, 0, 63, 95), canvas);
        }
      }
      if(nodes[i].loadXY[1] != 0){
        if(nodes[i].loadXY[1] > 0){
          MyPainter.arrow(Offset(pos.dx, pos.dy-5), Offset(pos.dx, pos.dy-50), 2.5, const Color.fromARGB(255, 0, 63, 95), canvas);
        }else{
          MyPainter.arrow(Offset(pos.dx, pos.dy+5), Offset(pos.dx, pos.dy+50), 2.5, const Color.fromARGB(255, 0, 63, 95), canvas);
        }
      }
    }
  }

  // 要素
  void _drawElem(List<Elem> elems, bool isSelect, bool isAfter, double width, Canvas canvas) {
    // バグ対策
    if(elems.isEmpty){
      return;
    }

    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 99, 99, 99)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    for(int i = 0; i < elems.length; i++){
      if(elems[i].nodeList[0] != null && elems[i].nodeList[1] != null){
        Offset pos1 = Offset.zero;
        Offset pos2 = Offset.zero;
        if(isAfter){
          pos1 = elems[i].nodeList[0]!.canvasAfterPos;
          pos2 = elems[i].nodeList[1]!.canvasAfterPos;
          paint.color = MyPainter.getColor((data.resultList[i] - data.resultMin) / (data.resultMax - data.resultMin) * 100);
        }else{
          pos1 = elems[i].nodeList[0]!.canvasPos;
          pos2 = elems[i].nodeList[1]!.canvasPos;
          if(isSelect && elems[i].isSelect){
            paint.color = Colors.red;
          }else{
            paint.color = const Color.fromARGB(255, 86, 86, 86);
          }
        }
        canvas.drawLine(pos1, pos2, paint);
      }
    }
  }



  @override
  bool shouldRepaint(covariant TrussPainter oldDelegate) {
    return false;
  }
}