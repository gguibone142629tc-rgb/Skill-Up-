import 'package:flutter/material.dart';

class MessagesSearchWidget extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  
  const MessagesSearchWidget({super.key, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 30),
      child: TextField(
        onChanged: onSearchChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          hintText: 'Search conversation',
          hintStyle: const TextStyle(color: Colors.grey),
          fillColor: const Color.fromARGB(255, 241, 241, 241),
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