import 'package:flutter/material.dart';
import 'package:kozo/apps/fem/fem_data.dart';
import 'package:kozo/components/my_painter.dart';

class FemPainter extends CustomPainter {
  const FemPainter({required this.data, required this.devTypeNum});

  final FemData data;
  final int devTypeNum;

  @override
  void paint(Canvas canvas, Size size) {

    // サイズに関する変数
    double width = 0;
    double heigh = 0;
    Rect rect = Rect.zero; // はりの表示範囲
    double nodeWidth = 0; // 節点の直径
    double elemWidth = 0; // 要素の太さ

    // サイズ設定
    void setSize() {
      // 要素の太さ
      elemWidth = rect.width/50;
      if(elemWidth > 15) {
        elemWidth = 15;
      } else if(elemWidth < 6.5) {
        elemWidth = 6.5;
      }
      // 節点の大きさ
      nodeWidth = elemWidth*0.6;
    }
    
    Rect dataRect = data.rect();
    List<Node> nodes = data.allNodeList();
    List<Elem> elems = data.allElemList();

    // キャンバスの広さ
    width = size.width-(size.width/4);
    heigh = size.height-(size.height/4);
    if(size.width - width < 200){
      width = size.width - 200;
    }
    if(size.height - heigh < 200){
      heigh = size.height - 200;
    }
    rect = Rect.fromLTRB((size.width-width)/2, (size.height-heigh)/2, size.width-(size.width-width)/2, size.height - (size.height-heigh)/2);
    
    if (!data.isCalculation) {
      setSize();
      data.updateCanvasPos(rect, 1);
      _drawElem(elems, true, canvas); // 要素
      _drawConst(nodes, dataRect, rect, canvas); // 節点拘束
      _drawPower(nodes, dataRect, canvas); // 荷重
      _drawNode(nodes, true, nodeWidth, canvas); // 節点
      _drawNodeNumber(nodes, true, canvas); // 節点番号
    }
    else{
      setSize();
      data.updateCanvasPos(rect, 1);
      _drawElem(data.elemList, false, canvas); // 要素
      _drawConst(data.nodeList, dataRect, rect, canvas); // 節点拘束
      _drawPower(data.nodeList, dataRect, canvas); // 荷重
      _drawNode(data.nodeList, false, nodeWidth, canvas); // 節点
      _drawResultElem(Rect.fromLTRB(rect.left, rect.top+rect.height/6, rect.right, rect.bottom-rect.height/6), elemWidth, canvas); // 変形図
      // MyPainter.rainbowBand(canvas, Offset(size.width - 60, size.height/4), Offset(size.width - 80, size.height - size.height/4), 50); // 虹色
      // 最大最小
      // Painter().text(canvas, size.width, MyPainter.doubleToString(data.resultMax, 3), Offset(size.width - 55, size.height/4-10), 12, Colors.black);
      // Painter().text(canvas, size.width, MyPainter.doubleToString(data.resultMin, 3), Offset(size.width - 55, size.height - size.height/4-10), 12, Colors.black);
    }
  }


  // 節点
  void _drawNode(List<Node> nodes, bool isSelect, double width, Canvas canvas) {
    Paint paint = Paint()
      ..strokeWidth = 2;

    if(nodes.isNotEmpty){
      for(int i = 0; i < nodes.length; i++){
        // 丸を描画
        paint.style = PaintingStyle.fill;
        paint.color = const Color.fromARGB(255, 79, 79, 79);
        canvas.drawCircle(nodes[i].canvasPos, width, paint);

        // 丸枠を描画
        paint.style = PaintingStyle.stroke;
        if(nodes[i].isSelect && isSelect){
          paint.color = Colors.red;
        }else{
          paint.color = const Color.fromARGB(255, 0, 0, 0);
        }
        canvas.drawCircle(nodes[i].canvasPos, width, paint);
      }
    }
  }

  // 節点番号
  void _drawNodeNumber(List<Node> nodes, bool isSelect, Canvas canvas) {
    if(nodes.isNotEmpty){
      for(int i = 0; i < nodes.length; i++){
        Offset pos = nodes[i].canvasPos;
        if(nodes[i].isSelect && isSelect){
          // Painter().text(canvas, 100, (i+1).toString(), Offset(pos.dx - 30, pos.dy - 30), 20, Colors.red);
        }else{
          // Painter().text(canvas, 100, (i+1).toString(), Offset(pos.dx - 30, pos.dy - 30), 20, Colors.black);
        }
      }
    }
  }

  // 要素
  void _drawElem(List<Elem> elems, bool isSelect, Canvas canvas) {
    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 194, 194, 194)
      ..style = PaintingStyle.fill;
    if(elems.isNotEmpty){
      // 三角形
      for(int i = 0; i < elems.length; i++){
        if(elems[i].nodeList[0] != null && elems[i].nodeList[1] != null && elems[i].nodeList[2] != null){
          var path = Path();
          path.moveTo(elems[i].nodeList[0]!.canvasPos.dx, elems[i].nodeList[0]!.canvasPos.dy);
          path.lineTo(elems[i].nodeList[1]!.canvasPos.dx, elems[i].nodeList[1]!.canvasPos.dy);
          path.lineTo(elems[i].nodeList[2]!.canvasPos.dx, elems[i].nodeList[2]!.canvasPos.dy);
          path.close();
          canvas.drawPath(path, paint);
        }
      }

      // 枠
      paint.color = const Color.fromARGB(255, 55, 55, 55);
      for(int i = 0; i < elems.length; i++){
        for(int j = 0; j < 3; j++){
          int num1 = j;
          int num2 = j < 2 ? j+1 : 0;
          if(elems[i].nodeList[num1] != null && elems[i].nodeList[num2] != null){
            canvas.drawLine(elems[i].nodeList[num1]!.canvasPos, elems[i].nodeList[num2]!.canvasPos, paint);
          }
        }
      }

      // 選択中の枠
      paint.color = Colors.red;
      paint.strokeWidth = 2.0;
      for(int i = 0; i < elems.length; i++){
        for(int j = 0; j < 3; j++){
          int num1 = j;
          int num2 = j < 2 ? j+1 : 0;
          if(elems[i].nodeList[num1] != null && elems[i].nodeList[num2] != null){
            if(isSelect & elems[i].isSelect){
              canvas.drawLine(elems[i].nodeList[num1]!.canvasPos, elems[i].nodeList[num2]!.canvasPos, paint);
            }
          }
        }
      }
    }
  }

  // 拘束
  void _drawConst(List<Node> nodes, Rect dataRect, Rect rect, Canvas canvas) {
    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 0, 0, 0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if(nodes.isNotEmpty){
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
  }

  // 荷重
  void _drawPower(List<Node> nodes, Rect dataRect, Canvas canvas) {    
    if(nodes.isNotEmpty){
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
  }

  // 変形後の要素
  void _drawResultElem(Rect canvasRect, double width, Canvas canvas) {
    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 225, 135, 135)
      ..style = PaintingStyle.fill
      ..strokeWidth = width;
    // 面
    paint = Paint()
      ..color = const Color.fromARGB(255, 49, 49, 49);

    for(int i = 0; i < data.elemList.length; i++){
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

    // 辺
    paint = Paint()
      ..color = const Color.fromARGB(255, 49, 49, 49)
      ..style = PaintingStyle.stroke;

    if(data.elemList.isNotEmpty){
      for(int i = 0; i < data.elemList.length; i++){
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

  @override
  bool shouldRepaint(covariant FemPainter oldDelegate) {
    return false;
  }
}