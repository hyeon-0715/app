import 'package:flutter/material.dart';

class DialogHelper {
  static Future<void> showCustomDialog({
    required BuildContext context,
    required String title,
    String? subtitle,
    String confirmText = '확인',
    String? cancelText,
    String? extraButtonText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    VoidCallback? onExtra,
    bool showTwoButtons = false,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double baseWidth = 1080;
    const double baseHeight = 2400;
    final widthRatio = screenWidth / baseWidth;
    final heightRatio = screenHeight / baseHeight;

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5E9D6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.all(20 * widthRatio),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 36 * widthRatio,
                  color: Colors.black,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                SizedBox(height: 20 * heightRatio),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 24 * widthRatio,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: 40 * heightRatio),
              if (showTwoButtons)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 150 * widthRatio,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          if (onConfirm != null) onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: TextStyle(
                            fontSize: 24 * widthRatio,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20 * widthRatio),
                    SizedBox(
                      width: 150 * widthRatio,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          if (onCancel != null) onCancel();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          cancelText!,
                          style: TextStyle(
                            fontSize: 24 * widthRatio,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: 300 * widthRatio,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      if (onConfirm != null) onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      confirmText,
                      style: TextStyle(
                        fontSize: 36 * widthRatio,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (cancelText != null && !showTwoButtons) ...[
                SizedBox(height: 20 * heightRatio),
                SizedBox(
                  width: 300 * widthRatio,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      if (onCancel != null) onCancel();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: TextStyle(
                        fontSize: 36 * widthRatio,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
              if (extraButtonText != null) ...[
                SizedBox(height: 20 * heightRatio),
                SizedBox(
                  width: 150 * widthRatio,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      if (onExtra != null) onExtra();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      padding: EdgeInsets.symmetric(vertical: 20 * heightRatio),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      extraButtonText,
                      style: TextStyle(
                        fontSize: 24 * widthRatio,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}