import 'package:flutter/material.dart';
import 'package:fyno_flutter_inapp/fyno_flutter_inapp.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

class FynoNotificationIcon extends StatefulWidget {
  final FynoInApp fynoInApp;
  final Color iconColor;

  const FynoNotificationIcon(
    this.fynoInApp,
    this.iconColor, {
    Key? key,
  }) : super(key: key);

  @override
  FynoNotificationIconState createState() => FynoNotificationIconState();
}

class FynoNotificationIconState extends State<FynoNotificationIcon> {
  @override
  Widget build(BuildContext context) {
    widget.fynoInApp.onListUpdate = () {
      setState(() {});
    };

    return Stack(
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationsPage(
                  widget.fynoInApp,
                  onUpdate,
                ),
              ),
            );
          },
          icon: Icon(
            Icons.notifications,
            color: widget.iconColor,
          ),
        ),
        if (widget.fynoInApp.fynoInAppState.unreadCount > 0)
          Positioned(
            right: 12,
            top: 10,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(
                minWidth: 10,
                minHeight: 10,
              ),
            ),
          ),
      ],
    );
  }

  void onUpdate() {
    setState(() {});
  }
}

class NotificationsPage extends StatefulWidget {
  final FynoInApp fynoInApp;
  final Function onClick;

  const NotificationsPage(this.fynoInApp, this.onClick, {Key? key})
      : super(key: key);

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  final ScrollController _allScrollController = ScrollController();
  final ScrollController _unreadScrollController = ScrollController();
  int _allCurrentPage = 1;
  int _unreadCurrentPage = 1;

  @override
  void initState() {
    super.initState();
    widget.fynoInApp.onListUpdate = () {
      if (mounted) {
        setState(() {});
      }
    };

    _allScrollController.addListener(() {
      if (_allScrollController.position.atEdge) {
        if (_allScrollController.position.pixels != 0 &&
            widget.fynoInApp.fynoInAppState.list.length <
                widget.fynoInApp.fynoInAppState.count) {
          _loadMoreNotifications('all');
        }
      }
    });

    _unreadScrollController.addListener(() {
      if (_unreadScrollController.position.atEdge) {
        if (_unreadScrollController.position.pixels != 0 &&
            widget.fynoInApp.fynoInAppState.unreadList.length <
                widget.fynoInApp.fynoInAppState.unreadCount) {
          _loadMoreNotifications('unread');
        }
      }
    });
  }

  Future<void> _loadMoreNotifications(String tab) async {
    if (tab == 'all') {
      _allCurrentPage++;
      await widget.fynoInApp.loadMoreNotifications(tab, _allCurrentPage);
    } else {
      _unreadCurrentPage++;
      await widget.fynoInApp.loadMoreNotifications(tab, _unreadCurrentPage);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _allScrollController.dispose();
    _unreadScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: buildAppBar(context),
        body: TabBarView(
          children: [
            buildNotificationTab(
              widget.fynoInApp,
              widget.fynoInApp.fynoInAppState.list,
              _onClick,
              'all',
              _allScrollController,
            ),
            buildNotificationTab(
              widget.fynoInApp,
              widget.fynoInApp.fynoInAppState.unreadList,
              _onClick,
              'unread',
              _unreadScrollController,
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    var unreadCount = widget.fynoInApp.fynoInAppState.unreadCount.toString();

    return AppBar(
      leading: BackButton(
        onPressed: () => {
          widget.onClick(),
          Navigator.pop(context),
          setState(() {}),
        },
      ),
      iconTheme: IconThemeData(color: Colors.white),
      backgroundColor: Theme.of(context).primaryColor,
      title: Text(
        'Notifications',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      actions: [
        if (widget.fynoInApp.fynoInAppState.unreadList.isNotEmpty)
          IconButton(
            onPressed: () {
              _showConfirmationDialog(
                'Mark All as Read',
                'Are you sure you want to mark all notifications as read?',
                () {
                  handleAction('markAllAsRead');
                },
              );
            },
            icon: Icon(Icons.done_all),
          ),
        if (widget.fynoInApp.fynoInAppState.list.isNotEmpty)
          IconButton(
            onPressed: () {
              _showConfirmationDialog(
                'Delete All',
                'Are you sure you want to delete all notifications?',
                () {
                  handleAction('deleteAll');
                },
              );
            },
            icon: Icon(Icons.delete_sweep),
          ),
      ],
      bottom: TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white,
        tabs: [
          Tab(text: 'All'),
          Tab(text: 'Unread ($unreadCount)'),
        ],
      ),
    );
  }

  void handleAction(String action) {
    switch (action) {
      case 'markAllAsRead':
        widget.fynoInApp.markAllAsRead().then((_) {
          setState(() {});
        });
        break;
      case 'deleteAll':
        widget.fynoInApp.deleteAllMessages().then((_) {
          setState(() {});
        });
        break;
    }
  }

  void _showConfirmationDialog(
      String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(context);
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _onClick() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget buildNotificationTab(
    FynoInApp fynoInApp,
    List<dynamic> messages,
    Function() onClick,
    String tabName,
    ScrollController? scrollController,
  ) {
    return Tab(
      child: NotificationsTab(
        fynoInApp,
        messages,
        onClick,
        tabName,
        scrollController,
      ),
    );
  }
}

class NotificationsTab extends StatelessWidget {
  final FynoInApp fynoInApp;
  final List<dynamic> messages;
  final Function() onClick;
  final String tabName;
  final ScrollController? scrollController;

  const NotificationsTab(
    this.fynoInApp,
    this.messages,
    this.onClick,
    this.tabName,
    this.scrollController, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildMessagesList(context, messages);
  }

  Widget buildMessagesList(BuildContext context, List<dynamic> messages) {
    Widget loadingIndicator = CircularProgressIndicator.adaptive();

    if (messages.isEmpty) {
      if (tabName == 'all') {
        return buildEmptyList('No notifications', context);
      }
      return buildEmptyList('No $tabName notifications', context);
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index < messages.length) {
          return buildListTile(context, messages[index]);
        } else {
          switch (tabName) {
            case 'all':
              if (index < fynoInApp.fynoInAppState.count) {
                return loadingIndicator;
              }
            case 'unread':
              if (index < fynoInApp.fynoInAppState.unreadCount) {
                return loadingIndicator;
              }
          }
        }
        return null;
      },
    );
  }

  Widget buildListTile(BuildContext context, dynamic message) {
    return NotificationListTile(
      fynoInApp,
      message,
      onClick,
    );
  }

  Widget buildEmptyList(String message, BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 20,
        ),
      ),
    );
  }
}

