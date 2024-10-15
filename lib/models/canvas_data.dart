import 'package:flutter/material.dart';

class CanvasData{
  double scale = 1;
  Offset canvasCenterPos = const Offset(0, 0);
  Offset dataCenterPos = const Offset(0, 0);

  void setScale(double canvasMinX, canvasMinY, canvasMaxX, canvasMaxY, dataMinX, dataMinY, dataMaxX, dataMaxY){
    canvasCenterPos = Offset((canvasMinX + canvasMaxX) / 2, (canvasMinY + canvasMaxY) / 2);
    dataCenterPos = Offset((dataMinX + dataMaxX) / 2, (dataMinY + dataMaxY) / 2);
    if((canvasMaxX - canvasMinX) / (dataMaxX- dataMinX) < (canvasMaxY - canvasMinY) / (dataMaxY- dataMinY)){
      scale = (canvasMaxX - canvasMinX) / (dataMaxX- dataMinX);
    }
    else{
      scale = (canvasMaxY - canvasMinY) / (dataMaxY- dataMinY);
    }
  }

  // キャンパス座標をデータ座に
  Offset cToD(Offset pos){
    Offset dPos = pos - canvasCenterPos;
    dPos = dPos / scale;
    dPos = Offset(dPos.dx + dataCenterPos.dx, - dPos.dy + dataCenterPos.dy);
    return dPos;
  }

  // データ座標をキャンバス座標に
  Offset dToC(Offset pos){
    Offset cPos = pos - dataCenterPos;
    cPos = cPos * scale;
    cPos = Offset(cPos.dx + canvasCenterPos.dx, - cPos.dy + canvasCenterPos.dy);
    return cPos;
  }
}