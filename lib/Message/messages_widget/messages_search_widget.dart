import 'package:flutter/material.dart';

class MessagesSearchWidget extends StatelessWidget {
  const MessagesSearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20,left: 20,right: 20,bottom: 30),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search,color: Colors.grey,),
          hint: Text('Search conversation',style: TextStyle(color: Colors.grey),),
          fillColor: Color.fromARGB(255, 241, 241, 241),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none
          )
        ),
      ),
    );
  }
}