class NotificationListTile extends StatefulWidget {
  final FynoInApp fynoInApp;
  final dynamic message;
  final Function() onClick;

  const NotificationListTile(
    this.fynoInApp,
    this.message,
    this.onClick, {
    Key? key,
  }) : super(key: key);

  @override
  NotificationListTileState createState() => NotificationListTileState();
}

class NotificationListTileState extends State<NotificationListTile> {
  @override
  Widget build(BuildContext context) {
    bool isUnread = !widget.message['isRead'];

    return InkWell(
      key: Key(widget.message.hashCode.toString()),
      onTap: () {
        handleTap(isUnread);
        handleNotificationAction(widget.message);
      },
      child: buildListTile(context, isUnread),
    );
  }

  void handleNotificationAction(Map<String, dynamic> message) {
    if (message['notification_content'] != null &&
        message['notification_content']['action'] != null &&
        message['notification_content']['action']['href'] != null) {
      launchUrl(Uri.parse(
          message['notification_content']['action']['href'].toString()));
    }
  }

  Widget buildListTile(BuildContext context, bool isUnread) {
    return ListTile(
      shape: Border(
        bottom: BorderSide(
          color: Theme.of(context).secondaryHeaderColor.withOpacity(0.5),
        ),
      ),
      contentPadding: EdgeInsets.only(
        top: 15,
        left: 20,
        right: 20,
      ),
      tileColor:
          isUnread ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
      title: buildTitle(context),
    );
  }

  Widget buildTitle(BuildContext context) {
    var notificationContent = widget.message['notification_content'];
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notificationContent['icon'] != null) buildNotificationIcon(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 13.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificationContent['title'].toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      notificationContent['body'].toString(),
                      style: TextStyle(
                        height: 1.5,
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (notificationContent['buttons'] != null)
                      buildButtonRow(),
                    Row(
                      children: [
                        Text(
                          GetTimeAgo.parse(
                            DateTime.fromMillisecondsSinceEpoch(
                                widget.message['status'][0]['timestamp']),
                          ),
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: !widget.message['isRead']
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (notificationContent['attachments'] != null &&
                notificationContent['attachments']['attachment'] != null)
              buildAttachment(),
          ],
        ),
        buildBottomSheetButton(!widget.message['isRead'], widget.message),
      ],
    );
  }

