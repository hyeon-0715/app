import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'main_page.dart';
import 'user_state.dart';
import '../utils/permission_helper.dart';
import '../utils/dialog_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  bool isHovered = false;
  bool isBackHovered = false;

  final TextEditingController _loginIdController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  final TextEditingController _signupIdController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _signupConfirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _loginIdController.dispose();
    _loginPasswordController.dispose();
    _signupIdController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  bool get _isLoginButtonEnabled {
    return _loginIdController.text.isNotEmpty && _loginPasswordController.text.isNotEmpty;
  }

  bool get _isSignupButtonEnabled {
    return _signupIdController.text.isNotEmpty &&
        _signupPasswordController.text.isNotEmpty &&
        _signupConfirmPasswordController.text.isNotEmpty &&
        _signupPasswordController.text == _signupConfirmPasswordController.text;
  }

  Future<void> _navigateToMainPage() async {
    bool allPermissionsGranted = await PermissionHelper.checkPermissions();
    if (!allPermissionsGranted) {
      await PermissionHelper.requestPermissions(context);
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/void.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 255, 243, 223),
              Color.fromARGB(255, 85, 81, 74),
            ],
          ),
          color: Color(0xFFF5F5DC),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Center(
                child: Text(
                  'kimchida',
                  style: TextStyle(
                    fontSize: 60 * widthRatio,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 780 * widthRatio,
                padding: EdgeInsets.all(40 * widthRatio),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5DC),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: isLogin ? _buildLoginContainer(widthRatio, heightRatio) : _buildSignupContainer(widthRatio, heightRatio),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginContainer(double widthRatio, double heightRatio) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '로그인',
          style: TextStyle(
            fontSize: 48 * widthRatio,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 40 * heightRatio),
        TextField(
          controller: _loginIdController,
          decoration: InputDecoration(
            hintText: '아이디',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 36 * widthRatio),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20 * widthRatio,
              vertical: 20 * heightRatio,
            ),
          ),
          style: TextStyle(fontSize: 36 * widthRatio),
          onChanged: (value) {
            setState(() {});
          },
        ),
        SizedBox(height: 20 * heightRatio),
        TextField(
          controller: _loginPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: '비밀번호',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 36 * widthRatio),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20 * widthRatio,
              vertical: 20 * heightRatio,
            ),
          ),
          style: TextStyle(fontSize: 36 * widthRatio),
          onChanged: (value) {
            setState(() {});
          },
        ),
        SizedBox(height: 40 * heightRatio),
        Center(
          child: SizedBox(
            width: 780 * widthRatio * 0.7,
            child: ElevatedButton(
              onPressed: _isLoginButtonEnabled
                  ? () async {
                      Provider.of<UserState>(context, listen: false).login(_loginIdController.text);
                      await _navigateToMainPage();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoginButtonEnabled ? Colors.green : Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '로그인',
                style: TextStyle(
                  fontSize: 36 * widthRatio,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20 * heightRatio),
        Center(
          child: SizedBox(
            width: 780 * widthRatio * 0.7,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  isLogin = false;
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '회원가입',
                style: TextStyle(
                  fontSize: 36 * widthRatio,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20 * heightRatio),
        Center(
          child: MouseRegion(
            onEnter: (_) {
              setState(() {
                isHovered = true;
              });
            },
            onExit: (_) {
              setState(() {
                isHovered = false;
              });
            },
            child: GestureDetector(
              onTap: () {
                Provider.of<UserState>(context, listen: false).logout();
                _navigateToMainPage();
              },
              child: Text(
                '나중에 로그인하기',
                style: TextStyle(
                  fontSize: 24 * widthRatio,
                  color: isHovered ? Colors.green : Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupContainer(double widthRatio, double heightRatio) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '회원가입',
          style: TextStyle(
            fontSize: 48 * widthRatio,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 40 * heightRatio),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _signupIdController,
                decoration: InputDecoration(
                  hintText: '아이디',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 36 * widthRatio),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20 * widthRatio,
                    vertical: 20 * heightRatio,
                  ),
                ),
                style: TextStyle(fontSize: 36 * widthRatio),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            SizedBox(width: 20 * widthRatio),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * widthRatio,
                  vertical: 20 * heightRatio,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '중복확인',
                style: TextStyle(
                  fontSize: 24 * widthRatio,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 60 * heightRatio),
        TextField(
          controller: _signupPasswordController,
          obscureText: true,
          obscuringCharacter: '*',
          decoration: InputDecoration(
            hintText: '비밀번호',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 36 * widthRatio),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20 * widthRatio,
              vertical: 20 * heightRatio,
            ),
          ),
          style: TextStyle(fontSize: 36 * widthRatio),
          onChanged: (value) {
            setState(() {});
          },
        ),
        SizedBox(height: 20 * heightRatio),
        TextField(
          controller: _signupConfirmPasswordController,
          obscureText: true,
          obscuringCharacter: '*',
          decoration: InputDecoration(
            hintText: '비밀번호 확인',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 36 * widthRatio),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20 * widthRatio,
              vertical: 20 * heightRatio,
            ),
          ),
          style: TextStyle(fontSize: 36 * widthRatio),
          onChanged: (value) {
            setState(() {});
          },
        ),
        SizedBox(height: 40 * heightRatio),
        Center(
          child: SizedBox(
            width: 780 * widthRatio * 0.7,
            child: ElevatedButton(
              onPressed: _isSignupButtonEnabled
                  ? () {
                      setState(() {
                        isLogin = true;
                        _signupIdController.clear();
                        _signupPasswordController.clear();
                        _signupConfirmPasswordController.clear();
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSignupButtonEnabled ? Colors.green : Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                '회원가입',
                style: TextStyle(
                  fontSize: 36 * widthRatio,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20 * heightRatio),
        Center(
          child: MouseRegion(
            onEnter: (_) {
              setState(() {
                isBackHovered = true;
              });
            },
            onExit: (_) {
              setState(() {
                isBackHovered = false;
              });
            },
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isLogin = true;
                });
              },
              child: Text(
                '이전으로',
                style: TextStyle(
                  fontSize: 24 * widthRatio,
                  color: isBackHovered ? Colors.green : Colors.black,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}