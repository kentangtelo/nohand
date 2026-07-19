# NoHand - MacBook Theft Alarm

NoHand is a macOS menu bar application that detects when a MacBook lid is
closed while the laptop is left unattended in a public place. When Armed,
NoHand keeps the Mac awake with its lid closed, locks the screen, plays a local
alarm from `audio.mp3`, and sends a notification to Android or iOS through
[ntfy.sh](https://ntfy.sh).

NoHand does not use an application-specific PIN. Unlocking and disarming rely
on the native macOS lock screen using the account password or Touch ID.

## Features

- Menu bar application with no Dock icon.
- Real-time lid open/closed detection through IOKit.
- Clamshell sleep prevention while Armed using `pmset disablesleep`.
- Looping MP3 alarm at maximum system volume with a system beep fallback.
- Alarm audio is preloaded during Arm to reduce clamshell transition races.
- Urgent push notifications through ntfy.sh.
- Automatic lock screen activation during Arm.
- Automatic disarm after unlocking with the account password or Touch ID.
- Sleep setting recovery after unlock, disarm, quit, or a previous crash.
- Apple Silicon and Intel support.

## Requirements

- A MacBook running macOS 15 or later.
- Xcode with the macOS SDK.
- An administrator account or administrator credentials.
- Accessibility permission for NoHand.
- The ntfy application on an Android or iOS device for receiving alerts.

## Initial Setup

### 1. Grant Accessibility Permission

1. Open **System Settings > Privacy & Security > Accessibility**.
2. Add the `nohand` application if it is not already listed.
3. Enable the toggle for `nohand`.

This permission is required by the lock screen fallback that simulates the
Control+Command+Q shortcut.

### 2. Configure ntfy

1. Install [ntfy](https://ntfy.sh) on your phone.
2. Subscribe to a random, hard-to-guess topic such as
   `nohand-7f91c2-example`.
3. Select **Set ntfy Topic...** from the NoHand menu.
4. Enter the same topic and select **Save**.
5. Select **Test Notification** and confirm that the notification arrives on
   your phone.

Topics on the public ntfy.sh server are not authenticated. Anyone who knows a
topic name can subscribe to it, so do not use an easily guessed name or send
sensitive information.

## Usage

### Arm

1. Select **NoHand > Arm**.
2. On first use, read and accept the battery and heat warning.
3. Enter administrator credentials when macOS requests authorization.
4. NoHand runs `pmset -a disablesleep 1`, acquires a power assertion, prepares
   `assets/audio.mp3`, and locks the screen.
5. If authorization is cancelled or the sleep setting cannot be changed,
   arming is cancelled and the application remains Disarmed.

### Trigger

When the lid is closed while NoHand is Armed:

- The Mac remains awake with its lid closed.
- `audio.mp3` plays continuously at maximum volume.
- A **MacBook Theft Alert** notification is sent to the configured ntfy topic.
- If the MP3 cannot be played, NoHand repeatedly plays the system alert sound.

### Disarm

1. Open the MacBook lid.
2. Unlock the Mac using the account password or Touch ID.
3. NoHand automatically stops the alarm, releases the power assertion, changes
   its state to Disarmed, and runs `pmset -a disablesleep 0`.

NoHand stores or validates no PIN or account password.

## Safety Warning

Armed mode intentionally keeps the Mac running while its lid is closed. This
can increase battery usage and device temperature.

- Never place the MacBook in a bag or sleeve while it is Armed.
- Always unlock and disarm NoHand before storing or transporting the MacBook.
- Do not ignore an error indicating that the sleep setting could not be
  restored.

If the application terminates unexpectedly, NoHand stores a recovery flag and
attempts to restore the sleep setting on its next launch. If automatic recovery
fails, run the following command in Terminal:

```bash
sudo pmset -a disablesleep 0
```

## License and Contributing

Internal project. Contact the repository owner to contribute.
