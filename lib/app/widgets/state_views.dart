import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../constants/app_icons.dart';
import '../constants/constants.dart';
import '../data/api_client.dart';
import '../data/auth_service.dart';
import '../data/strings.dart';

/// Loading, empty and error are three different states, and the spec insists
/// they stay different: an empty answer is not a failure, and a failure is
/// never a zero.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 16 : 48),
        child: Center(
          child: Lottie.asset(
            'assets/lottie/loading.json',
            width: compact ? 64 : 120,
            height: compact ? 64 : 120,
            errorBuilder: (_, __, ___) => const CircularProgressIndicator(
              color: kPrimaryColor,
              strokeWidth: 2,
            ),
          ),
        ),
      );
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.title, this.message});

  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/noData.json',
              width: 140,
              height: 140,
              repeat: false,
              errorBuilder: (_, __, ___) =>
                  const AppIcon(AppIcons.empty, size: 48, color: kMutedColor),
            ),
            const SizedBox(height: 12),
            Text(
              title ?? S.noRecords,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: gilroySemiBold,
                fontSize: 17,
                color: kBlackColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message ?? S.nothingForPeriod,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 14,
                color: kMutedColor,
              ),
            ),
          ],
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error is ApiException ? (error as ApiException).failure : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failure == ApiFailure.network)
            Image.asset('assets/icons/noconnection.gif',
                width: 120,
                height: 120,
                errorBuilder: (_, __, ___) => const AppIcon(AppIcons.warning,
                    size: 44, color: kNegativeColor))
          else
            const AppIcon(AppIcons.warning, size: 44, color: kNegativeColor),
          const SizedBox(height: 12),
          Text(
            errorTitle(error),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: gilroySemiBold,
              fontSize: 17,
              color: kBlackColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            errorMessage(error),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: gilroyRegular,
              fontSize: 14,
              color: kMutedColor,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const AppIcon(AppIcons.refresh, size: 18),
              label: Text(
                S.retry,
                style: const TextStyle(fontFamily: gilroySemiBold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A failure is never turned into a number. Each documented code says
/// something different to the person holding the phone.
String errorTitle(Object error) {
  if (error is WrongRoleException) return S.errNoAccess;
  if (error is! ApiException) return S.errLoad;
  return switch (error.failure) {
    ApiFailure.badRequest => S.errBadRequest,
    ApiFailure.unauthorized => S.errSession,
    ApiFailure.forbidden => S.errNoAccess,
    ApiFailure.notFound => S.errNotFound,
    ApiFailure.conflict => S.errConflict,
    ApiFailure.network => S.errNetwork,
    ApiFailure.server => S.errServer,
  };
}

String errorMessage(Object error) {
  if (error is WrongRoleException) return S.msgWrongRole;
  if (error is! ApiException) return S.msgTryAgain;
  final server = error.serverMessage;
  if (server != null && server.trim().isNotEmpty) return server.trim();
  return switch (error.failure) {
    ApiFailure.badRequest => S.msgBadRequest,
    ApiFailure.unauthorized => S.msgSession,
    ApiFailure.forbidden => S.msgForbidden,
    ApiFailure.notFound => S.msgNotFound,
    ApiFailure.conflict => S.msgConflict,
    ApiFailure.network => S.msgNetwork,
    ApiFailure.server => S.msgServer,
  };
}
