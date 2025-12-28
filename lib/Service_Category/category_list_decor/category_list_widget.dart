
import 'package:finaproj/Service_Category/category_model/category_mdel.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CategoryListWidget extends StatelessWidget {
  const CategoryListWidget({super.key, required this.categoryModel});

  final CategoryModel categoryModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      
      height: 70,
    
      margin: EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 8),
      decoration: BoxDecoration(
        
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 0,
            spreadRadius: 0,
            offset:  Offset(0, 2), // 👈 shadow goes DOWN only
          )
        ],
        color: Colors.white
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 54,
            width: 54,
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0x0ff7f7f7),
              borderRadius: BorderRadius.circular(8)
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
                  margin: EdgeInsets.only(top: 5),
                  child: Text(categoryModel.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,),),
                ),
                Container(
                  margin: EdgeInsets.only(top: 2),
                  child: Text(categoryModel.subtitle, style: TextStyle(fontSize: 14),),
                )
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            child: Icon(Icons.arrow_forward_ios,size: 18,)
          )
        ],
        
      ),
    );
  }
}