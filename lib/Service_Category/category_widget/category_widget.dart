import 'package:finaproj/Service_Category/category_list_decor/category_list_widget.dart';
import 'package:finaproj/Service_Category/category_model/category_mdel.dart';
import 'package:flutter/material.dart';

class CategoryWidget extends StatelessWidget {
  CategoryWidget({super.key});

  final List<CategoryModel> listCateg = [
    CategoryModel(
      iconPath: 'assets/icons/Vector.svg',
      title: 'Graphic Design',
      subtitle: 'Logo & brand identity',
    ),
    CategoryModel(
      iconPath: 'assets/icons/micro.svg',
      title: 'Digital Marketing',
      subtitle: 'Social media marketing, SEO',
    ),
    CategoryModel(
      iconPath: 'assets/icons/video-play.svg',
      title: 'Video & Animation',
      subtitle: 'Video editing & Vide Ads',
    ),
    CategoryModel(
      iconPath: 'assets/icons/music.svg',
      title: 'Music & Audio',
      subtitle: 'Producers & Composers',
    ),
    CategoryModel(
      iconPath: 'assets/icons/code.svg',
      title: 'Program & Tech',
      subtitle: 'Website & App development',
    ),
    CategoryModel(
      iconPath: 'assets/icons/camera.svg',
      title: 'Product Photography',
      subtitle: 'Product Photographers',
    ),
    CategoryModel(
      iconPath: 'assets/icons/chip.svg',
      title: 'Build AI Service',
      subtitle: 'Build your AI app',
    ),
    CategoryModel(
      iconPath: 'assets/icons/note.svg',
      title: 'Data',
      subtitle: 'Data Science & AI',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: listCateg.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return CategoryListWidget(categoryModel: listCateg[index]);
      },
    );
  }
}
