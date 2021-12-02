import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:gastro_printing/src/print.dart';

enum PrintElementType { string, char, command }

class PrintElement {
  List<PosColumn> columnList;
  PrintElementType type;

  PrintElement(this.columnList, {this.type = PrintElementType.string});

  factory PrintElement.fromCutCommand() {
    List<PosColumn> contentList = [
      PosColumn(
        text: '__GS_V_m__',
      ),
    ];
    return PrintElement(contentList, type: PrintElementType.command);
  }

  factory PrintElement.fromChar({
    required PrintContent character,
  }) {
    List<PosColumn> contentList = [
      PosColumn(
          text: character.data!, //List.filled(character.width * 4 - 2, character.data!).join(),
          width: character.width,
          truncatable: character.truncatable,
          overridable: character.overridable,
          styles: PosStyles(
            codeTable: 'CP1252',
            align: PosAlign.right,
            fontType: character.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            bold: character.textBold,
            reverse: character.textReverse,
          )),
    ];
    return PrintElement(contentList, type: PrintElementType.char);
  }

  factory PrintElement.fromOneCol({
    required PrintContent content,
    bool center = true,
  }) {
    PosTextSize contentHeight;
    switch (content.textHeight) {
      case 1:
        contentHeight = PosTextSize.size1;
        break;
      case 2:
        contentHeight = PosTextSize.size2;
        break;
      case 3:
        contentHeight = PosTextSize.size3;
        break;
      default:
        contentHeight = PosTextSize.size1;
    }

    PosTextSize contentWidth;
    switch (content.textWidth) {
      case 1:
        contentWidth = PosTextSize.size1;
        break;
      case 2:
        contentWidth = PosTextSize.size2;
        break;
      case 3:
        contentWidth = PosTextSize.size3;
        break;
      default:
        contentWidth = PosTextSize.size1;
    }

    List<PosColumn> contentList = [
      PosColumn(
          text: content.data!,
          width: content.width,
          margin: content.margin,
          truncatable: content.truncatable,
          overridable: content.overridable,
          styles: PosStyles(
            align: center ? PosAlign.center : PosAlign.right,
            bold: content.textBold,
            codeTable: content.codePage,
            fontType: content.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            height: contentHeight,
            width: contentWidth,
            reverse: content.textReverse,
          )),
    ];
    return PrintElement(contentList);
  }

  factory PrintElement.fromTwoCols({
    required PrintContent leftContent,
    required PrintContent rightContent,
    bool rightAlign = true,
  }) {
    PosTextSize leftContentHeight;
    switch (leftContent.textHeight) {
      case 1:
        leftContentHeight = PosTextSize.size1;
        break;
      case 2:
        leftContentHeight = PosTextSize.size2;
        break;
      case 3:
        leftContentHeight = PosTextSize.size3;
        break;
      default:
        leftContentHeight = PosTextSize.size1;
    }

    PosTextSize leftContentWidth;
    switch (leftContent.textWidth) {
      case 1:
        leftContentWidth = PosTextSize.size1;
        break;
      case 2:
        leftContentWidth = PosTextSize.size2;
        break;
      case 3:
        leftContentWidth = PosTextSize.size3;
        break;
      default:
        leftContentWidth = PosTextSize.size1;
    }

    PosTextSize rightContentHeight;
    switch (rightContent.textHeight) {
      case 1:
        rightContentHeight = PosTextSize.size1;
        break;
      case 2:
        rightContentHeight = PosTextSize.size2;
        break;
      case 3:
        rightContentHeight = PosTextSize.size3;
        break;
      default:
        rightContentHeight = PosTextSize.size1;
    }

    PosTextSize rightContentWidth;
    switch (rightContent.textWidth) {
      case 1:
        rightContentWidth = PosTextSize.size1;
        break;
      case 2:
        rightContentWidth = PosTextSize.size2;
        break;
      case 3:
        rightContentWidth = PosTextSize.size3;
        break;
      default:
        rightContentWidth = PosTextSize.size1;
    }

    List<PosColumn> contentList = [
      PosColumn(
          text: leftContent.data!,
          width: leftContent.width,
          margin: leftContent.margin,
          truncatable: leftContent.truncatable,
          overridable: leftContent.overridable,
          styles: PosStyles(
            align: PosAlign.left,
            bold: leftContent.textBold,
            codeTable: 'CP1252',
            fontType: leftContent.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            height: leftContentHeight,
            width: leftContentWidth,
            reverse: leftContent.textReverse,
          )),
      PosColumn(
          text: rightContent.data!,
          width: rightContent.width,
          margin: rightContent.margin,
          truncatable: rightContent.truncatable,
          overridable: rightContent.overridable,
          styles: PosStyles(
            align: rightAlign ? PosAlign.right : PosAlign.left,
            bold: rightContent.textBold,
            codeTable: 'CP1252',
            fontType: rightContent.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            height: rightContentHeight,
            width: rightContentWidth,
            reverse: rightContent.textReverse,
          )),
    ];
    return PrintElement(contentList);
  }

