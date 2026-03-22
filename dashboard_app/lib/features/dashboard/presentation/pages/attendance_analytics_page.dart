import 'package:flutter/material.dart';
import 'package:dashboard_app/core/constants/app_constants.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';

class AttendanceAnalyticsPage extends StatefulWidget {
  const AttendanceAnalyticsPage({super.key});

  @override
  State<AttendanceAnalyticsPage> createState() => _AttendanceAnalyticsPageState();
}

class _AttendanceAnalyticsPageState extends State<AttendanceAnalyticsPage> {
  String _selectedView = 'Daily';
  final List<String> _views = ['Daily', 'Weekly', 'Monthly'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Analytics',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(AppConstants.textPrimary)),
                  ),
                  SizedBox(height: 4),
                  Text('Real-time attendance insights and trends', style: TextStyle(color: Color(AppConstants.textSecondary))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedView,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(AppConstants.primaryColor)),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(AppConstants.textPrimary)),
                    items: _views.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (val) => setState(() => _selectedView = val!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Summary Cards
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              String avgAttendance = '--%';
              String absentCount = '--';
              String accuracy = '99.5%';

              if (state is DashboardStatsLoadSuccess) {
                if (state.totalStudents > 0) {
                  final double ratio = (state.presentToday / state.totalStudents) * 100;
                  avgAttendance = '${ratio.toStringAsFixed(1)}%';
                } else {
                  avgAttendance = '0.0%';
                }
                absentCount = '${state.absentToday} Students';
              } else if (state is DashboardStatsLoadInProgress) {
                 avgAttendance = 'Loading...';
                 absentCount = 'Loading...';
              }

              return Row(
                children: [
                   _buildStatCard('Average Attendance', avgAttendance, Icons.trending_up_rounded, const Color(AppConstants.primaryColor)),
                   const SizedBox(width: 24),
                   _buildStatCard('Today\'s Absences', absentCount, Icons.warning_rounded, const Color(0xFFF59E0B)),
                   const SizedBox(width: 24),
                   _buildStatCard('Face Match Ver.', accuracy, Icons.face_retouching_natural_rounded, const Color(AppConstants.accentColor)),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          // Visualization Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Attendance Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(AppConstants.textPrimary))),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Color(AppConstants.textSecondary)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  Text('Showing $_selectedView statistics', style: const TextStyle(color: Color(AppConstants.textSecondary), fontSize: 13)),
                  const Expanded(
                    child: _PremiumChartPlaceholder(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(AppConstants.textSecondary), fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(AppConstants.textPrimary))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumChartPlaceholder extends StatelessWidget {
  const _PremiumChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(12, (index) {
              final height = 100.0 + (index * 35.0 % 200.0);
              return Container(
                width: 32,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(AppConstants.primaryColor).withOpacity(0.8),
                      const Color(AppConstants.primaryLight).withOpacity(0.4),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(AppConstants.backgroundColor),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(AppConstants.textSecondary)),
                SizedBox(width: 8),
                Text(
                  'Live Data Integration Pending',
                  style: TextStyle(color: Color(AppConstants.textSecondary), fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
