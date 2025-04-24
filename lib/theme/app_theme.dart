import 'package:flutter/material.dart';

class AppTheme extends ThemeExtension<AppTheme> {
  final Color bgColor;
  final Color textFieldColor;
  final Color borderColor;
  final Color textColor;
  final Color buttonColor;
  final Color finishButton;
  final Color oppositeMessageBalloon;
  final Color messageColor;
  final Color videoComponent;
  final Color iconColor;
  final Color placeholderColor;
  final Color messageText;

  const AppTheme(
      {required this.bgColor,
      required this.textFieldColor,
      required this.borderColor,
      required this.textColor,
      required this.buttonColor,
      required this.finishButton,
      required this.oppositeMessageBalloon,
      required this.messageColor,
      required this.videoComponent,
      required this.iconColor,
      required this.placeholderColor,
      required this.messageText});

  @override
  ThemeExtension<AppTheme> copyWith(
      {Color? bgColor,
      Color? textFieldColor,
      Color? borderColor,
      Color? textColor,
      Color? buttonColor,
      Color? finishButton,
      Color? oppositeMessageBalloon,
      Color? messageColor,
      Color? videoComponent,
      Color? iconColor,
      Color? placeholderColor,
      Color? messageText}) {
    return AppTheme(
        bgColor: bgColor ?? this.bgColor,
        textFieldColor: textFieldColor ?? this.textFieldColor,
        borderColor: borderColor ?? this.borderColor,
        textColor: textColor ?? this.textColor,
        buttonColor: buttonColor ?? this.buttonColor,
        finishButton: finishButton ?? this.finishButton,
        oppositeMessageBalloon:
            oppositeMessageBalloon ?? this.oppositeMessageBalloon,
        messageColor: messageColor ?? this.messageColor,
        videoComponent: videoComponent ?? this.videoComponent,
        iconColor: iconColor ?? this.iconColor,
        placeholderColor: placeholderColor ?? this.placeholderColor,
        messageText: messageText ?? this.messageText);
  }

  @override
  ThemeExtension<AppTheme> lerp(ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) return this;
    return AppTheme(
        bgColor: Color.lerp(bgColor, other.bgColor, t)!,
        textFieldColor: Color.lerp(textFieldColor, other.textFieldColor, t)!,
        borderColor: Color.lerp(borderColor, other.borderColor, t)!,
        textColor: Color.lerp(textColor, other.textColor, t)!,
        buttonColor: Color.lerp(buttonColor, other.buttonColor, t)!,
        finishButton: Color.lerp(finishButton, other.finishButton, t)!,
        oppositeMessageBalloon: Color.lerp(
            oppositeMessageBalloon, other.oppositeMessageBalloon, t)!,
        messageColor: Color.lerp(messageColor, other.messageColor, t)!,
        videoComponent: Color.lerp(videoComponent, other.videoComponent, t)!,
        iconColor: Color.lerp(iconColor, other.iconColor, t)!,
        placeholderColor:
            Color.lerp(placeholderColor, other.placeholderColor, t)!,
        messageText: Color.lerp(messageText, other.messageText, t)!);
  }
}

final lightTheme = ThemeData().copyWith(extensions: <ThemeExtension<AppTheme>>[
  const AppTheme(
    bgColor: Color(0xfffaf0e6),
    textFieldColor: Color(0xfff9f5f0),
    borderColor: Color(0xffe0e0e0),
    textColor: Color(0xff333333),
    buttonColor: Color(0xffa3c4f3),
    finishButton: Color(0xffe63946),
    oppositeMessageBalloon: Color(0xfffadadd),
    messageColor: Color(0xffe3f2fd),
    videoComponent: Color(0xff4a90e2),
    iconColor: Color(0xff333333),
    placeholderColor: Color(0xffbdbdbd),
    messageText: Color(0xff333333),
  ),
]);

final darkTheme = ThemeData().copyWith(extensions: <ThemeExtension<AppTheme>>[
  const AppTheme(
    bgColor: Color(0xff121212),
    textFieldColor: Color(0xff424242),
    borderColor: Color(0xff757575),
    textColor: Color(0xffe0e0e0),
    buttonColor: Color(0xff2196f3),
    finishButton: Color(0xffe63946),
    oppositeMessageBalloon: Color(0xfffadadd),
    messageColor: Color(0xffe3f2fd),
    videoComponent: Color(0xff2196f3),
    iconColor: Color(0xffffc107),
    placeholderColor: Color(0xffbdbdbd),
    messageText: Color(0xff333333),
  ),
]);
