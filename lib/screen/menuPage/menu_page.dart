import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:torudex/screen/groupPage/create_group.dart';
import 'package:torudex/screen/groupPage/group_screen.dart';
import 'package:torudex/screen/menuPage/pomodoro/pomodoro_page.dart';
import 'package:torudex/screen/menuPage/setting/darkmode_settings_screen.dart';
import 'package:torudex/screen/menuPage/setting/helpCenter/help_center.dart';
import 'package:torudex/screen/menuPage/setting/privacy_settings_screen.dart';
import 'package:torudex/screen/menuPage/setting/helpCenter/help_center.dart';
import 'package:torudex/screen/searchPage/search_user_page.dart';
import '../../api/user_apis.dart';
import 'setting/privacy_settings_screen.dart';

import '../../models/user_info_model.dart';
import '../startPage/intro.dart';
import '../userPage/profile_page.dart';
import 'notes/note_page.dart';

import 'package:provider/provider.dart';
import 'package:torudex/theme/theme.dart';
import 'package:torudex/theme/theme_provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final user = FirebaseAuth.instance.currentUser;

  User? firebaseUser;
  String username = "Đang tải...";
  String email = "";
  String avatarUrl = "";
  bool isGoogleSignIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) return;

    // Lấy dữ liệu từ Firestore trước
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser!.uid)
            .get();

    // Kiểm tra nếu user đăng nhập bằng Google
    bool isGoogleUser = false;
    for (var info in firebaseUser!.providerData) {
      if (info.providerId == 'google.com') {
        isGoogleUser = true;
        break;
      }
    }

    setState(() {
      isGoogleSignIn = isGoogleUser;

      if (snapshot.exists) {
        final data = snapshot.data();
        // Ưu tiên dữ liệu từ Firestore
        username =
            data?['username'] ?? firebaseUser?.displayName ?? "Không có tên";
        avatarUrl = data?['avatarUrl'] ?? firebaseUser?.photoURL ?? "";
        email = data?['email'] ?? firebaseUser?.email ?? "";
      } else {
        // Fallback về dữ liệu từ FirebaseAuth
        username = firebaseUser?.displayName ?? "Không có tên";
        avatarUrl = firebaseUser?.photoURL ?? "";
        email = firebaseUser?.email ?? "";
      }
    });
  }

  Future<void> removeFcmTokenFromFirestore(String uid) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      final usersRef = FirebaseFirestore.instance.collection('users');
      await usersRef.doc(uid).update({
        'fcmTokens': FieldValue.arrayRemove([fcmToken]),
      });
    }
  }

  signOut() async {
    APIs.updateActiveStatus(false);
    await FirebaseAuth.instance.signOut();
    await removeFcmTokenFromFirestore(user!.uid);
    // Đăng xuất Google nếu có đăng nhập bằng Google
    Get.offAll(() => const IntroScreen());
    await GoogleSignIn().signOut();
  }

  void _showSettingsMenu(bool isDarkMode) {
    showMenu(
      color: AppBackgroundStyles.modalBackground(isDarkMode),
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 50,
        kToolbarHeight + MediaQuery.of(context).padding.top,
        0,
        0,
      ),
      items: [
        PopupMenuItem(
          value: 'setting_privacy',
          child: Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: AppTextStyles.buttonTextColor(isDarkMode),
              ),
              const SizedBox(width: 10),
              Text(
                'Chỉnh sửa quyền riêng tư',
                style: TextStyle(
                  color: AppTextStyles.buttonTextColor(isDarkMode),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'setting_darkmode',
          child: Row(
            children: [
              Icon(
                Icons.mode_night_outlined,
                color: AppTextStyles.buttonTextColor(isDarkMode),
              ),
              const SizedBox(width: 10),
              Text(
                'Chế độ tối',
                style: TextStyle(
                  color: AppTextStyles.buttonTextColor(isDarkMode),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: AppTextStyles.buttonTextColor(isDarkMode),
              ),
              const SizedBox(width: 10),
              Text(
                'Đăng xuất',
                style: TextStyle(
                  color: AppTextStyles.buttonTextColor(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'setting_privacy') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PrivacySettingsScreen()),
        );
      } else if (value == 'setting_darkmode') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DarkmodeSettingsScreen()),
        );
      } else if (value == 'logout') {
        _showLogoutDialog(isDarkMode);
      }
    });
  }

  void _showLogoutDialog(bool isDarkMode) {
    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            backgroundColor: AppBackgroundStyles.modalBackground(isDarkMode),
            title: Text('Đăng xuất', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
            content: Text('Bạn có chắc chắn muốn đăng xuất không?', style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode))),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Hủy', style: TextStyle(color: AppTextStyles.subTextColor(isDarkMode))),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppBackgroundStyles.buttonBackground(isDarkMode),
                ),
                child: Text(
                  'Đăng xuất',
                  style: TextStyle(color: AppTextStyles.buttonTextColor(isDarkMode)),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppBackgroundStyles.mainBackground(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppBackgroundStyles.secondaryBackground(isDarkMode),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        title: Row(
          children: [
            Text("Menu", style: TextStyle(color: AppTextStyles.normalTextColor(isDarkMode), fontSize: 25, fontWeight: FontWeight.bold)),
            // Expanded(
            //   child: Center(
            //     child: Image.asset("assets/ToruDex_logo.png", height: 50),
            //   ),
            // ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: () {
                _showSettingsMenu(isDarkMode);
              },
              icon: Icon(
                Icons.settings,
                color: AppTextStyles.buttonTextColor(isDarkMode),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: AppTextStyles.buttonTextColor(isDarkMode).withOpacity(0.2),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppBackgroundStyles.buttonBackground(isDarkMode),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // màu bóng đổ
                      blurRadius: 8, // độ mờ của bóng
                      offset: Offset(0, 4), // vị trí đổ bóng (x: ngang, y: dọc)
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final userInfo = UserInfoModel(
                            username: username,
                            email: email,
                            avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
                            followers: [],
                          );

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(user: userInfo),
                            ),
                          );

                          // Nếu có cập nhật, thì reload lại dữ liệu người dùng
                          if (result == true) {
                            _loadUserInfo();
                          }
                        },

                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              // CircleAvatar(
                              //   backgroundImage: NetworkImage(
                              //     avatarUrl.isNotEmpty
                              //         ? avatarUrl
                              //         : "https://example.com/default_avatar.png",
                              //   ),

                              //   radius: 20,
                              // ),
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: (avatarUrl != null &&
                                        avatarUrl!.isNotEmpty)
                                    ? NetworkImage(avatarUrl!)
                                    : const AssetImage("assets/avatar.png") as ImageProvider,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  username,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTextStyles.buttonTextColor(
                                      isDarkMode,
                                    ),
                                  ),
                                ),
                              ),
                              // Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // SizedBox(height: 8),
                    // Container(
                    //   width: double.infinity,
                    //   height: 1,
                    //   color: AppTextStyles.buttonTextColor(isDarkMode),
                    // ),
                    // SizedBox(height: 6),
                    // Row(
                    //   children: [
                    //     Icon(Icons.add, size: 20, color: AppTextStyles.buttonTextColor(isDarkMode),),
                    //     SizedBox(width: 4),
                    //     Text(
                    //       "Đăng nhập với tài khoản khác",
                    //       style: TextStyle(
                    //                 color: AppTextStyles.buttonTextColor(isDarkMode),
                    //               ),
                    //       ),
                    //   ],
                    // ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _showLogoutDialog(isDarkMode);
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppBackgroundStyles.buttonBackground(
                      isDarkMode,
                    ),
                    minimumSize: Size(500, 40),
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Đăng xuất",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTextStyles.buttonTextColor(isDarkMode),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
