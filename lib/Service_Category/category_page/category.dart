import 'package:finaproj/Service_Category/category_widget/category_widget.dart';
import 'package:flutter/material.dart';

class Category extends StatelessWidget {
  const Category({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(24),
          child: const Icon(Icons.arrow_back, size: 24),
        ),
        title: const Text(
          'Service Category',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: CategoryWidget(),
    );
  }
}
