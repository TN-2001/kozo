import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kozo/utils/calculator.dart';

class Painter{
  void arrow(Offset start, end, double width, Canvas canvas){
    Paint p = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2 * width;

    if(start.dx > end.dx){
      canvas.drawLine(start, Offset(end.dx+4.3*width, end.dy), p);
    }else if(start.dx < end.dx){
      canvas.drawLine(start, Offset(end.dx-4.3*width, end.dy), p);
    }else if(start.dy > end.dy){
      canvas.drawLine(start, Offset(end.dx, end.dy+4.3*width), p);
    }else if(start.dy < end.dy){
      canvas.drawLine(start, Offset(end.dx, end.dy-4.3*width), p);
    }

    double arrowSize = 5 * width;
    const arrowAngle = math.pi / 6;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);

    final path = Path();
    path.moveTo(
      end.dx - arrowSize * math.cos(angle - arrowAngle),
      end.dy - arrowSize * math.sin(angle - arrowAngle),
    );
    path.lineTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowSize * math.cos(angle + arrowAngle),
      end.dy - arrowSize * math.sin(angle + arrowAngle),
    );
    path.close();
    canvas.drawPath(path, p);
  }

  // 2点間を繋ぐ角度自由の長方形
  void angleRectangle(Canvas canvas, Offset p0, Offset p1, double width, Color color, bool isfull){
    final paint = Paint()
      ..color = color;
    if(!isfull) paint.style = PaintingStyle.stroke;

    var p = angleRectanglePos(p0, p1, width);

    Offset topLeft = p.$1;
    Offset topRight = p.$2;
    Offset bottomRight = p.$3;
    Offset bottomLeft = p.$4;

    Path path = Path();
    path.moveTo(topLeft.dx, topLeft.dy);
    path.lineTo(topRight.dx, topRight.dy);
    path.lineTo(bottomRight.dx, bottomRight.dy);
    path.lineTo(bottomLeft.dx, bottomLeft.dy);
    path.close();

    canvas.drawPath(path, paint);
  }

  // 多角形
  void polygon(Canvas canvas, List<Offset> offsetList, Color color, bool isfull){
    final paint = Paint()
      ..color = color;
    if(!isfull) paint.style = PaintingStyle.stroke;

    final path = Path();
    for(int i = 0; i < offsetList.length; i++){
      if(i == 0){
        path.moveTo(offsetList[i].dx, offsetList[i].dy);
      }
      else{
        path.lineTo(offsetList[i].dx, offsetList[i].dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // 文字
  void text(Canvas canvas, double canvasWidth, String text, Offset offset, double fontSize, Color color){
    final textSpan1 = TextSpan(
      text: text,
      style: TextStyle(
        foreground: Paint()
          ..style = PaintingStyle.stroke // 輪郭（りんかく）
          ..strokeWidth = 5 // 輪郭の太さ
          ..strokeJoin = StrokeJoin.round // 輪郭の角を滑らかに
          ..color = Colors.white,
        fontSize: fontSize,
      ),
    );
    final textPainter1 = TextPainter(
      text: textSpan1,
      textDirection: TextDirection.ltr,
    );
    textPainter1.layout(
      minWidth: 0,
      maxWidth: canvasWidth,
    );
    textPainter1.paint(canvas, offset);
    
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: canvasWidth,
    );
    textPainter.paint(canvas, offset);
  }

  // 虹色帯
  void rainbowBand(Canvas canvas, Offset offset1, Offset offset2, int number){
    final double minX = math.min(offset1.dx, offset2.dx);
    final double maxX = math.max(offset1.dx, offset2.dx);
    final double minY = math.min(offset1.dy, offset2.dy);
    final double maxY = math.max(offset1.dy, offset2.dy);
    final paint = Paint();
    for(int i = 0; i < number; i++){
      paint.color = Painter().getColor((number-i)/number * 100);
      final path = Path();
      path.moveTo(maxX, (maxY - minY) / number * i + minY);
      path.lineTo(maxX, (maxY - minY) / number * (i+1) + minY);
      path.lineTo(minX, (maxY - minY) / number * (i+1) + minY);
      path.lineTo(minX, (maxY - minY) / number * i + minY);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  // 色0～100
  Color getColor(double par){
    Color color = const Color.fromARGB(255, 255, 0, 0);
    color = const Color.fromARGB(255, 255, 255, 0);
    color = const Color.fromARGB(255, 0, 255, 0);
    color = const Color.fromARGB(255, 0, 255, 255);
    color = const Color.fromARGB(255, 0, 0, 255);

    color = const Color.fromARGB(255, 255, 0, 0);

    double get = par / 100 * 4;
    if(get <= 1){
      color = Color.fromARGB(255, 0, (255 * get).toInt(), 255);
    }
    else if(get > 1 && get <= 2){
      get -= 1;
      color = Color.fromARGB(255, 0, 255, (255 - 255 * get).toInt());
    }
    else if(get > 2 && get <= 3){
      get -= 2;
      color = Color.fromARGB(255, (255 * get).toInt(), 255, 0);
    }
    else if(get > 3 && get <= 4){
      get -= 3;
      color = Color.fromARGB(255, 255, (255 - 255 * get).toInt(), 0);
    }

    return color;
  }
}