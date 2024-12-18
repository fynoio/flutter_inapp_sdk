import 'package:flutter/material.dart';
import 'package:fyno_flutter_inapp/fyno_flutter_inapp.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

class ThemeConfig {
  final Color? darkText;
  final Color? lightText;
  final Color? darkBackground;
  final Color? lightBackground;
  final Color? primary;

  ThemeConfig({
    this.lightText,
    this.darkText,
    this.lightBackground,
    this.darkBackground,
    this.primary,
  });
}

class FynoNotificationIcon extends StatefulWidget {
  final FynoInApp fynoInApp;
  final Color iconColor;
  final IconData? notificationIcon;
  final ThemeConfig? themeConfig;

  const FynoNotificationIcon(
    this.fynoInApp,
    this.iconColor, {
    this.notificationIcon,
    this.themeConfig,
    Key? key,
  }) : super(key: key);

  @override
  FynoNotificationIconState createState() => FynoNotificationIconState();
}

class FynoNotificationIconState extends State<FynoNotificationIcon> {
  @override
  Widget build(BuildContext context) {
    widget.fynoInApp.stateUpdate = () {
      if (mounted) {
        setState(() {});
      }
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
                  themeConfig: widget.themeConfig,
                ),
              ),
            );
          },
          icon: Icon(
            widget.notificationIcon ?? Icons.notifications_outlined,
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
    if (mounted) {
      setState(() {});
    }
  }
}

class NotificationsPage extends StatefulWidget {
  final FynoInApp fynoInApp;
  final Function onClick;
  final ThemeConfig? themeConfig;

