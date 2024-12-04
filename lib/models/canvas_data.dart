import 'package:flutter/material.dart';

class CanvasData{
  double scale = 1;
  Offset _canvasCenterPos = const Offset(0, 0);
  Offset _dataCenterPos = const Offset(0, 0);
  Rect _canvasRect = Rect.zero;

  void setScale(Rect canvasRect, Rect dataRect)
  {
    _canvasRect = canvasRect;
    _canvasCenterPos = canvasRect.center;
    _dataCenterPos = dataRect.center;
    double width = dataRect.width;
    double height = dataRect.height;
    if(width == 0 && height == 0){
      width = 100;
    }
    if(canvasRect.width / width < canvasRect.height / height){
      scale = canvasRect.width / width;
    }
    else{
      scale = canvasRect.height / height;
    }
  }

  // キャンパス座標をデータ座に
  Offset cToD(Offset pos)
  {
    Offset dPos = pos - _canvasCenterPos;
    dPos = dPos / scale;
    dPos = Offset(dPos.dx + _dataCenterPos.dx, - dPos.dy + _dataCenterPos.dy);
    return dPos;
  }

  // データ座標をキャンバス座標に
  Offset dToC(Offset pos)
  {
    Offset cPos = pos - _dataCenterPos;
    cPos = cPos * scale;
    cPos = Offset(cPos.dx + _canvasCenterPos.dx, - cPos.dy + _canvasCenterPos.dy);
    return cPos;
  }

  // キャンパス座標Rectをデータ座Rectに
  Rect cToDRect(Rect rect)
  {
    Offset reftTop = cToD(Offset(rect.left, rect.bottom));
    Offset rightBottom = cToD(Offset(rect.right, rect.top));
    return Rect.fromPoints(reftTop, rightBottom);
  }

  // データ座標Rectをキャンバス座標Rectに
  Rect dToCRect(Rect rect)
  {
    Offset reftTop = dToC(Offset(rect.left, rect.bottom));
    Offset rightBottom = dToC(Offset(rect.right, rect.top));
    return Rect.fromPoints(reftTop, rightBottom);
  }

  // %をキャンバス幅に
  double percentToCWidth(double percent)
  {
    if(_canvasRect.width > _canvasRect.height){
      return _canvasRect.height * percent / 100;
    }else{
      return _canvasRect.width * percent / 100;
    }
  }
}