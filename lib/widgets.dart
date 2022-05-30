import 'package:chatapp/styles.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  const Header(this.heading, {Key? key}) : super(key: key);
  final String heading;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8.0),
        child: Text(
          heading,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      );
}

class Button extends StatelessWidget {
  const Button({Key? key, required this.callback, required this.text})
      : super(key: key);
  final void Function() callback;
  final String text;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: callback,
      style: Styles.buttonDecoration,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ),
    );
  }
}

class Paragraph extends StatelessWidget {
  const Paragraph(this.content, {Key? key}) : super(key: key);
  final String content;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          content,
          style: const TextStyle(fontSize: 18),
        ),
      );
}

class IconAndDetail extends StatelessWidget {
  const IconAndDetail(this.icon, this.detail, {Key? key}) : super(key: key);
  final IconData icon;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(
              detail,
              style: const TextStyle(fontSize: 18),
            )
          ],
        ),
      );
}

class StyledButton extends StatelessWidget {
  const StyledButton({Key? key, required this.child, required this.onPressed})
      : super(key: key);
  final Widget child;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.deepPurple)),
        onPressed: onPressed,
        child: child,
      );
}