  factory PrintElement.fromThreeCol({
    required PrintContent firstContent,
    required PrintContent secondContent,
    required PrintContent thirdContent,
    bool center = false,
  }) {
    PosTextSize firstContentHeight;
    switch (firstContent.textHeight) {
      case 1:
        firstContentHeight = PosTextSize.size1;
        break;
      case 2:
        firstContentHeight = PosTextSize.size2;
        break;
      case 3:
        firstContentHeight = PosTextSize.size3;
        break;
      default:
        firstContentHeight = PosTextSize.size1;
    }

    PosTextSize secondContentHeight;
    switch (secondContent.textHeight) {
      case 1:
        secondContentHeight = PosTextSize.size1;
        break;
      case 2:
        secondContentHeight = PosTextSize.size2;
        break;
      case 3:
        secondContentHeight = PosTextSize.size3;
        break;
      default:
        secondContentHeight = PosTextSize.size1;
    }

    PosTextSize thirdContentHeight;
    switch (thirdContent.textHeight) {
      case 1:
        thirdContentHeight = PosTextSize.size1;
        break;
      case 2:
        thirdContentHeight = PosTextSize.size2;
        break;
      case 3:
        thirdContentHeight = PosTextSize.size3;
        break;
      default:
        thirdContentHeight = PosTextSize.size1;
    }

    PosTextSize firstContentWidth;
    switch (firstContent.textWidth) {
      case 1:
        firstContentWidth = PosTextSize.size1;
        break;
      case 2:
        firstContentWidth = PosTextSize.size2;
        break;
      case 3:
        firstContentWidth = PosTextSize.size3;
        break;
      default:
        firstContentWidth = PosTextSize.size1;
    }

    PosTextSize secondContentWidth;
    switch (secondContent.textWidth) {
      case 1:
        secondContentWidth = PosTextSize.size1;
        break;
      case 2:
        secondContentWidth = PosTextSize.size2;
        break;
      case 3:
        secondContentWidth = PosTextSize.size3;
        break;
      default:
        secondContentWidth = PosTextSize.size1;
    }

    PosTextSize thirdContentWidth;
    switch (thirdContent.textWidth) {
      case 1:
        thirdContentWidth = PosTextSize.size1;
        break;
      case 2:
        thirdContentWidth = PosTextSize.size2;
        break;
      case 3:
        thirdContentWidth = PosTextSize.size3;
        break;
      default:
        thirdContentWidth = PosTextSize.size1;
    }

    List<PosColumn> contentList = [
      PosColumn(
          text: firstContent.data!,
          width: firstContent.width,
          margin: firstContent.margin,
          truncatable: firstContent.truncatable,
          overridable: firstContent.overridable,
          styles: PosStyles(
            align: PosAlign.left,
            bold: firstContent.textBold,
            codeTable: 'CP1252',
            fontType: firstContent.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            height: firstContentHeight,
            width: firstContentWidth,
            reverse: firstContent.textReverse,
          )),
      PosColumn(
          text: secondContent.data!,
          width: secondContent.width,
          margin: secondContent.margin,
          truncatable: secondContent.truncatable,
          overridable: secondContent.overridable,
          styles: PosStyles(
            align: center ? PosAlign.center : PosAlign.left,
            bold: secondContent.textBold,
            codeTable: 'CP1252',
            fontType: secondContent.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            height: secondContentHeight,
            width: secondContentWidth,
            reverse: secondContent.textReverse,
          )),
      PosColumn(
          text: thirdContent.data!,
          width: thirdContent.width,
          margin: thirdContent.margin,
          truncatable: thirdContent.truncatable,
          overridable: thirdContent.overridable,
          styles: PosStyles(
            align: PosAlign.right,
            bold: thirdContent.textBold,
            codeTable: 'CP1252',
            fontType: thirdContent.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            height: thirdContentHeight,
            width: thirdContentWidth,
            reverse: thirdContent.textReverse,
          )),
    ];
    return PrintElement(contentList);
  }

