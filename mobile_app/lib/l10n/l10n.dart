import 'package:flutter/widgets.dart';

import '../core/services/locale_controller.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Context-free lookup for services (uses current [LocaleController] locale).
AppLocalizations get l10n =>
    lookupAppLocalizations(LocaleController.instance.locale);
