
import 'package:finaproj/Service_Category/category_model/category_mdel.dart';
import 'package:finaproj/FindMentor/page/find_mentor_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CategoryListWidget extends StatelessWidget {
  const CategoryListWidget({super.key, required this.categoryModel});

  final CategoryModel categoryModel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FindMentorPage(
              initialCategory: categoryModel.title,
              initialCategories: [categoryModel.title],
              hideStudents: true,
            ),
          ),
        );
      },
      child: Container(
        height: 70,
        margin: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 0,
              spreadRadius: 0,
              offset: const Offset(0, 2), // shadow goes DOWN only
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 54,
              width: 54,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SvgPicture.asset(
                  categoryModel.iconPath,
                  height: 22,
                  width: 22,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    child: Text(
                      categoryModel.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: Text(categoryModel.subtitle, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              child: const Icon(Icons.arrow_forward_ios, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}