// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kozo/components/decorations.dart';

// ignore: must_be_immutable
class MyContainer extends StatelessWidget {
  MyContainer({
    super.key, 
    this.child = const SizedBox(), 
    this.width = double.infinity, this.height = double.infinity, 
    this.alignment = Alignment.topLeft,
    this.margin = EdgeInsets.zero, this.padding = EdgeInsets.zero,
    this.color = const Color.fromARGB(0, 0, 0, 0),
    this.isTopBorder = false, this.isBotomBorder = false, this.isLeftBorder = false, this.isRightBorder = false, this.isAllBorder = false,
    this.borderWidth = 0, this.borderColor = const Color.fromARGB(255, 200, 200, 200), this.borderRadius = BorderRadius.zero,
  }){
    if(isAllBorder){
      isBotomBorder = true;
      isLeftBorder = true;
      isRightBorder = true;
      isTopBorder = true;
    }
  }

  final Widget child;
  final double width, height;
  final Alignment alignment;
  final EdgeInsets margin, padding;
  final Color color;
  bool isTopBorder, isBotomBorder, isLeftBorder, isRightBorder, isAllBorder;
  final double borderWidth;
  final Color borderColor;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border(
          left: border(isLeftBorder),
          top: border(isTopBorder),
          right: border(isRightBorder),
          bottom: border(isBotomBorder),
        ),
        borderRadius: borderRadius,
      ),
      child: child
    );
  }

  BorderSide border(bool isSet){
    if(isSet){
      return BorderSide(
        color: borderColor,
        width: borderWidth,
      );
    }
    else{
      return const BorderSide(
        color: Color.fromARGB(0, 0, 0, 0),
        width: 0,
      );
    }
  }
}

class ContentBox extends StatelessWidget {
  const ContentBox({super.key, this.leftChild, this.children = const <Widget>[], this.rightChild, this.height, this.sideWidth});

  final Widget? leftChild;
  final List<Widget> children;
  final Widget? rightChild;
  final double? height;
  final double? sideWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 40,
      child: Row(
        children: [
          SizedBox(
            width: sideWidth ?? 40,
            child: Center(
              child: leftChild ?? const Center(),
            ),
          ),

          const SizedBox(width: 1,),

          Expanded(
            child: Row(
              children: [
                for(int i = 0; i < children.length; i++)...{
                  Expanded(
                    child: Center(
                      child: children[i],
                    ),
                  ),
                  const SizedBox(width: 1,),
                }
              ],
            ),
          ),

          SizedBox(
            width: sideWidth ?? 40,
            child: Center(
              child: rightChild ?? const Center(),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class ContentTextField extends StatelessWidget {
  ContentTextField({super.key, required this.text, required this.onChange});

  final String text;
  void Function(String value) onChange;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        border: InputBorder.none,
        fillColor: Color.fromARGB(31, 165, 165, 165),
        filled: true,
      ),
      controller: TextEditingController(text: text),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9.-]+'))],
      onChanged: (value) {
        onChange(value);
      },
    );
  }
}

// ignore: must_be_immutable
class ContentDropdown extends StatelessWidget {
  ContentDropdown({super.key, this.value, required this.items, required this.onChange});

  final String? value;
  final List<String> items;
  void Function(String? newValue) onChange;

  @override
  Widget build(BuildContext context) {
    final String? dropdownValue = (value != null && items.contains(value)) ? value : items.first;

    return DropdownButton<String>(
      value: dropdownValue,
      items: items
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChange,
      underline: Container(color: Colors.transparent),
    );
  }
}

// ignore: must_be_immutable
class ContentCheckbox extends StatelessWidget {
  ContentCheckbox({super.key, required this.value, required this.onChange});

  final bool value;
  void Function(bool? value) onChange;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      // tristate: true,
      value: value, 
      onChanged: onChange,
    );
  }
}

class MyTextField extends StatelessWidget {
  const MyTextField({super.key, required this.text, required this.onChange, this.color = const Color.fromARGB(255, 255, 255, 255)});

  final String text;
  final void Function(String value) onChange;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: color,
        contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5),
      ),
      controller: TextEditingController(text: text),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9.-]+'))],
      onChanged: (value) {onChange(value);},
    );
  }
}

class MyCheckbox extends StatelessWidget {
  const MyCheckbox({super.key, required this.value, required this.onChanged});

  final bool value;
  final void Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      // dimension: 25,
      child: 
    ToggleButtons(
      isSelected: [value],
      onPressed: (int index) {
        onChanged(!value);
      },
      borderColor: MyColors.border,
      selectedBorderColor: MyColors.border,
      borderRadius: MyBorderRadius.circle,
      borderWidth: 1,
      color: const Color.fromARGB(0, 255, 255, 255),
      fillColor: const Color.fromARGB(0, 255, 255, 255),
      selectedColor: const Color.fromARGB(255, 0, 0, 0),
      // constraints: BoxConstraints(
      //   minWidth: 10,
      //   minHeight: 10,
      // ),
      children: [
        if(value)...{
          const Icon(Icons.check)
        }
        else...{
          const SizedBox()
        }
      ],
    )
    );
  }
}

