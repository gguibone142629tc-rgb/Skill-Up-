import 'package:finaproj/Message/messages_widget/message_list_widget.dart';
import 'package:finaproj/Message/messages_widget/messages_search_widget.dart';

import 'package:finaproj/main.dart';

import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Messages', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            pinned: true,
            elevation: 0,
          ),
          const SliverToBoxAdapter(child: MessagesSearchWidget()),
          SliverToBoxAdapter(child: MessageListWidget()), // Use BoxAdapter for lists
        ],
      ),
      // Pass index 2 so "Messages" turns blue
      bottomNavigationBar: const CustomBottomNavBar(initialIndex: 2), 
    );
  }
}