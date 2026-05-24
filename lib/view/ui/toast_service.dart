import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastService {
  static void success(
    String title, {
    String? description,
    BuildContext? context,
    Duration autoCloseDuration = const Duration(seconds: 2),
  }) {
    show(
      title: title,
      description: description,
      context: context,
      type: ToastificationType.success,
      autoCloseDuration: autoCloseDuration,
    );
  }

  static void info(
    String title, {
    String? description,
    BuildContext? context,
    Duration autoCloseDuration = const Duration(seconds: 2),
  }) {
    show(
      title: title,
      description: description,
      context: context,
      type: ToastificationType.info,
      autoCloseDuration: autoCloseDuration,
    );
  }

  static void warning(
    String title, {
    String? description,
    BuildContext? context,
    Duration autoCloseDuration = const Duration(seconds: 3),
  }) {
    show(
      title: title,
      description: description,
      context: context,
      type: ToastificationType.warning,
      autoCloseDuration: autoCloseDuration,
    );
  }

  static void error(
    String title, {
    String? description,
    BuildContext? context,
    Duration autoCloseDuration = const Duration(seconds: 5),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      title: title,
      description: description,
      context: context,
      type: ToastificationType.error,
      autoCloseDuration: autoCloseDuration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void show({
    required String title,
    String? description,
    required ToastificationType type,
    BuildContext? context,
    Duration autoCloseDuration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    toastification.show(
      context: context,
      alignment: Alignment.bottomRight,
      type: type,
      style: ToastificationStyle.flatColored,
      showProgressBar: false,
      autoCloseDuration: autoCloseDuration,
      title: Text(title),
      description: _buildDescription(
        description: description,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }

  static Widget? _buildDescription({
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (description == null && (actionLabel == null || onAction == null)) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (description != null) Text(description),
        if (actionLabel != null && onAction != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: onAction, child: Text(actionLabel)),
          ),
      ],
    );
  }
}