  const NotificationsPage(
    this.fynoInApp,
    this.onClick, {
    this.themeConfig,
    Key? key,
  }) : super(key: key);

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
    widget.fynoInApp.stateUpdate = () {
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      leading: BackButton(
        onPressed: () => {
          widget.onClick(),
          Navigator.pop(context),
          if (mounted)
            {
              setState(() {}),
            }
        },
      ),
      iconTheme: IconThemeData(
          color: isDarkMode
              ? widget.themeConfig?.darkText ?? Colors.white
              : widget.themeConfig?.lightText ?? Colors.black),
      backgroundColor: isDarkMode
          ? widget.themeConfig?.darkBackground ?? Colors.black
          : widget.themeConfig?.lightBackground ?? Colors.white,
      title: Text(
        'Notifications',
        style: TextStyle(
          color: isDarkMode
              ? widget.themeConfig?.darkText ?? Colors.white
              : widget.themeConfig?.lightText ?? Colors.black,
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
        labelColor: isDarkMode
            ? widget.themeConfig?.darkText ?? Colors.white
            : widget.themeConfig?.lightText ?? Colors.black,
        unselectedLabelColor: isDarkMode
            ? widget.themeConfig?.darkText ?? Colors.white
            : widget.themeConfig?.lightText ?? Colors.black,
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
          if (mounted) {
            setState(() {});
          }
        });
        break;
      case 'deleteAll':
        widget.fynoInApp.deleteAllMessages().then((_) {
          if (mounted) {
            setState(() {});
          }
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
        themeConfig: widget.themeConfig,
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
  final ThemeConfig? themeConfig;

  const NotificationsTab(
    this.fynoInApp,
    this.messages,
    this.onClick,
    this.tabName,
    this.scrollController, {
    this.themeConfig,
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
      themeConfig: themeConfig,
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
  final ThemeConfig? themeConfig;

  const NotificationListTile(
    this.fynoInApp,
    this.message,
    this.onClick, {
    this.themeConfig,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      shape: Border(
        bottom: BorderSide(
          color: isDarkMode
              ? widget.themeConfig?.darkText?.withOpacity(0.5) ??
                  Colors.white.withOpacity(0.5)
              : widget.themeConfig?.lightText?.withOpacity(0.5) ??
                  Colors.black.withOpacity(0.5),
        ),
      ),
      contentPadding: EdgeInsets.only(
        top: 15,
        left: 20,
        right: 20,
      ),
      tileColor: isUnread
          ? isDarkMode
              ? widget.themeConfig?.darkBackground?.withOpacity(0.6) ??
                  Colors.white.withOpacity(0.1)
              : widget.themeConfig?.lightBackground?.withOpacity(0.6) ??
                  Colors.black.withOpacity(0.1)
          : Theme.of(context).brightness == Brightness.dark
              ? widget.themeConfig?.darkBackground?.withOpacity(0.2) ??
                  Colors.black
              : widget.themeConfig?.lightBackground?.withOpacity(0.2) ??
                  Colors.white,
      title: buildTitle(context),
    );
  }

  Widget buildTitle(BuildContext context) {
    var notificationContent = widget.message['notification_content'];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                        color: isDarkMode
                            ? widget.themeConfig?.darkText ?? Colors.white
                            : widget.themeConfig?.lightText ?? Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      notificationContent['body'].toString(),
                      style: TextStyle(
                        color: isDarkMode
                            ? widget.themeConfig?.darkText ?? Colors.white
                            : widget.themeConfig?.lightText ?? Colors.black,
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
                            color: isDarkMode
                                ? widget.themeConfig?.darkText ?? Colors.white
                                : widget.themeConfig?.lightText ?? Colors.black,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 25,
      margin: EdgeInsets.only(right: 8, bottom: 8),
      child: TextButton(
        onPressed: () {
          _launchUrl(Uri.parse(button['action'].toString()));
        },
        style: ButtonStyle(
          backgroundColor: isPrimary
              ? MaterialStatePropertyAll(widget.themeConfig?.primary ??
                  (isDarkMode ? Colors.white : Colors.black))
              : null,
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
              side: BorderSide(
                color: isPrimary
                    ? widget.themeConfig?.primary ??
                        (isDarkMode ? Colors.white : Colors.black)
                    : isDarkMode
                        ? widget.themeConfig?.darkText ?? Colors.white
                        : widget.themeConfig?.lightText ?? Colors.black,
              ),
            ),
          ),
        ),
        child: Text(
          button['label'].toString().toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            color: isPrimary
                ? isDarkMode
                    ? widget.themeConfig?.lightText ?? Colors.black
                    : widget.themeConfig?.darkText ?? Colors.white
                : isDarkMode
                    ? widget.themeConfig?.darkText ?? Colors.white
                    : widget.themeConfig?.lightText ?? Colors.black,
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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            color: isDarkMode
                ? widget.themeConfig?.darkBackground?.withOpacity(0.6) ??
                    Colors.white.withOpacity(0.2)
                : widget.themeConfig?.lightBackground?.withOpacity(0.6) ??
                    Colors.black.withOpacity(0.2),
            child: Column(
              children: [
                Icon(
                  Icons.play_circle,
                  color: isDarkMode
                      ? widget.themeConfig?.darkText ?? Colors.white
                      : widget.themeConfig?.lightText ?? Colors.black,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            color: isDarkMode
                ? widget.themeConfig?.darkBackground?.withOpacity(0.6) ??
                    Colors.white.withOpacity(0.2)
                : widget.themeConfig?.lightBackground?.withOpacity(0.6) ??
                    Colors.black.withOpacity(0.2),
            child: Column(
              children: [
                Icon(
                  Icons.file_copy,
                  color: isDarkMode
                      ? widget.themeConfig?.darkText ?? Colors.white
                      : widget.themeConfig?.lightText ?? Colors.black,
                  size: 20,
                ),
                Text(
                  fileType,
                  style: TextStyle(
                    color: isDarkMode
                        ? widget.themeConfig?.darkText ?? Colors.white
                        : widget.themeConfig?.lightText ?? Colors.black,
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? widget.themeConfig?.darkText ?? Colors.white
                          : widget.themeConfig?.lightText ?? Colors.black,
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
          color: Theme.of(context).brightness == Brightness.dark
              ? widget.themeConfig?.darkText ?? Colors.white
              : widget.themeConfig?.lightText ?? Colors.black,
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
          if (mounted) {
            setState(() {});
          }
          widget.onClick();
        });
        break;
      case 'delete':
        widget.fynoInApp.deleteMessage(message).then((_) {
          if (mounted) {
            setState(() {});
          }
          widget.onClick();
        });
        break;
    }
  }

  void handleTap(bool isUnread) {
    if (isUnread) {
      widget.fynoInApp.markAsRead(widget.message).then((_) {
        if (mounted) {
          setState(() {});
        }
        widget.onClick();
      });
    }
  }
}
