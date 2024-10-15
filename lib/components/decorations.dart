import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// サイズ
class MySize{
  static const double headerHeight = 50;
  static const double iconButton = 40;
}

// 色
class MyColors{
  static const Color wiget0 = Color.fromARGB(255, 255, 255, 255);
  static const Color wiget1 = Color.fromARGB(255, 235, 235, 235);
  static const Color wiget2 = Color.fromARGB(255, 235, 235, 235);

  static const Color border = Color.fromARGB(255, 200, 200, 200);
}

// 形状
class MyBorderRadius{
  static BorderRadius circle = BorderRadius.circular(4);
}

// ボックスデコレーション
final BoxDecoration myBoxDecoration = BoxDecoration(
  color: MyColors.wiget0,
  borderRadius: MyBorderRadius.circle,
  border: Border.all(
    color: MyColors.border,
  )
);

// ボタンスタイル
final ButtonStyle myButtonStyle = ElevatedButton.styleFrom(
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.zero,
  ),
  backgroundColor: const Color.fromARGB(0, 0, 0, 0),
  foregroundColor: Colors.black,
  shadowColor: const Color.fromARGB(0, 0, 0, 0),
  padding: const EdgeInsets.all(0),
);

final ButtonStyle myButtonStyleBorder = ElevatedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: MyBorderRadius.circle,
    side: const BorderSide(color: MyColors.border),
  ),
  backgroundColor: const Color.fromARGB(0, 255, 255, 255),
  foregroundColor: Colors.black,
  shadowColor: const Color.fromARGB(0, 0, 0, 0),
  padding: const EdgeInsets.all(0),
);

// 入力制限
final List<TextInputFormatter> myInputFormattersNumber = [FilteringTextInputFormatter.allow(RegExp(r'^[0-9.-]+'))];

// 入力フィールドデコレーション
final InputDecoration myInputDecoration = InputDecoration(
  border: OutlineInputBorder(
    borderRadius: MyBorderRadius.circle,
    borderSide: const BorderSide(
      color: MyColors.border,
    ),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: MyBorderRadius.circle,
    borderSide: const BorderSide(
      color: MyColors.border,
    )
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: MyBorderRadius.circle,
    borderSide: const BorderSide(
      color: MyColors.border,
    )
  ),
  filled: true,
  fillColor: MyColors.wiget0,
  contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5),
);