/// Farming Calendar Screen
///
/// Shows auto-generated farming plan (read-only)
/// and allows user to add custom events

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firebase_service.dart';
import '../../models/farming_plan_model.dart';
import '../../models/event_model.dart';

class FarmingCalendarScreen extends StatefulWidget {
  const FarmingCalendarScreen({super.key});

  @override
  State<FarmingCalendarScreen> createState() => _FarmingCalendarScreenState();
}

class _FarmingCalendarScreenState extends State<FarmingCalendarScreen>
    with SingleTickerProviderStateMixin {
  final _firebaseService = FirebaseService();
  late TabController _tabController;

  FarmingPlanModel? _farmingPlan;
  List<EventModel> _customEvents = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load farming plan
      final plan = await _firebaseService.getFarmingPlan(uid);

      // Load custom events
      final events = await _firebaseService.getCustomEvents(uid);

      if (mounted) {
        setState(() {
          _farmingPlan = plan;
          _customEvents = events;
          _isLoading = false;
        });
        print('Loaded ${events.length} custom events'); // Debug log
      }
    } catch (e) {
      print('Error loading calendar data: $e'); // Debug log
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;

                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;

                final event = EventModel(
                  id: '',
                  userId: uid,
                  title: titleController.text,
                  description: descriptionController.text,
                  date: selectedDate,
                  isCompleted: false,
                  createdAt: DateTime.now(),
                );

                await _firebaseService.addCustomEvent(event);

                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text('Add Event'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Farming Calendar'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Farming Plan'),
            Tab(text: 'My Events'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildFarmingPlanTab(), _buildCustomEventsTab()],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
    );
  }

  Widget _buildFarmingPlanTab() {
    if (_farmingPlan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today,
              size: 80,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No farming plan yet',
              style: TextStyle(fontSize: 18, color: AppColors.textGrey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a crop to generate your farming plan',
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan summary card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _farmingPlan!.cropName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Farming Plan',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                if (_farmingPlan!.isAIGenerated) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 12,
                                          color: Colors.purple.shade700,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Gemini AI',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateInfo(
                          'Sowing Date',
                          _farmingPlan!.sowingDate,
                          Icons.grass,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateInfo(
                          'Harvest Date',
                          _farmingPlan!.harvestDate,
                          Icons.agriculture,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Activities list header
          Row(
            children: [
              Icon(
                _farmingPlan!.isAIGenerated
                    ? Icons.auto_awesome
                    : Icons.lock_outline,
                size: 16,
                color: _farmingPlan!.isAIGenerated
                    ? Colors.purple
                    : AppColors.textGrey,
              ),
              const SizedBox(width: 4),
              Text(
                _farmingPlan!.isAIGenerated
                    ? 'AI-Generated Weekly Plan'
                    : 'Auto-generated Plan (Read-only)',
                style: TextStyle(
                  fontSize: 14,
                  color: _farmingPlan!.isAIGenerated
                      ? Colors.purple
                      : AppColors.textGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _farmingPlan!.activities.length,
            itemBuilder: (context, index) {
              final activity = _farmingPlan!.activities[index];
              return _buildActivityCard(activity, index);
            },
          ),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, DateTime date, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryGreen),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
          const SizedBox(height: 2),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(FarmingActivity activity, int index) {
    final isPast = activity.date.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPast
                        ? AppColors.primaryGreen
                        : AppColors.primaryGreen.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _getActivityIcon(activity.type),
                      size: 20,
                      color: isPast ? Colors.white : AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Activity details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isPast
                          ? AppColors.textGrey
                          : AppColors.textPrimary,
                      decoration: isPast ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.date.day}/${activity.date.month}/${activity.date.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getActivityTypeColor(
                            activity.type,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activity.type.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getActivityTypeColor(activity.type),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActivityTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.sowing:
        return AppColors.primaryGreen;
      case ActivityType.irrigation:
        return AppColors.accentBlue;
      case ActivityType.fertilizer:
        return AppColors.accentOrange;
      case ActivityType.harvesting:
        return AppColors.primaryGreenDark;
      case ActivityType.pestControl:
        return AppColors.accentRed;
      default:
        return AppColors.textGrey;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.preparation:
        return Icons.agriculture;
      case ActivityType.sowing:
        return Icons.grass;
      case ActivityType.irrigation:
        return Icons.water_drop;
      case ActivityType.fertilizer:
        return Icons.science;
      case ActivityType.pestControl:
        return Icons.bug_report;
      case ActivityType.maintenance:
        return Icons.build;
      case ActivityType.harvesting:
        return Icons.shopping_basket;
      case ActivityType.custom:
        return Icons.event_note;
    }
  }

  Widget _buildCustomEventsTab() {
    if (_userId == null) {
      return const Center(child: Text('Please login to view events'));
    }

    return StreamBuilder<List<EventModel>>(
      stream: _firebaseService.getCustomEventsStream(_userId!),
      initialData: _customEvents,
      builder: (context, snapshot) {
        // Handle loading state only if we have no cached data
        if (snapshot.connectionState == ConnectionState.waiting &&
            _customEvents.isEmpty &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }

        if (snapshot.hasError) {
          print('Stream error: ${snapshot.error}');
          // Show cached data if available, otherwise show error
          if (_customEvents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: AppColors.accentRed,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
        }

        final events = snapshot.data ?? _customEvents;

        // Update local cache safely
        if (snapshot.hasData && events.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _customEvents.length != events.length) {
              setState(() => _customEvents = events);
            }
          });
        }

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_note,
                  size: 80,
                  color: AppColors.textGrey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No custom events yet',
                  style: TextStyle(fontSize: 18, color: AppColors.textGrey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to add your own events',
                  style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (event.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              event.description,
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 14,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            '${event.date.day}/${event.date.month}/${event.date.year}',
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.accentRed,
                      ),
                      onPressed: () async {
                        await _firebaseService.deleteCustomEvent(event.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
