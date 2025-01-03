// Import necessary Dart packages
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fyno_flutter_inapp/notifications_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

// Define a class for FynoInApp
class FynoInApp {
  // Create an instance of FynoInAppState
  FynoInAppState fynoInAppState = FynoInAppState();

  // Method to get FynoNotificationIcon
  FynoNotificationIcon getFynoNotificationIconButton(
    BuildContext context,
    Color color, {
    IconData? notificationIcon,
    ThemeConfig? themeConfig,
  }) {
    return FynoNotificationIcon(
      this,
      color,
      notificationIcon: notificationIcon,
      themeConfig: themeConfig,
    );
  }

  // Callback function to notify listeners of changes
  Function(dynamic data)? onListUpdate;
  late Function stateUpdate = () => {print('Default stateUpdate triggered')};
  socket_io.Socket? socket;

  // Method to connect to the FynoInAppSocket
  void fynoInAppSocketConnect(
    workspaceId,
    integrationId,
    userId,
    origin,
    signature,
  ) {
    print("socket status, $socket");
    if (socket != null) {
      print("Already connected to server");
      return;
    }

    // Create a socket and configure its options
    socket = socket_io.io(
      "wss://inapp.fyno.io",
      socket_io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({
            'user_id': userId,
            'WS_ID': workspaceId,
            'Integration_ID': integrationId,
          })
          .setExtraHeaders({
            'Origin': origin,
            'withCredentials': true,
            'x-fyno-signature': signature,
          })
          .enableForceNew()
          .build(),
    );

    // Handle socket error
    socket?.onError((error) => print(error));

    socket?.onDisconnect((_) {
      print('Disconnected from the server');
    });

    // Handle successful connection to the server
    socket?.on('connectionSuccess', (_) {
      print('Connected to the server');
      // Initialize variables and emit request for messages
      fynoInAppState._list = [];
      fynoInAppState._count = 0;
      fynoInAppState._unreadCount = 0;
      fynoInAppState._signature = signature;
      socket?.emit('get:messages', {'filter': 'all', 'page': 1});
      socket?.emit('updateLastSeen');
    });

    socket?.on('lastSeenUpdated', (data) {
      print(data);
      fynoInAppState.isSeen = data;
    });

    // Handle incoming messages
    socket?.on('message', (data) {
      // Check if the message is not silent and handle it
      if (!(data?['notification_content']?['silent_message'] ?? true)) {
        _handleIncomingMessage(data);
      }
    });

    // Handle messages state updates
    socket?.on('messages:state', (data) {
      // Update message lists and counts based on server response
      fynoInAppState._list =
          (data['messages']['messages']?.length > 0 && data['page'] > 2)
              ? fynoInAppState._list + data['messages']['messages']
              : data['messages']['messages'];

      // Update unread list and count
      fynoInAppState._unreadList =
          (data['messages']['messages']?.length > 0 && data['page'] > 2)
              ? fynoInAppState._unreadList +
                  data['messages']['messages']
                      ?.where((message) => !message['isRead'])
                      ?.toList()
              : data['messages']['messages']
                      ?.where((message) => !message['isRead'])
                      ?.toList() ??
                  [];

      fynoInAppState._unreadCount = data['messages']['unread'];
      fynoInAppState._count = data['messages']['total'];
      fynoInAppState._page = data['page'];
      stateUpdate.call();
    });

    // Handle tag updates
    socket?.on('tag:updated', (id) {
      var idDone = '';

      var prevMessage = fynoInAppState._list
          .firstWhere((item) => item['_id'] == id, orElse: () => null);

      // Check if the message is not marked as read and update counts
      if (idDone != id &&
          !RegExp(r'"READ"')
              .hasMatch(jsonEncode(prevMessage?['status'] ?? []))) {
        fynoInAppState._unreadCount--;
        idDone = id;

        fynoInAppState._unreadList.removeWhere((item) => item['_id'] == id);
      }
      fynoInAppState._list.removeWhere((item) => item['_id'] == id);
      fynoInAppState._count--;
    });
  }

