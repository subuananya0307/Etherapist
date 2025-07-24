import 'package:flutter/material.dart';

class logoTile extends StatelessWidget {
  final String path;
  final Function()? onTap;
  const logoTile({
    super.key,
    required this.path,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        child: Image.asset(path,height: 50,),
      ),
    );
  }
}