  factory PrintElement.fromSixCols({
    required PrintContent first,
    required PrintContent second,
    required PrintContent third,
    required PrintContent fourth,
    required PrintContent fifth,
    required PrintContent sixth,
  }) {
    PosTextSize firstContentHeight;
    PosTextSize secondContentHeight;
    PosTextSize thirdContentHeight;
    PosTextSize fourthContentHeight;
    PosTextSize fifthContentHeight;
    PosTextSize sixthContentHeight;

    PosTextSize firstContentWidth;
    PosTextSize secondContentWidth;
    PosTextSize thirdContentWidth;
    PosTextSize fourthContentWidth;
    PosTextSize fifthContentWidth;
    PosTextSize sixthContentWidth;

    switch (first.textHeight) {
      case 1:
        firstContentHeight = PosTextSize.size1;
        break;
      case 2:
        firstContentHeight = PosTextSize.size2;
        break;
      case 3:
        firstContentHeight = PosTextSize.size3;
        break;
      default:
        firstContentHeight = PosTextSize.size1;
    }

    switch (second.textHeight) {
      case 1:
        secondContentHeight = PosTextSize.size1;
        break;
      case 2:
        secondContentHeight = PosTextSize.size2;
        break;
      case 3:
        secondContentHeight = PosTextSize.size3;
        break;
      default:
        secondContentHeight = PosTextSize.size1;
    }

    switch (second.textHeight) {
      case 1:
        secondContentHeight = PosTextSize.size1;
        break;
      case 2:
        secondContentHeight = PosTextSize.size2;
        break;
      case 3:
        secondContentHeight = PosTextSize.size3;
        break;
      default:
        secondContentHeight = PosTextSize.size1;
    }

    switch (third.textHeight) {
      case 1:
        thirdContentHeight = PosTextSize.size1;
        break;
      case 2:
        thirdContentHeight = PosTextSize.size2;
        break;
      case 3:
        thirdContentHeight = PosTextSize.size3;
        break;
      default:
        thirdContentHeight = PosTextSize.size1;
    }

    switch (fourth.textHeight) {
      case 1:
        fourthContentHeight = PosTextSize.size1;
        break;
      case 2:
        fourthContentHeight = PosTextSize.size2;
        break;
      case 3:
        fourthContentHeight = PosTextSize.size3;
        break;
      default:
        fourthContentHeight = PosTextSize.size1;
    }

    switch (fifth.textHeight) {
      case 1:
        fifthContentHeight = PosTextSize.size1;
        break;
      case 2:
        fifthContentHeight = PosTextSize.size2;
        break;
      case 3:
        fifthContentHeight = PosTextSize.size3;
        break;
      default:
        fifthContentHeight = PosTextSize.size1;
    }

    switch (sixth.textHeight) {
      case 1:
        sixthContentHeight = PosTextSize.size1;
        break;
      case 2:
        sixthContentHeight = PosTextSize.size2;
        break;
      case 3:
        sixthContentHeight = PosTextSize.size3;
        break;
      default:
        sixthContentHeight = PosTextSize.size1;
    }

    switch (first.textWidth) {
      case 1:
        firstContentWidth = PosTextSize.size1;
        break;
      case 2:
        firstContentWidth = PosTextSize.size2;
        break;
      case 3:
        firstContentWidth = PosTextSize.size3;
        break;
      default:
        firstContentWidth = PosTextSize.size1;
    }

    switch (second.textWidth) {
      case 1:
        secondContentWidth = PosTextSize.size1;
        break;
      case 2:
        secondContentWidth = PosTextSize.size2;
        break;
      case 3:
        secondContentWidth = PosTextSize.size3;
        break;
      default:
        secondContentWidth = PosTextSize.size1;
    }

    switch (third.textWidth) {
      case 1:
        thirdContentWidth = PosTextSize.size1;
        break;
      case 2:
        thirdContentWidth = PosTextSize.size2;
        break;
      case 3:
        thirdContentWidth = PosTextSize.size3;
        break;
      default:
        thirdContentWidth = PosTextSize.size1;
    }

    switch (fourth.textWidth) {
      case 1:
        fourthContentWidth = PosTextSize.size1;
        break;
      case 2:
        fourthContentWidth = PosTextSize.size2;
        break;
      case 3:
        fourthContentWidth = PosTextSize.size3;
        break;
      default:
        fourthContentWidth = PosTextSize.size1;
    }

    switch (fifth.textWidth) {
      case 1:
        fifthContentWidth = PosTextSize.size1;
        break;
      case 2:
        fifthContentWidth = PosTextSize.size2;
        break;
      case 3:
        fifthContentWidth = PosTextSize.size3;
        break;
      default:
        fifthContentWidth = PosTextSize.size1;
    }

    switch (sixth.textWidth) {
      case 1:
        sixthContentWidth = PosTextSize.size1;
        break;
      case 2:
        sixthContentWidth = PosTextSize.size2;
        break;
      case 3:
        sixthContentWidth = PosTextSize.size3;
        break;
      default:
        sixthContentWidth = PosTextSize.size1;
    }

    List<PosColumn> contentList = [
      PosColumn(
          text: first.data!,
          width: first.width,
          styles: PosStyles(
            align: PosAlign.left,
            bold: first.textBold,
            codeTable: 'CP1252',
            fontType: first.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            height: firstContentHeight,
            width: firstContentWidth,
            reverse: first.textReverse,
          )),
      PosColumn(
          text: second.data!,
          width: second.width,
          styles: PosStyles(
            align: PosAlign.right,
            bold: second.textBold,
            codeTable: 'CP1252',
            fontType: second.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            height: secondContentHeight,
            width: secondContentWidth,
            reverse: second.textReverse,
          )),
      PosColumn(
          text: third.data!,
          width: third.width,
          styles: PosStyles(
            align: PosAlign.right,
            bold: third.textBold,
            codeTable: 'CP1252',
            fontType: third.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            height: thirdContentHeight,
            width: thirdContentWidth,
            reverse: third.textReverse,
          )),
      PosColumn(
          text: fourth.data!,
          width: fourth.width,
          styles: PosStyles(
            align: PosAlign.right,
            bold: fourth.textBold,
            codeTable: 'CP1252',
            fontType: fourth.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            height: fourthContentHeight,
            width: fourthContentWidth,
            reverse: fourth.textReverse,
          )),
      PosColumn(
          text: fifth.data!,
          width: fifth.width,
          styles: PosStyles(
            align: PosAlign.right,
            bold: fifth.textBold,
            codeTable: 'CP1252',
            fontType: fifth.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            height: fifthContentHeight,
            width: fifthContentWidth,
            reverse: fifth.textReverse,
          )),
      PosColumn(
          text: sixth.data!,
          width: sixth.width,
          styles: PosStyles(
            align: PosAlign.right,
            bold: sixth.textBold,
            codeTable: 'CP1252',
            fontType: sixth.textFont == 'Font A' ? PosFontType.fontA : PosFontType.fontB,
            height: sixthContentHeight,
            width: sixthContentWidth,
            reverse: sixth.textReverse,
          )),
    ];
    return PrintElement(contentList);
  }

// factory PrintElement.fromFourCols({
//   required PrintContent col1,
//   required PrintContent col2,
//   required PrintContent col3,
//   required PrintContent col4,
// }) {
//   List<PosColumn> contentList = [
//     PosColumn(
//         text: leftContent.data,
//         width: leftContent.width,
//         styles: PosStyles(
//           codeTable: 'CP1252',
//           align: PosAlign.left,
//           bold: leftContent.bold,
//         )),
//     PosColumn(
//         text: rightContent.data,
//         width: rightContent.width,
//         styles: PosStyles(
//           codeTable: 'CP1252',
//           align: PosAlign.right,
//           bold: rightContent.bold,
//         )),
//   ];
//   return PrintElement(contentList);
// }
}
