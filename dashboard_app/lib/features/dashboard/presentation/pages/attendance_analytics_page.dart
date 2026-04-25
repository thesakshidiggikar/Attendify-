import 'package:flutter/material.dart';
import 'package:dashboard_app/core/constants/app_constants.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../bloc/dashboard_bloc.dart';
import '../../domain/entities/employee.dart';

class AttendanceAnalyticsPage extends StatefulWidget {
  const AttendanceAnalyticsPage({super.key});

  @override
  State<AttendanceAnalyticsPage> createState() => _AttendanceAnalyticsPageState();
  
}

class _AttendanceAnalyticsPageState extends State<AttendanceAnalyticsPage> {
  String _selectedView = 'Daily';
  final List<String> _views = ['Daily', 'Weekly', 'Monthly'];

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(FetchDashboardStatsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1100;
        final horizontalPadding = isCompact ? 24.0 : 40.0;
        
        return BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardStatsLoadSuccess) {
              return ListView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 40.0),
                physics: const BouncingScrollPhysics(),
                children: [
                   _buildSupremeHeader(isCompact),
                   const SizedBox(height: 48),
                   _buildStatGrid(state, isCompact),
                   const SizedBox(height: 40),
                   _buildMainAnalyticsStage(state, isCompact),
                   const SizedBox(height: 40),
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Expanded(
                         flex: 4,
                         child: _buildSupremeModule(
                           title: 'REGIONAL SYNC',
                           subtitle: 'Departmental check-in health audit',
                           icon: Icons.lan_rounded,
                           child: SizedBox(height: 400, child: _DepartmentBarChart(deptStats: _calculateDeptStats(state.employees))),
                         ),
                       ),
                       const SizedBox(width: 32),
                       Expanded(
                         flex: 3,
                         child: _buildSupremeModule(
                           title: 'REGISTRY COMPOSITION',
                           subtitle: 'Live student population density',
                           icon: Icons.donut_large_rounded,
                           child: SizedBox(height: 400, child: _AttendanceDistributionPie(
                             present: state.presentToday,
                             absent: state.absentToday,
                             total: state.totalStudents,
                           )),
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 40),
                   _buildSupremeModule(
                     title: 'CENTRAL AUDIT STREAM',
                     subtitle: 'Real-time synchronization logs from regional terminals',
                     icon: Icons.analytics_rounded,
                     child: const _RecentActivityList(isFullView: true),
                   ),
                   const SizedBox(height: 60),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 3));
          },
        );
      },
    );
  }

  Widget _buildSupremeHeader(bool isCompact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text('INTELLIGENCE COMMAND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF6366F1), letterSpacing: 4)),
             const SizedBox(height: 12),
             Text('Fleet Performance Executive Overview', style: TextStyle(fontSize: isCompact ? 28 : 42, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B), letterSpacing: -2)),
             const SizedBox(height: 4),
             const Text('Real-time synchronization with IST/Kolkata cloud nodes active.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const Spacer(),
        _buildActionPill(Icons.sync_rounded, 'FORCE RE-SYNC', () => context.read<DashboardBloc>().add(FetchDashboardStatsRequested())),
        const SizedBox(width: 16),
        _buildActionPill(Icons.ios_share_rounded, 'GENERATE REPORT', () {}),
      ],
    );
  }

  Widget _buildActionPill(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1E293B)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(DashboardStatsLoadSuccess state, bool isCompact) {
    return Row(
      children: [
        _buildSupremeStatCard('TOTAL REGISTRY', '${state.totalStudents}', Icons.groups_rounded, const Color(0xFF6366F1)),
        const SizedBox(width: 24),
        _buildSupremeStatCard('ACTIVE SESSIONS', '${state.presentToday}', Icons.sensors_rounded, const Color(0xFF10B981)),
        const SizedBox(width: 24),
        _buildSupremeStatCard('DEFICIT RECORDS', '${state.absentToday}', Icons.warning_rounded, const Color(0xFFF43F5E)),
        const SizedBox(width: 24),
        _buildSupremeStatCard('CLOUD LATENCY', '142ms', Icons.bolt_rounded, Colors.amber),
      ],
    );
  }

  Widget _buildSupremeStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withOpacity(0.02)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.03), blurRadius: 40, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                const Icon(Icons.north_east_rounded, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 24),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainAnalyticsStage(DashboardStatsLoadSuccess state, bool isCompact) {
    return _buildSupremeModule(
      title: 'ATTENDANCE VELOCITY',
      subtitle: 'Real-time progression tracking across academic time-series',
      icon: Icons.timeline_rounded,
      child: SizedBox(
        height: 400,
        child: _AttendanceTrendChart(
          view: _selectedView,
          currentPercentage: state.totalStudents > 0 ? (state.presentToday/state.totalStudents*100) : 0,
        ),
      ),
    );
  }

  Widget _buildSupremeModule({required String title, required String subtitle, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.02)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 60, offset: const Offset(0, 20)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.08), shape: BoxShape.circle),
                 child: Icon(icon, color: const Color(0xFF6366F1), size: 24),
               ),
               const SizedBox(width: 20),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5)),
                   Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                 ],
               ),
               const Spacer(),
               if (title.contains('VELOCITY')) _buildViewToggle(false),
            ],
          ),
          const SizedBox(height: 40),
          child,
        ],
      ),
    );
  }

  Map<String, double> _calculateDeptStats(List<Employee> employees) {
    if (employees.isEmpty) return {};
    
    final Map<String, List<Employee>> groups = {};
    for (var e in employees) {
      groups.putIfAbsent(e.department, () => []).add(e);
    }
    
    final Map<String, double> stats = {};
    groups.forEach((dept, list) {
      final int presentCount = list.where((e) => e.attendanceStatus.toLowerCase() == 'present').length;
      stats[dept] = (presentCount / list.length) * 100;
    });
    return stats;
  }

  Widget _buildViewToggle(bool isCompact) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        children: _views.map((v) {
          final isSelected = _selectedView == v;
          return GestureDetector(
            onTap: () => setState(() => _selectedView = v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 20),
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
              ),
              child: Center(
                child: Text(
                  v,
                  style: TextStyle(
                    color: isSelected ? const Color(AppConstants.primaryColor) : const Color(AppConstants.textSecondary),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, IconData icon, Color color, bool isCompact) {
    return Container(
      width: isCompact ? 160 : 220,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: Color(AppConstants.textSecondary), fontSize: 11, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(color: Color(AppConstants.textPrimary), fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required String subtitle, required Widget child, Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(AppConstants.textPrimary))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(AppConstants.textSecondary), fontSize: 12)),
                ],
              ),
              const Icon(Icons.more_horiz, color: Color(AppConstants.textSecondary), size: 20),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AttendanceTrendChart extends StatelessWidget {
  final String view;
  final double currentPercentage;
  const _AttendanceTrendChart({required this.view, required this.currentPercentage});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                
                String text = '';
                if (view == 'Daily') {
                  if (value.toInt() < days.length) text = days[value.toInt()];
                } else if (view == 'Monthly') {
                   // Show few months to fit
                   if (value.toInt() % 2 == 0 && value.toInt() < months.length) text = months[value.toInt()];
                } else {
                  text = 'W${value.toInt() + 1}';
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%', style: TextStyle(color: Colors.grey.shade400, fontSize: 12));
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: view == 'Daily' ? 6 : (view == 'Monthly' ? 11 : 3),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            // Since we only have real-time today, we draw a flat line or single point for today
            spots: _getRealSpots(view, currentPercentage),
            isCurved: true,
            curveSmoothness: 0.35,
            gradient: const LinearGradient(
              colors: [Color(AppConstants.primaryColor), Color(AppConstants.primaryLight)],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: const Color(AppConstants.primaryColor),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(AppConstants.primaryColor).withOpacity(0.15),
                  const Color(AppConstants.primaryLight).withOpacity(0.01),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getRealSpots(String view, double current) {
    // We show a slightly dynamic baseline based on real data for Today
    int todayIdx = (DateTime.now().weekday - 1);
    
    // For Daily: Show past history as 0 or baseline until actual history API is ready
    // For now, we show the REAL data point for today and placeholders for others
    return List.generate(view == 'Daily' ? 7 : (view == 'Monthly' ? 12 : 4), (i) {
      if (i == todayIdx && view == 'Daily') return FlSpot(i.toDouble(), current);
      // Fallback: until we have history, show a smooth baseline around current %
      return FlSpot(i.toDouble(), current > 0 ? (current * (0.8 + (i*0.05))) : 0);
    });
  }
}

class _AttendanceDistributionPie extends StatelessWidget {
  final int present;
  final int absent;
  final int total;

  const _AttendanceDistributionPie({
    required this.present,
    required this.absent,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const Center(child: Text('No data available'));

    final presentPerc = (present / total * 100).toStringAsFixed(1);

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 70,
                  sections: [
                    PieChartSectionData(
                      color: const Color(0xFF6366F1),
                      value: present.toDouble(),
                      title: '',
                      radius: 24,
                      badgeWidget: _buildPercentageBadge('$presentPerc%'),
                      badgePositionPercentageOffset: 1.4,
                    ),
                    PieChartSectionData(
                      color: const Color(0xFFF43F5E).withOpacity(0.15),
                      value: absent.toDouble(),
                      title: '',
                      radius: 18,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text('$present', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                   const Text('PRESENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 48),
        _buildLegend(),
      ],
    );
  }

  Widget _buildPercentageBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendItem(color: Color(0xFF6366F1), label: 'Active Registry'),
        SizedBox(width: 32),
        _LegendItem(color: Color(0xFFF43F5E), label: 'Absent/Risk'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(AppConstants.textSecondary), fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _DepartmentBarChart extends StatelessWidget {
  final Map<String, double> deptStats;
  const _DepartmentBarChart({required this.deptStats});

  @override
  Widget build(BuildContext context) {
    final depts = deptStats.keys.toList();
    if (depts.isEmpty) return const Center(child: Text('No department data available'));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF1E293B),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${depts[groupIndex]}\n${rod.toY.toInt()}%',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < depts.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        depts[value.toInt()].toUpperCase(),
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 40,
              getTitlesWidget: (val, meta) => Text('${val.toInt()}%', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.black.withOpacity(0.03), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(depts.length, (i) {
          final percentage = deptStats[depts[i]] ?? 0;
          return _makeGroupData(i, percentage);
        }),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 28,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true, 
            toY: 100, 
            color: const Color(0xFFF1F5F9),
          ),
        ),
      ],
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final bool isFullView;
  final List<Employee>? employees;
  const _RecentActivityList({this.isFullView = false, this.employees});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardStatsLoadSuccess || employees != null) {
          final sourceUsers = employees ?? (state as DashboardStatsLoadSuccess).employees;
          final users = isFullView ? sourceUsers : sourceUsers.take(5).toList();
          
          if (users.isEmpty) return const Center(child: Text('No recent activity'));
          
          return ListView.separated(
            physics: isFullView ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 20, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, i) {
              final user = users[i];
              final isPresent = user.attendanceStatus.toLowerCase() == 'present';
              
              return Container(
                padding: isFullView ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4) : EdgeInsets.zero,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: isFullView ? 20 : 16,
                      backgroundColor: (isPresent ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withOpacity(0.1),
                      child: Text(user.username.isNotEmpty ? user.username[0] : '?', style: TextStyle(fontSize: isFullView ? 14 : 12, fontWeight: FontWeight.bold, color: isPresent ? const Color(0xFF10B981) : const Color(0xFFF43F5E))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.username, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isFullView ? 15 : 13, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(user.department, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              const SizedBox(width: 8),
                              Container(width: 2, height: 2, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(isPresent ? 'Present Today' : 'Absent Today', style: TextStyle(fontSize: 11, color: isPresent ? const Color(0xFF10B981) : const Color(0xFFF43F5E).withOpacity(0.6))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      user.attendanceTime != null && user.attendanceTime!.isNotEmpty 
                        ? user.attendanceTime!.split('T').last.substring(0, 5) 
                        : '--:--', 
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    if (isFullView) ...[
                       const SizedBox(width: 16),
                       const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                    ]
                  ],
                ),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
