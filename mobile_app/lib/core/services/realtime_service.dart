import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';
import '../../models/prescription_model.dart';

class RealtimeService {
  IO.Socket? socket;
  Function(PrescriptionModel)? onNewPrescription;
  Function(String title, String body)? onNotification;

  void connect(String userId) {
    socket = IO.io(ApiConstants.voiceSignalingUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setQuery({'userId': userId})
      .build());

    socket!.onConnect((_) {
      print('Realtime Socket connected');
      socket!.emit('join-user-room', userId);
    });

    socket!.on('new-prescription', (data) {
      if (onNewPrescription != null) {
        onNewPrescription!(PrescriptionModel.fromJson(data));
      }
    });

    socket!.on('notification', (data) {
      if (onNotification != null) {
        onNotification!(data['title'], data['body']);
      }
    });
  }

  void sendPrescription(String receiverId, Map<String, dynamic> prescription) {
    if (socket?.connected == true) {
      socket!.emit('new-prescription', {
        'receiverId': receiverId,
        'prescription': prescription
      });
    }
  }

  void disconnect() {
    socket?.disconnect();
  }
}