  void reset() {
    if (socket != null) {
      socket?.dispose();
      socket = null;
      resetDefaults();
    } else {
      print("Socket not initialized");
    }
  }

  void resetDefaults() {
    fynoInAppState._list = [];
    fynoInAppState._unreadList = [];
    fynoInAppState._count = 0;
    fynoInAppState._unreadCount = 0;
    fynoInAppState._page = 1;
    fynoInAppState._signature = '';
    fynoInAppState.isSeen = true;
  }

  // Private method to handle status changes
  void _handleChangeStatus(status) {
    if (status['status'] == 'DELETED') {
      // Remove the message from the list if it is deleted
      fynoInAppState._list
          .removeWhere((element) => element['_id'] == status['messageId']);
      fynoInAppState._count--;
      // Remove from unread list and update count if it's unread
      if (!(status?['isRead'] ?? true)) {
        fynoInAppState._unreadList
            .removeWhere((element) => element['_id'] == status['messageId']);
        fynoInAppState._unreadCount--;
      }
    } else if (status['status'] == 'READ') {
      // Mark the message as read and update counts
      var message = fynoInAppState._list.firstWhere(
        (element) => element['_id'] == status['messageId'],
        orElse: () => null,
      );

      if (message != null) {
        message?['status'].add(Map<String, Object>.from(status));
        message['isRead'] = true;
      }
      // Remove from unread list and update count
      fynoInAppState._unreadList
          .removeWhere((element) => element['_id'] == status['messageId']);
      fynoInAppState._unreadCount--;
    } else {
      // Update message status for other cases
      var message = fynoInAppState._list.firstWhere(
        (message) => message['_id'] == status['messageId'],
        orElse: () => null,
      );

      if (message != null) {
        message?['status'].add(Map<String, Object>.from(status));
      }
    }
  }

  // Method to load more notifications
  Future<void> loadMoreNotifications(String type, int page) {
    final Completer<void> completer = Completer<void>();

    socket?.once('messages:state', (_) {
      completer.complete();
    });

    socket?.emit('get:messages', {'filter': type, 'page': page});

    return completer.future;
  }

  // Method to delete all messages
  Future<void> deleteAllMessages() {
    final Completer<void> completer = Completer<void>();

    socket?.once('messages:state', (_) {
      completer.complete();
    });

    socket?.emit('markAll:delete', fynoInAppState._signature);
    fynoInAppState._unreadCount = 0;

    return completer.future;
  }

  // Method to mark all messages as read
  Future<void> markAllAsRead() {
    final Completer<void> completer = Completer<void>();

    socket?.once('messages:state', (_) {
      completer.complete();
    });

    socket?.emit('markAll:read', fynoInAppState._signature);
    fynoInAppState._unreadCount = 0;

    return completer.future;
  }

  // Method to handle incoming message
  void _handleIncomingMessage(message) {
    message['isRead'] = false;
    fynoInAppState._list.insert(0, message);
    fynoInAppState._unreadList.insert(0, message);
    fynoInAppState._count++;
    fynoInAppState._unreadCount++;
    onListUpdate?.call(message);
    stateUpdate.call();
  }

  // Method to handle message deletion
  Future<void> deleteMessage(notification) async {
    final Completer<void> completer = Completer<void>();

    socket?.once('statusUpdated', (status) {
      _handleChangeStatus(status);
      completer.complete();
    });

    socket?.emit('message:deleted', notification);

    return completer.future;
  }

  // Method to mark a message as read
  Future<void> markAsRead(notification) async {
    final Completer<void> completer = Completer<void>();

    socket?.once('statusUpdated', (status) {
      _handleChangeStatus(status);
      completer.complete();
    });

    socket?.emit('message:read', notification);

    return completer.future;
  }
}

// Define the state class for FynoInApp
class FynoInAppState {
  // Define instance variables
  var _list = [];
  var _unreadList = [];
  var _count = 0;
  var _unreadCount = 0;
  var _page = 1;
  String _signature = '';
  bool isSeen = true;

  // Define getters for the variables
  List get list => _list;
  List get unreadList => _unreadList;
  int get count => _count;
  int get unreadCount => _unreadCount;
  int get page => _page;
}
