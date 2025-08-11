import 'package:dm1/auth_manager.dart';
import 'package:dm1/models/driving.dart';
import 'package:dm1/models/user.dart';
import 'package:dm1/pages/exit.dart';
import 'package:dm1/pages/home/widgets/auth_guard.dart';
import 'package:dm1/routes.dart';
import 'package:dm1/services/http/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_navbar.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  DrivingTotalCount? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfileAndStats();
  }

  Future<void> _loadProfileAndStats() async {
    final authManager = context.read<AuthManager>();
    final httpService = HttpService();

    try {
      final userProfile = await authManager.getUserProfile();

      final token = await authManager.getAccessToken();
      final drivingStatsResp = await httpService.getDrivingStatistics(token);

      setState(() {
        _user = userProfile;
        _stats = drivingStatsResp.success;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitWrapper(
      child: AuthGuard(
        child: PopScope(
          canPop: true, 
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) {
              SystemNavigator.pop(); 
            } 
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('프로필'),
              centerTitle: true,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    //logic
                  },
                ),
              ],
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('오류 발생: $_error'))
                    : _user == null
                        ? const Center(child: Text('사용자 정보를 불러올 수 없습니다'))
                        : _buildProfileContent(),
            bottomNavigationBar: const BottomNavBar(selectedIndex: 3),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, size: 60, color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  _user!.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(_user!.email),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileItem(
                      Icons.date_range,
                      '가입일',
                      _user!.createdAt.toString().split(' ').first),
                  const Divider(),
                  _buildProfileItem(
                      Icons.update,
                      '마지막 수정일',
                      _user!.updatedAt.toString().split(' ').first),
                  const Divider(),
                  _buildProfileItem(
                      Icons.directions_car,
                      '총 주행 거리',
                      _stats != null
                          ? '${_stats!.totalDistance.toStringAsFixed(1)} km'
                          : '0 km'),
                  const Divider(),
                  _buildProfileItem(
                      Icons.list_alt,
                      '총 주행 횟수',
                      _stats != null ? '${_stats!.count}회' : '0회'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuButton('운전 설정', Icons.settings_applications),
          _buildMenuButton('알림 설정', Icons.notifications),
          _buildMenuButton('도움말', Icons.help),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 17, 9, 107)),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String text, IconData icon,
      {Color color = Colors.black}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black),
      onTap: () {
        // menulogic
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.exit_to_app, color: Colors.red),
      title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
      trailing: const Icon(Icons.chevron_right, color: Colors.red),
      onTap: () => _showLogoutConfirmation(context),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃 확인'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performLogout(context);
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    final authManager = context.read<AuthManager>();
    try {
      await authManager.logout();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 실패: ${e.toString()}')),
      );
    }
  }
}
