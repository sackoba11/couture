// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';

// class SnackbarService {
//   SnackbarService._();

//   static final FToast _fToast = FToast();
//   static bool _initialized = false;

//   static void ensureInitialized(BuildContext context) {
//     try {
//       _fToast.init(context);
//       _initialized = true;
//     } catch (_) {
//       _initialized = false;
//     }
//   }

//   static Future<void> show(
//     String title,
//     String message, {
//     IconData? icon,
//     Color? backgroundColor,
//     Color? textColor,
//     Duration duration = const Duration(seconds: 3),
//   }) async {
//     try {
//       if (!_initialized) return;
//       _fToast.showToast(
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16.0),
//             color: backgroundColor ?? const Color(0xDD323232),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (icon != null) ...[
//                 Icon(icon, color: textColor, size: 22),
//                 const SizedBox(width: 10),
//               ],
//               Expanded(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         color: textColor,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 15,
//                       ),
//                     ),
//                     if (message.isNotEmpty) ...[
//                       const SizedBox(height: 2),
//                       Text(
//                         message,
//                         style: TextStyle(color: textColor, fontSize: 13),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         // fadeDuration: const Duration(milliseconds: 250),
//         positionedToastBuilder: (context, child, gravity) =>
//             Positioned(top: 40, left: 16, right: 16, child: child),
//         gravity: ToastGravity.TOP,
//         toastDuration: duration,
//       );
//     } catch (_) {
//       // Overlay indisponible (tests unitaires, isolate background,
//       // fermeture en cours) : on ignore plutôt que de planter l'appelant.
//     }
//   }

//   /// Tests uniquement : vide la file et annule les minuteurs.
//   @visibleForTesting
//   static void resetForTesting() {
//     try {
//       _fToast.removeQueuedCustomToasts();
//     } catch (_) {}
//     _initialized = false;
//   }
// }
