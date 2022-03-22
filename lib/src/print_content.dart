import 'package:tiengviet/tiengviet.dart';

class PrintContent {
  String? data;
  String codePage;
  int width;
  int margin;
  String? textFont;
  int? textWidth;
  int? textHeight;
  bool textReverse;
  bool textBold;
  bool overridable;
  bool truncatable;

  PrintContent({
    this.data = 'Null data',
    this.codePage = 'CP1252',
    required this.width,
    this.margin = 0,
    this.textFont = 'Font A',
    this.textWidth = 1,
    this.textHeight = 1,
    this.textReverse = false,
    this.textBold = false,
    this.overridable = false,
    this.truncatable = true,
  });

  factory PrintContent.fromWrapText(
          {required String data,
          required int width,
          String codePage = 'CP1252',
          int margin = 0,
          String textFont = 'Font A',
          int textWidth = 1,
          int textHeight = 1,
          bool textReverse = false,
          bool textBold = false,
          bool overridable = false,
          bool truncatable = true}) =>
      PrintContent(
          data: TiengViet.parse(data),
          codePage: codePage,
          textFont: textFont,
          width: width,
          margin: margin,
          textBold: textBold,
          textReverse: textReverse,
          textHeight: textHeight,
          textWidth: textWidth,
          overridable: overridable,
          truncatable: truncatable);
}
