import 'package:flutter/material.dart';

class CanvasData{
  double scale = 1;
  Offset canvasCenterPos = const Offset(0, 0);
  Offset dataCenterPos = const Offset(0, 0);

  void setScale(double canvasWidth, canvasHeight, dataMinX, dataMinY, dataMaxX, dataMaxY){
    canvasCenterPos = Offset(canvasWidth / 2, canvasHeight / 2);
    dataCenterPos = Offset((dataMinX + dataMaxX) / 2, (dataMinY + dataMaxY) / 2);
    if(canvasWidth / (dataMaxX- dataMinX) < canvasHeight / (dataMaxY- dataMinY)){
      scale = canvasWidth / (dataMaxX- dataMinX);
    }
    else{
      scale = canvasHeight / (dataMaxY- dataMinY);
    }
  }

  Offset canvasPosToDataPos(Offset pos){
    Offset dPos = pos - canvasCenterPos;
    dPos = dPos / scale;
    dPos = Offset(dPos.dx + dataCenterPos.dx, - dPos.dy + dataCenterPos.dy);
    return dPos;
  }

  Offset dataPosToCanvasPos(Offset pos){
    Offset cPos = pos - dataCenterPos;
    cPos = cPos * scale;
    cPos = Offset(cPos.dx + canvasCenterPos.dx, - cPos.dy + canvasCenterPos.dy);
    return cPos;
  }
}