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

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(FetchDashboardStatsRequested());
  }

  String _selectedView = 'Daily';
  final List<String> _views = ['Daily', 'Weekly', 'Monthly'];

  String _displayMode = 'Overview';
  final List<String> _displayModes = ['Overview', 'Graphs', 'Distribution', 'Activity Log'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1100;
        final horizontalPadding = isCompact ? 24.0 : 40.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricStrip(isCompact),
              const SizedBox(height: 32),
              Center(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildDisplayModeTabs(isCompact),
                    _buildViewToggle(isCompact),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SizedBox.expand(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.00, 0.05),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      );
                    },
                    child: _buildBodyContent(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisplayModeTabs(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        children: _displayModes.map((mode) {
          final isSelected = _displayMode == mode;
          return GestureDetector(
            onTap: () => setState(() => _displayMode = mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] : [],
              ),
              child: Text(
                mode,
                style: TextStyle(
                  color: isSelected ? const Color(AppConstants.primaryColor) : const Color(AppConstants.textSecondary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricStrip(bool isCompact) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        int total = 0, present = 0, absent = 0;
        if (state is DashboardStatsLoadSuccess) {
          total = state.totalStudents;
          present = state.presentToday;
          absent = state.absentToday;
        }
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricPill('Total Students', '$total', Icons.people_outline_rounded, const Color(AppConstants.primaryColor), isCompact),
            _buildMetricPill('Present Today', '$present', Icons.check_circle_outline_rounded, const Color(AppConstants.accentColor), isCompact),
            _buildMetricPill('Absent', '$absent', Icons.error_outline_rounded, Colors.redAccent, isCompact),
            _buildMetricPill('Avg. Success', total > 0 ? '${((present/total)*100).toInt()}%' : '0%', Icons.bolt_rounded, Colors.amber, isCompact),
          ],
        );
      },
    );
  }

  Widget _buildBodyContent() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardStatsLoadSuccess) {
          final deptStats = _calculateDeptStats(state.employees);
          
          switch (_displayMode) {
            case 'Graphs':
              return _buildSectionCard(
                key: const ValueKey('graphs'),
                title: 'Department Performance',
                subtitle: '${deptStats.length} departments tracked in real-time',
                child: _DepartmentBarChart(deptStats: deptStats),
              );
            case 'Distribution':
              return _buildSectionCard(
                key: const ValueKey('pie'),
                title: 'Status Distribution',
                subtitle: 'Ratio of present vs absent across categories',
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: _AttendanceDistributionPie(
                      present: state.presentToday,
                      absent: state.absentToday,
                      total: state.totalStudents,
                    ),
                  ),
                ),
              );
            case 'Activity Log':
              return _buildSectionCard(
                key: const ValueKey('list'),
                title: 'Daily Attendance Log',
                subtitle: 'Real-time student check-ins for ${DateTime.now().toLocal().toString().split(' ')[0]}',
                child: const _RecentActivityList(isFullView: true),
              );
            default: // Overview
              return _buildSectionCard(
                key: const ValueKey('overview'),
                title: 'Live Attendance Snapshot',
                subtitle: 'Today\'s performance: ${state.totalStudents > 0 ? (state.presentToday/state.totalStudents*100).toInt() : 0}% success rate',
                child: _AttendanceTrendChart(
                  view: _selectedView, 
                  currentPercentage: state.totalStudents > 0 ? (state.presentToday/state.totalStudents*100) : 0,
                ),
              );
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
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

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 55,
              sections: [
                PieChartSectionData(
                  color: const Color(AppConstants.primaryColor),
                  value: present.toDouble(),
                  title: '',
                  radius: 20,
                ),
                PieChartSectionData(
                  color: Colors.redAccent.withOpacity(0.2),
                  value: absent.toDouble(),
                  title: '',
                  radius: 15,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: const Color(AppConstants.primaryColor), label: 'Present'),
        const SizedBox(width: 24),
        _LegendItem(color: Colors.redAccent.withOpacity(0.2), label: 'Absent'),
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
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < depts.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(depts[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(depts.length, (i) {
          final percentage = deptStats[depts[i]] ?? 0;
          return _makeGroupData(i, percentage, const Color(AppConstants.primaryColor));
        }),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: Colors.grey.withOpacity(0.05)),
        ),
      ],
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final bool isFullView;
  const _RecentActivityList({this.isFullView = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardStatsLoadSuccess) {
          final users = isFullView ? state.employees : state.employees.take(5).toList();
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
                      backgroundColor: (isPresent ? const Color(AppConstants.accentColor) : Colors.redAccent).withOpacity(0.1),
                      child: Text(user.username.isNotEmpty ? user.username[0] : '?', style: TextStyle(fontSize: isFullView ? 14 : 12, fontWeight: FontWeight.bold, color: isPresent ? const Color(AppConstants.accentColor) : Colors.redAccent)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.username, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isFullView ? 15 : 13, color: const Color(AppConstants.textPrimary))),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(user.department, style: const TextStyle(fontSize: 10, color: Color(AppConstants.textSecondary))),
                              const SizedBox(width: 8),
                              Container(width: 2, height: 2, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(isPresent ? 'Present Today' : 'Absent Today', style: TextStyle(fontSize: 11, color: isPresent ? const Color(AppConstants.accentColor) : Colors.redAccent.withOpacity(0.6))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text('10:${20+i} AM', style: const TextStyle(fontSize: 11, color: Color(AppConstants.textSecondary))),
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
