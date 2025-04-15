import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dialog_helper.dart';

class PermissionHelper {
  static final ImagePicker _picker = ImagePicker();

  // 권한 상태 확인
  static Future<bool> checkPermissions() async {
    bool galleryGranted = await Permission.photos.isGranted;
    bool cameraGranted = await Permission.camera.isGranted;
    return galleryGranted && cameraGranted;
  }

  // 권한 요청
  static Future<bool> requestPermissions(BuildContext context, {VoidCallback? onPermissionsGranted}) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        PermissionStatus galleryStatus = await Permission.photos.status;
        PermissionStatus cameraStatus = await Permission.camera.status;

        if (!galleryStatus.isGranted || !cameraStatus.isGranted) {
          if (!galleryStatus.isGranted) {
            if (galleryStatus.isPermanentlyDenied) {
              await _showOpenSettingsDialog(context, '갤러리', onPermissionsGranted: onPermissionsGranted);
              return false;
            }
            galleryStatus = await Permission.photos.request();
          }

          if (!cameraStatus.isGranted) {
            if (cameraStatus.isPermanentlyDenied) {
              await _showOpenSettingsDialog(context, '카메라', onPermissionsGranted: onPermissionsGranted);
              return false;
            }
            cameraStatus = await Permission.camera.request();
          }

          if (galleryStatus.isGranted && cameraStatus.isGranted) {
            if (onPermissionsGranted != null) {
              onPermissionsGranted();
            }
            return true;
          } else if (galleryStatus.isPermanentlyDenied || cameraStatus.isPermanentlyDenied) {
            await _showOpenSettingsDialog(
              context,
              galleryStatus.isPermanentlyDenied ? '갤러리' : '카메라',
              onPermissionsGranted: onPermissionsGranted,
            );
            return false;
          } else {
            await _showPermissionDeniedDialog(context, onPermissionsGranted: onPermissionsGranted);
            return false;
          }
        }
        return true; // 권한이 이미 모두 부여된 경우
      }
      return false;
    } catch (e) {
      print('Error during permission request: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('권한 요청 중 오류 발생: $e')),
        );
      }
      return false;
    }
  }

  // 권한 요청 다이얼로그 표시
  static Future<void> _showPermissionDialog(BuildContext context, {VoidCallback? onPermissionsGranted}) async {
    await DialogHelper.showCustomDialog(
      context: context,
      title: '앱을 원활하게 사용하기 위해서는\n다음 권한을 설정해야 합니다.',
      confirmText: '확인',
      onConfirm: () async {
        await requestPermissions(context, onPermissionsGranted: onPermissionsGranted);
      },
    );
  }

  // 권한 거부 시 다이얼로그 표시
  static Future<void> _showPermissionDeniedDialog(BuildContext context, {VoidCallback? onPermissionsGranted}) async {
    await DialogHelper.showCustomDialog(
      context: context,
      title: '권한이 거부되었습니다.\n앱을 원활하게 사용하려면 권한을 허용해 주세요.',
      confirmText: '다시 시도',
      cancelText: '취소',
      onConfirm: () async {
        await requestPermissions(context, onPermissionsGranted: onPermissionsGranted);
      },
      onCancel: () {},
    );
  }

  // 영구 거부 시 설정으로 유도
  static Future<void> _showOpenSettingsDialog(
    BuildContext context,
    String permissionType, {
    VoidCallback? onPermissionsGranted,
    ImageSource? onImageSource,
    Function(XFile?)? onImagePicked,
  }) async {
    await DialogHelper.showCustomDialog(
      context: context,
      title: '$permissionType 권한이 영구적으로 거부되었습니다.\n설정에서 권한을 허용해 주세요.',
      confirmText: '설정으로 이동',
      onConfirm: () async {
        await openAppSettings();
        Permission permission = permissionType == '갤러리' ? Permission.photos : Permission.camera;
        PermissionStatus status = await permission.status;
        if (status.isGranted && context.mounted) {
          if (onImageSource != null && onImagePicked != null) {
            XFile? image = await pickImage(context, onImageSource);
            onImagePicked(image);
          } else if (onPermissionsGranted != null) {
            onPermissionsGranted();
          }
        } else if (context.mounted) {
          if (onImageSource != null) {
            await showPermissionDeniedDialogForImage(context, permissionType, onImageSource, onImagePicked);
          } else {
            await _showPermissionDeniedDialog(context, onPermissionsGranted: onPermissionsGranted);
          }
        }
      },
    );
  }

  // 이미지 선택 옵션 다이얼로그 표시
  static Future<void> showImageSourceDialog(
    BuildContext context, {
    required Function(ImageSource, String) onImageSourceSelected,
  }) async {
    await DialogHelper.showCustomDialog(
      context: context,
      title: '사진 선택',
      subtitle: '사진을 선택할 방법을 선택하세요.',
      confirmText: '갤러리',
      cancelText: '카메라',
      extraButtonText: '취소',
      onConfirm: () {
        onImageSourceSelected(ImageSource.gallery, '갤러리');
      },
      onCancel: () {
        onImageSourceSelected(ImageSource.camera, '카메라');
      },
      onExtra: () {},
      showTwoButtons: true,
    );
  }

  // 이미지 선택
  static Future<XFile?> pickImage(BuildContext context, ImageSource source, {Function(XFile?)? onImagePicked}) async {
    String permissionType = source == ImageSource.gallery ? '갤러리' : '카메라';
    Permission permission = source == ImageSource.gallery ? Permission.photos : Permission.camera;

    PermissionStatus status = await permission.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      if (status.isPermanentlyDenied) {
        await _showOpenSettingsDialog(
          context,
          permissionType,
          onImageSource: source,
          onImagePicked: onImagePicked,
        );
        return null;
      }
      status = await permission.request();

      if (status.isDenied) {
        await showPermissionDeniedDialogForImage(context, permissionType, source, onImagePicked);
        return null;
      } else if (status.isPermanentlyDenied) {
        await _showOpenSettingsDialog(
          context,
          permissionType,
          onImageSource: source,
          onImagePicked: onImagePicked,
        );
        return null;
      }
    }

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진이 선택되었습니다: ${image.path}')),
        );
        if (onImagePicked != null) {
          onImagePicked(image);
        }
      }
      return image;
    } catch (e) {
      print('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류 발생: $e')),
        );
      }
      return null;
    }
  }

  // 이미지 선택용 권한 거부 다이얼로그 표시
  static Future<void> showPermissionDeniedDialogForImage(
    BuildContext context,
    String permissionType,
    ImageSource source, [
    Function(XFile?)? onImagePicked,
  ]) async {
    await DialogHelper.showCustomDialog(
      context: context,
      title: '$permissionType 권한이 거부되었습니다.\n앱을 원활하게 사용하려면 권한을 허용해 주세요.',
      confirmText: '다시 시도',
      cancelText: '취소',
      onConfirm: () async {
        XFile? image = await pickImage(context, source, onImagePicked: onImagePicked);
        if (onImagePicked != null && image != null) {
          onImagePicked(image);
        }
      },
      onCancel: () {},
    );
  }
}