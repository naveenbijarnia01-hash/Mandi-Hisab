import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import 'gaadi_entry_screen.dart';

class GaadiRegisterScreen extends ConsumerStatefulWidget {
  const GaadiRegisterScreen({super.key});

  @override
  ConsumerState<GaadiRegisterScreen> createState() => _GaadiRegisterScreenState();
}

class _GaadiRegisterScreenState extends ConsumerState<GaadiRegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleListAsync = ref.watch(vehicleListStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gaadi Register (Vehicle Register)'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.secondary,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Sabhi (All)'),
            Tab(text: 'Aavak (In)'),
            Tab(text: 'Javak (Out)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Gaadi No / Party / Location se khojein...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Vehicle List
          Expanded(
            child: vehicleListAsync.when(
              data: (vehicles) {
                final filtered = vehicles.where((v) {
                  final matchQuery = v.vehicleNumber.toLowerCase().contains(_searchQuery) ||
                      v.partyName.toLowerCase().contains(_searchQuery) ||
                      v.destinationLocation.toLowerCase().contains(_searchQuery) ||
                      v.sourceLocation.toLowerCase().contains(_searchQuery);
                  return matchQuery;
                }).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVehicleList(filtered),
                    _buildVehicleList(filtered.where((v) => v.movementType == 'incoming').toList()),
                    _buildVehicleList(filtered.where((v) => v.movementType == 'outgoing').toList()),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        icon: const Icon(Icons.add),
        label: const Text('Nayi Gaadi Darz Karein'),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const GaadiEntryScreen()));
        },
      ),
    );
  }

  Widget _buildVehicleList(List<VehicleModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('Koi gaadi record nahi mila'));
    }

    final timeFormat = DateFormat('dd MMM, hh:mm a');

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final v = list[index];
        final isIncoming = v.movementType == 'incoming';
        final isCompleted = v.status == VehicleStatus.completed;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIncoming ? AppColors.success : const Color(0xFFC2410C),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          v.vehicleNumber,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        v.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Party: ${v.partyName}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.route, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${v.sourceLocation}  ➔  ${v.destinationLocation}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      v.items.map((i) => '${i.cropName}: ${i.quantity} ${i.unit.label}').join(', '),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                    ),
                    Text(
                      timeFormat.format(v.arrivalTime),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
