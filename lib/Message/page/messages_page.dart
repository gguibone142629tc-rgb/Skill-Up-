import 'package:finaproj/Message/messages_widget/message_list_widget.dart';
import 'package:finaproj/Message/messages_widget/messages_search_widget.dart';

import 'package:finaproj/main.dart';

import 'package:flutter/material.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  String _searchQuery = '';
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _handleRefresh() async {
    // Wait a moment to allow Firestore stream to update
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _handleRefresh,
        color: const Color(0xFF2D6A65),
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              title: Text('Messages', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              pinned: true,
              elevation: 0,
            ),
            SliverToBoxAdapter(
              child: MessagesSearchWidget(
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            SliverToBoxAdapter(child: MessageListWidget(searchQuery: _searchQuery)),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(initialIndex: 2), 
    );
  }
}