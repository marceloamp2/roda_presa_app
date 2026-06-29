import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  Future<void> checkForImmediateUpdate() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (_shouldStartImmediateUpdate(updateInfo)) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (error, stackTrace) {
      debugPrint('Immediate app update check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  bool _shouldStartImmediateUpdate(AppUpdateInfo updateInfo) {
    if (updateInfo.updateAvailability ==
        UpdateAvailability.developerTriggeredUpdateInProgress) {
      return true;
    }

    return updateInfo.updateAvailability ==
            UpdateAvailability.updateAvailable &&
        updateInfo.immediateUpdateAllowed;
  }
}
