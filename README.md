# That’s what she said

With That’s What She Said you can read the text of any voice message or audio file you receive.

[View on App Store](https://itunes.apple.com/us/app/thats-what-she-said/id1239469302?ls=1&mt=8)

## How it works

You need to send the voice message you have to an iOS action. Depending on the app this opens behind a button called "Share", "Forward" or "Export". Often it’s also the Apple share symbol.

If you tap on it, the iOS actions open where you can choose That’s What She Said:

<img src="https://jakobstoeck.de/assets/ios-action.png" width="311" alt="iOS action">

The transcribed text is shown after a few seconds as a notification:

<img src="https://jakobstoeck.de/assets/ios-twss-text.png" width="311" alt="iOS action">

## Supported Apps

Most apps should word since it only needs to support iOS actions. Those appear usually if you tap on "Share", "Forward" or "Export". I tried it succesfully with:

- WhatsApp
- Telegram
- Voice Memos

One notable exception is the Apple Messages app. I couldn’t find any way to share or export a voice message in this app.

## Privacy

Depending on the audio format voice is either sent directly to Google’s (for Opus and Flac) Speech Recognition service or Apple’s (all other audio formats). No other data is transmitted or stored.