class MyToggleButtons extends StatelessWidget {
  const MyToggleButtons({
    super.key,  
    required this.isSelected, required this.onPressed, required this.children,
    this.direction = Axis.horizontal, this.width = 50, this.height = 50,
  });

  final List<bool> isSelected;
  final void Function(int index) onPressed;
  final List<Widget> children;
  final Axis direction;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: isSelected,
      onPressed: (int index) {
        onPressed(index);
      },
      direction: direction,
      constraints: BoxConstraints(
        minWidth: width,
        minHeight: height,
      ),
      children: children,
    );
  }
}

class MyAlign extends StatelessWidget {
  const MyAlign({
    super.key, 
    this.alignment = Alignment.center, 
    this.child = const SizedBox(), 
    this.isIntrinsicHeight = false, this.isIntrinsicWidth = false
  });

  final Alignment alignment;
  final Widget child;
  final bool isIntrinsicHeight, isIntrinsicWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Stack(
        children: [
          if(isIntrinsicHeight && isIntrinsicWidth)...{
            heightwidth(),
          }else if(isIntrinsicHeight)...{
            heigh(),
          }else if(isIntrinsicWidth)...{
            width(),
          }else...{
            child,
          }
        ],
      ),
    );
  }

  Widget heightwidth(){
    return IntrinsicHeight(
      child: IntrinsicWidth(
        child: child,
      ),
    );
  }

  Widget heigh(){
    return IntrinsicHeight(
      child: child,
    );
  }

  Widget width(){
    return IntrinsicWidth(
      child: child,
    );
  }
}

class MyScaffold extends StatelessWidget {
  const MyScaffold({super.key, this.header, this.body});

  final Widget? header, body;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          if(header != null)...{
            header!,
          },
          Expanded(
            child: body ?? const SizedBox(),
          )
        ],
      )
    );
  }
}

class MyHeaderMenu extends StatelessWidget {
  const MyHeaderMenu({super.key, required this.children,});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 50,
      width: double.infinity,
      decoration: myBoxDecorationHeader,
      child: Row(
        children: [
          const SizedBox(width: 10,),
          for(int i = 0; i < children.length; i++)...{
            children[i],
            const SizedBox(width: 10,),
          }
        ],
      ),
    );
  }
}

class MyDrawer extends Drawer {
  const MyDrawer({super.key, required this.itemList, required this.onTap});

  final List<String> itemList;
  final void Function(int number) onTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          for(int i = 0; i < itemList.length; i++)...{
            ListTile(
              title: Text(itemList[i]),
              onTap: () {
                onTap(i);
              },
            ),
          },
        ],
      ),
    );
  }
}

class MyMenuIconButton extends StatelessWidget {
  const MyMenuIconButton({super.key, required this.icon, required this.onPressed});

  final IconData icon;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

class MyMenuToggleButtons extends StatelessWidget {
  const MyMenuToggleButtons({super.key, required this.icons, required this.value, required this.onPressed});

  final int value;
  final List<IconData> icons;
  final void Function(int value) onPressed;

  @override
  Widget build(BuildContext context) {
    List<bool> isSelected = List.generate(icons.length, (index) => false);
    isSelected[value] = true;

    return ToggleButtons(
      // constraints: const BoxConstraints(
      //   minWidth: 50,
      //   minHeight: 50,
      // ),
      borderColor: Colors.transparent,
      isSelected: isSelected,
      onPressed: onPressed,
      children: [
        for(int i = 0; i < icons.length; i++)...{
          Icon(icons[i]),
        }
      ],
    );
  }
}

class MyMenuDropdown extends StatelessWidget {
  const MyMenuDropdown({super.key, required this.value, required this.items, required this.onPressed});

  final int value;
  final List<String> items;
  final void Function(int value) onPressed;

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      value: items[value],
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      underline: Container(color: Colors.transparent),
      onChanged: (String? newValue) {
        for(int i = 0; i < items.length; i++){
          if(newValue == items[i]){
            onPressed(i);
            break;
          }
        }
      },
    );
  }
}

class MyCustomPaint extends StatelessWidget {
  const MyCustomPaint({super.key, required this.painter, this.onTap, this.onDrag});

  final void Function(Offset position)? onTap, onDrag;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: MyColors.wiget1,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          onTap!(details.localPosition);
          if(onDrag != null){
            onDrag!(details.localPosition);
          }
        },
        onHorizontalDragUpdate: (details) {
          if(onDrag != null){
            onDrag!(details.localPosition);
          }
        },
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // 利用可能な最大幅と高さを取得
            final double maxWidth = constraints.maxWidth;
            final double maxHeight = constraints.maxHeight;

            // CustomPaintのサイズを設定
            return CustomPaint(
              size: Size(maxWidth, maxHeight), // ここで動的にサイズを指定
              painter: painter,
            );
          },
        ),
      ),
    );
  }
}