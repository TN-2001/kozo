import 'package:flutter/material.dart';
import 'package:kozo/components/decorations.dart';

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
            const Divider(height: 0, color: MyColors.border,),
          },
          Expanded(
            child: body ?? const SizedBox(),
          )
        ],
      )
    );
  }
}

class MyHeader extends StatelessWidget {
  const MyHeader({super.key, required this.children,});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MySize.headerHeight,
      width: double.infinity,
      color: Colors.white,
      // 要素
      child: Row(
        children: [
          const SizedBox(width: 5,),
          for(int i = 0; i < children.length; i++)...{
            // 要素
            children[i],
            if(i < children.length-1)...{
              // 要素間のライン
              Container(
                margin: const EdgeInsets.only(
                  left: 5,
                  right: 5,
                ),
                child: const VerticalDivider(width: 0, color: MyColors.border,),
              ),
            },
          },
          const SizedBox(width: 5,),
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
      width: 200,
      backgroundColor: Colors.white,
      // ウィジェットの形
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      // 要素
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

class MyIconButton extends StatelessWidget {
  const MyIconButton({super.key, required this.icon, required this.onPressed});

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

class MyIconToggleButtons extends StatelessWidget {
  const MyIconToggleButtons({super.key, required this.icons, required this.value, required this.onPressed});

  final int value;
  final List<IconData> icons;
  final void Function(int value) onPressed;

  @override
  Widget build(BuildContext context) {
    List<bool> isSelected = List.generate(icons.length, (index) => false);
    isSelected[value] = true;

    return ToggleButtons(
      constraints: const BoxConstraints(
        minWidth: MySize.iconButton,
        minHeight: MySize.iconButton,
        maxWidth: MySize.iconButton,
        maxHeight: MySize.iconButton,
      ),
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

class MySetting extends StatelessWidget {
  const MySetting({super.key, this.titleName, this.buttonName, this.onPressed, required this.children,});

  final String? titleName;
  final String? buttonName;
  final void Function()? onPressed;
  final List<MySettingItem> children;

  @override
  Widget build(BuildContext context) {
    return MyAlign(
      alignment: Alignment.bottomCenter,
      isIntrinsicWidth: true,
      isIntrinsicHeight: true,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(5),
        decoration: myBoxDecoration,
        child: Column(
          children: [
            // タイトル
            if(titleName != null)...{
              Container(
                height: 25,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 5, right: 5), 
                child: Text(titleName!),
              ),
              const SizedBox(height: 2.5,),
            },
            // ウィジェットリスト
            for(int i = 0; i < children.length; i++)...{
              children[i],
              if(i < children.length-1)...{
                const SizedBox(height: 2.5,),
              },
            },
            // ボタン
            if(buttonName != null && onPressed != null)...{
              const SizedBox(height: 2.5,),
              SizedBox(
                width: double.infinity,
                height: 25,
                child: Row(
                  children: [
                    const Expanded(child: SizedBox(), ),
                    ElevatedButton(
                      onPressed: () {
                        onPressed!();
                      },
                      style: myButtonStyleBorder,
                      child: Text(buttonName!),
                    ),
                  ],
                ),
              )
            }
          ],
        ),
      ),
    );
  }
}

class MySettingItem extends StatelessWidget {
  const MySettingItem({super.key, this.titleName = "", required this.children});

  final String titleName;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      alignment: Alignment.center,
      child: Row(
        children: [
          // タイトル
          Container(
            width: 75, 
            alignment: Alignment.centerLeft, 
            padding: const EdgeInsets.only(left: 5, right: 5), 
            child: Text(titleName),
          ),
          // ウィジェットリスト
          for(int i = 0; i < children.length; i++)...{
            const SizedBox(width: 10,),
            children[i],
          },
        ],
      )
    );
  }
}

class MySettingTextField extends StatelessWidget {
  const MySettingTextField({super.key, required this.name, required this.text, required this.onChanged,});

  final String name;
  final String text;
  final void Function(String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ラベル
        Container(
          width: 100, 
          alignment: Alignment.centerRight, 
          padding: const EdgeInsets.only(left: 5, right: 5), 
          child: Text(name),
        ),
        // テキストフィールド
        SizedBox(
          width: 100, 
          child: TextField(
            controller: TextEditingController(text: text),
            inputFormatters: myInputFormattersNumber,
            decoration: myInputDecoration,
            onChanged: (value) {
              onChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class MySettingCheckbox extends StatelessWidget {
  const MySettingCheckbox({super.key, required this.name, required this.value, required this.onChanged});

  final String name;
  final bool value;
  final void Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ラベル
        Container(
          width: 100, 
          alignment: Alignment.centerRight, 
          padding: const EdgeInsets.only(left: 5, right: 5), 
          child: Text(name),
        ),
        // チェックボックス
        Container(
          width: 100, 
          alignment: Alignment.centerLeft, 
          child: Checkbox(
            value: value,
            onChanged: (value) {
              onChanged(value!);
            },
          ),
        ),
      ],
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