# Fyno Flutter InApp SDK

Fyno's Flutter InApp SDK comes with the ability to provide its users with a multitude of notification features, all bundled into one, allowing it to smartly provide the best and optimised message delivery service from within your application itself.

## Prerequisites

Before you start, make sure you have the following information ready

- **Workspace ID (WSID)**: You can find your workspace ID on your Fyno [API Keys](https://app.fyno.io/api-keys) page.
- **Integration Token**: Obtain the integration token from the [Integrations](https://app.fyno.io/integrations) page.
- **User ID**: This should be a unique identifier for the currently logged-in user. This user ID is crucial for Fyno to send specific notifications to the right users.

## Installation

Install the package by using one of the following commands.

```bash
dart pub add fyno_flutter_inapp
OR
flutter pub add fyno_flutter_inapp
```

This will add a line like this to your package's pubspec.yaml (and run an implicit `dart/flutter pub get`):

```yaml
dependencies:
  fyno_flutter_inapp: <latest_version>
```

Alternatively, your editor might support `dart/flutter pub get`. Check the docs for your editor to learn more.

## HMAC Signature Generation

The HMAC signature is essential for ensuring the security and integrity of your notifications. Here is an example of how to generate the HMAC signature in dart

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
String signature = Hmac(sha256, utf8.encode(workspaceId + integrationToken))
.convert(utf8.encode(userId))
.toString();
}
```

## Usage

Import the package in your Dart file:

```dart
import 'package:fyno_flutter_inapp/fyno_flutter_inapp.dart';
```

## SDK Initialisation

To use the SDK in your Flutter application, initialise the SDK as follows

```dart
final FynoInApp fynoInApp = FynoInApp();

// Web Socket connection
fynoInApp.fynoInAppSocketConnect(
workspaceId,
integrationId,
userId,
origin,
signature,
);
```

There are 2 ways you can configure InApp UI.

1. Fyno UI
2. Customisable UI

- Fyno UI

```dart
fynoInApp.getFynoNotificationIconButton(
context,
<icon_color>,
),
```

- Customisable UI

Within the Customizable UI feature, you have the flexibility to build your own UI. Additionally, you can personalize the icons for actions like 'Read all' and 'Delete all' with your own custom designs. If you are utilizing the Customizable UI, it is necessary to invoke the following APIs.

1. To mark all InApp notifications as Read

```dart
fynoInApp.markAllAsRead()
```

2. To delete all InApp notifications

```dart
fynoInApp.deleteAllMessages()
```

3. To mark a single InApp notifications as Read

```dart
fynoInApp.markAsRead(notification) // pass one of the items from this list fynoInApp.fynoInAppState.list
```

4. To delete a single InApp notification

```dart
fynoInApp.deleteMessage(notification) // pass one of the items from this list fynoInApp.fynoInAppState.list
```

5. To load more notifications (based on pagination)

```dart
fynoInApp.loadMoreNotifications(page, type) // type -> 'all' or 'unread', page should be greater than zero
```