  Widget buildNotificationIcon() {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: ClipOval(
        child: Image.network(
          widget.message['notification_content']['icon'].toString(),
          height: 25,
          width: 25,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  List<dynamic> sortButtons(List<dynamic> buttons) {
    buttons.sort((a, b) {
      bool isPrimaryA = a['primary'].toLowerCase() == "true";
      bool isPrimaryB = b['primary'].toLowerCase() == "true";

      if (isPrimaryA && !isPrimaryB) {
        return 1;
      } else if (!isPrimaryA && isPrimaryB) {
        return -1;
      } else {
        return 0;
      }
    });

    return buttons;
  }

  Widget buildButtonRow() {
    widget.message['notification_content']['buttons'] =
        sortButtons(widget.message['notification_content']['buttons']);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          widget.message['notification_content']['buttons'].length,
          (index) {
            return buildButton(
                widget.message['notification_content']['buttons'][index]);
          },
        ),
      ),
    );
  }

  Widget buildButton(dynamic button) {
    bool isPrimary = button['primary'].toLowerCase() == "true";

    return Container(
      height: 25,
      margin: EdgeInsets.only(right: 8, bottom: 8),
      child: TextButton(
        onPressed: () {
          _launchUrl(Uri.parse(button['action'].toString()));
        },
        style: ButtonStyle(
          backgroundColor: isPrimary
              ? MaterialStateProperty.all(Theme.of(context).primaryColor)
              : null,
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
              side: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
        ),
        child: Text(
          button['label'].toString().toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            color: isPrimary ? Colors.white : Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget buildAttachment() {
    String attachmentType = widget.message['notification_content']
            ['attachments']['type']
        .toString()
        .toLowerCase();

    switch (attachmentType) {
      case 'image':
        return buildImage();
      case 'video':
        return buildVideo();
      case 'document':
        return buildDocument();
      default:
        return Container();
    }
  }

  Widget buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5.0),
      child: Column(children: [
        Image.network(
          widget.message['notification_content']['attachments']['attachment']
              .toString(),
          height: 45,
          width: 45,
          fit: BoxFit.cover,
        ),
      ]),
    );
  }

  Widget buildVideo() {
    String videoUrl =
        widget.message['notification_content']['attachments']['attachment'];

    return SizedBox(
      height: 55,
      width: 55,
      child: InkWell(
        onTap: () {
          _launchUrl(Uri.parse(videoUrl));
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.0),
          child: Container(
            padding: EdgeInsets.all(12),
            color: Theme.of(context).primaryColor.withOpacity(0.15),
            child: Column(
              children: [
                Icon(
                  Icons.play_circle,
                  color: Theme.of(context).primaryColor,
                  size: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDocument() {
    String documentUrl =
        widget.message['notification_content']['attachments']['attachment'];

    String fileExtension = path.extension(path.basename(documentUrl));

    String fileType = fileExtension.isNotEmpty
        ? fileExtension.substring(1).toUpperCase()
        : '';

    return SizedBox(
      height: 55,
      width: 55,
      child: InkWell(
        onTap: () {
          _launchUrl(Uri.parse(documentUrl));
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            color: Theme.of(context).primaryColor.withOpacity(0.15),
            child: Column(
              children: [
                Icon(
                  Icons.file_copy,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                Text(
                  fileType,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(Uri uri) async {
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }

  void showBottomSheet(BuildContext context, bool isUnread, dynamic message) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 14),
                    width: 50,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: Theme.of(context).secondaryHeaderColor,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                if (isUnread)
                  ListTile(
                    title: Container(
                        child: Row(
                      children: [
                        Icon(Icons.done_all),
                        SizedBox(width: 12),
                        Text('Mark as Read')
                      ],
                    )),
                    onTap: () {
                      handlePopupSelection('markAsRead', message);
                      Navigator.pop(context);
                    },
                  ),
                ListTile(
                  title: Container(
                      child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 12),
                      Text('Delete'),
                    ],
                  )),
                  onTap: () {
                    handlePopupSelection('delete', message);
                    Navigator.pop(context);
                  },
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildBottomSheetButton(bool isUnread, dynamic message) {
    return Positioned(
      bottom: -4,
      right: 0,
      child: IconButton(
        icon: Icon(
          Icons.more_horiz,
          color: Theme.of(context).secondaryHeaderColor,
        ),
        onPressed: () {
          showBottomSheet(context, isUnread, message);
        },
      ),
    );
  }

  void handlePopupSelection(String value, dynamic message) {
    switch (value) {
      case 'markAsRead':
        widget.fynoInApp.markAsRead(message).then((_) {
          setState(() {});
          widget.onClick();
        });
        break;
      case 'delete':
        widget.fynoInApp.deleteMessage(message).then((_) {
          setState(() {});
          widget.onClick();
        });
        break;
    }
  }

  void handleTap(bool isUnread) {
    if (isUnread) {
      widget.fynoInApp.markAsRead(widget.message).then((_) {
        setState(() {});
        widget.onClick();
      });
    }
  }
}
