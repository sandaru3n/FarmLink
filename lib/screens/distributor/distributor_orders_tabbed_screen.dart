import 'package:flutter/material.dart';
import 'distributor_orders_screen.dart';
import 'distributor_consumer_orders_screen.dart';

class DistributorOrdersTabbedScreen extends StatefulWidget {
  const DistributorOrdersTabbedScreen({super.key});

  @override
  State<DistributorOrdersTabbedScreen> createState() => _DistributorOrdersTabbedScreenState();
}

class _DistributorOrdersTabbedScreenState extends State<DistributorOrdersTabbedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Farmer Orders'),
            Tab(text: 'Consumer Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DistributorOrdersScreen(),
          DistributorConsumerOrdersScreen(),
        ],
      ),
    );
  }
}
