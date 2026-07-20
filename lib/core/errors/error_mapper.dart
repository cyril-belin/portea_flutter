import 'dart:async';
import 'dart:io';

import 'package:portea_client/portea_client.dart';

/// Translates any exception raised by a repository call into a single
/// user-facing French message.
///
/// This is the single source of truth for error wording in the app. View
/// models catch the exception, call [mapExceptionToMessage], store the result
/// in their `errorMessage`, and notify — nothing else.
///
/// Two disjoint Serverpod exception hierarchies exist (there is no shared
/// `ServerpodException` base):
/// - [SerializableException] — typed business exceptions, transported across
///   the wire with their concrete type preserved (our `.spy.yaml` exceptions).
///   Their `.message` is already a French business sentence authored on the
///   server; we surface it verbatim, never reworded.
/// - [ServerpodClientException] — HTTP/transport layer, carrying a numeric
///   [ServerpodClientException.statusCode] (`-1` = unreachable, `401` =
///   session dead, `500` = server bug, …).
///
/// Special case: [ActiveLitterLimitException] is **never** mapped here. It is
/// a paywall signal handled in the view model (see `LitterDeclarationViewModel`
/// → `LitterDeclarationOutcome.activeLimitReached`), not a user-facing error
/// string. A view model that can raise it must catch it *before* falling back
/// to this mapper.
String mapExceptionToMessage(Object error) {
  // --- Typed business exceptions (SerializableException) ---------------------
  // Order matters only for readability; these types are mutually exclusive.
  // The `.message` field is the French business string authored in the server
  // `.spy.yaml` files — surfaced verbatim.
  if (error is InvalidLitterRelationException) return error.message;
  if (error is InvalidPuppyRelationException) return error.message;
  if (error is PuppyDeletionNotAllowedException) return error.message;
  if (error is InvalidWeighingRelationException) return error.message;
  if (error is InvalidWeighingInputException) return error.message;
  if (error is InvalidCareRelationException) return error.message;
  if (error is InvalidCareInputException) return error.message;
  if (error is InvalidPuppyInputException) return error.message;
  if (error is InvalidKennelInputException) return error.message;
  if (error is IncompleteCessionDataException) return error.message;
  // NOTE: ActiveLitterLimitException deliberately NOT handled here.
  // F10-A: server-reported premium sync failure surfaces its server-authored
  // message verbatim (the user's premiumUntil is left untouched on the server,
  // but the purchase/restore flow could not confirm the new state).
  if (error is PremiumSyncFailedException) return error.message;
  // F10-B: RGPD account deletion failure surfaces its server-authored message
  // verbatim. The transaction is atomic, so a failure means nothing was
  // deleted — the user can retry safely.
  if (error is AccountDeletionException) return error.message;

  // --- Transport / HTTP layer ------------------------------------------------
  if (error is ServerpodClientException) {
    switch (error.statusCode) {
      case -1:
        // SocketException / connection refused / DNS — wrapped by the IO
        // delegate into statusCode -1.
        return _networkMessage;
      case HttpStatus.unauthorized:
        // ServerpodClientUnauthorized — the client already attempted one
        // silent token refresh before propagating this, so reaching here
        // means the session is genuinely dead.
        return _sessionExpiredMessage;
      case HttpStatus.forbidden:
        return "Vous n'avez pas accès à cette action.";
      default:
        // 400, 404, 500, … — nothing actionable for the user.
        return _genericMessage;
    }
  }

  // --- Network primitives not wrapped by the Serverpod IO delegate ----------
  // TimeoutException slips through unwrapped (see serverpod_client_io.dart);
  // SocketException is normally converted to statusCode -1 above, but we keep
  // it as a defensive net for any code path that bypasses the delegate.
  if (error is TimeoutException) return _timeoutMessage;
  if (error is SocketException) return _networkMessage;

  // --- Anything else ---------------------------------------------------------
  return _genericMessage;
}

const String _networkMessage = 'Vérifiez votre connexion internet.';
const String _timeoutMessage =
    'Le serveur met trop de temps à répondre. Vérifiez votre connexion et réessayez.';
const String _sessionExpiredMessage =
    'Votre session a expiré. Reconnectez-vous pour continuer.';
const String _genericMessage = 'Une erreur est survenue. Veuillez réessayer.';
