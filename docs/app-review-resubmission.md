# App Review Resubmission Notes

Use this checklist and reply text for the July 2026 rejection items.

Rejection items:
- Guideline 1.5: Support URL in App Store Connect was not accepted.
- Guideline 2.1: App Review needs a demo video recorded on a physical iOS device for version 1.0 (1).

## 1) Fix Support URL in App Store Connect

Set Support URL to a functional, public GitHub Pages support page. Do not use the repository top page or GitHub blob page as the Support URL.

Recommended URL:
- https://gaaaaax4.github.io/twist-ios/

Before resubmitting, open the URL in a private/incognito browser window and confirm it shows the Twist Support page without requiring a GitHub login. The page should clearly say users can ask questions, report problems, and request support.

GitHub Pages setup:
1. Commit and push the Pages files to the `main` branch.
2. Open GitHub repository Settings -> Pages.
3. Set Source to "Deploy from a branch".
4. Set Branch to "main" and Folder to "/docs".
5. Save and wait for the deployment to complete.
6. Open https://gaaaaax4.github.io/twist-ios/ in a private/incognito browser window.

If the URL returns 404, check these first:
- the Pages changes have been pushed to GitHub
- GitHub Pages is enabled for `main` / `/docs`
- the Pages deployment has completed successfully
- a few minutes have passed since enabling Pages

If GitHub Pages is not accepted again, publish the same content on another simple public webpage, for example a personal website page or a Notion/Google Sites page that is publicly readable without login.

## 2) Provide Demo Video Link

Add a demo video link in:
- App Store Connect -> App Review Information -> Notes

Also include the same demo video link in the reply to App Review.

Video requirements from App Review:
- Recorded on a physical iOS device (not simulator)
- Shows all core app features
- Shows permission prompts and flows
- Uses the current submitted version, 1.0 (1)
- Matches the build currently submitted for review

Recommended hosting:
- Unlisted YouTube video
- Public Google Drive link with "Anyone with the link can view"
- Public Dropbox/iCloud shared link that does not require sign-in

Before resubmitting, test the video link in a private/incognito browser window.

## 3) Demo Video Recording Script (Suggested)

Record on a physical iOS device. App Review used an iPhone 17 Pro Max for this review, so use a physical iPhone if available. Do not use a simulator.

Suggested flow:
1. Show the physical device home screen and open Twist.
2. Show the initial screen.
3. Start the screenshot selection flow.
4. Show the Photo Library permission prompt or limited photo picker flow, then grant/select access.
5. Select a Spotify playlist screenshot from Photos.
6. Show the OCR-recognized track list or the selected screenshot state.
7. Enter a playlist name if the app asks for one.
8. Tap Convert and show the progress screen.
9. Show the Apple Music permission prompt and grant permission.
10. Show the conversion result:
- created track count
- skipped tracks list, if any
11. Open Apple Music and show the created playlist.
12. If ads appear in this build, briefly show the ad area so App Review sees the current version accurately.

If a permission was already granted on the device, reset it before recording or mention in Notes that the permission had already been granted on the recording device.

## 4) App Review Information Notes Field Template

Paste this in:
- App Store Connect -> App Review Information -> Notes

Demo video recorded on a physical iOS device for Twist version 1.0 (1):
[PASTE_VIDEO_LINK_HERE]

The video demonstrates the current app flow, including Photo Library access, Apple Music authorization, screenshot OCR, playlist creation, and confirmation of the created playlist in Apple Music.

Support URL:
https://gaaaaax4.github.io/twist-ios/

## 5) Reply Message to Apple (English Template)

Hello App Review Team,

Thank you for your review.

We have addressed both issues:

1. Support URL updated
- We updated the Support URL to a functional support page where users can ask questions, report issues, and request support:
https://gaaaaax4.github.io/twist-ios/

2. Demo video provided
- We provided a new demo video recorded on a physical iOS device using version 1.0 (1).
- The video demonstrates the complete app flow, including Photo Library access, Apple Music authorization, screenshot OCR, playlist creation, and the final playlist in Apple Music.
- Demo video link:
[PASTE_VIDEO_LINK_HERE]

We also added this video link to the App Review Information Notes field in App Store Connect.

Please let us know if any additional information is required.

Best regards,
Twist Developer

## 6) Reply Message to Apple (Japanese Template)

App Review Team

レビューありがとうございます。ご指摘の2点を対応しました。

1. Support URLの更新
- 質問、問題報告、サポート依頼ができる有効なサポートページに更新しました。
https://gaaaaax4.github.io/twist-ios/

2. デモ動画の提出
- バージョン1.0 (1)を実機iOSデバイスで撮影したデモ動画を用意しました。
- Photo Libraryへのアクセス、Apple Musicの認可、スクリーンショットのOCR、プレイリスト作成、Apple Music上で作成されたプレイリストの確認まで、主要機能の動作を確認できる内容です。
- デモ動画リンク:
[PASTE_VIDEO_LINK_HERE]

この動画リンクは、App Store ConnectのApp Review InformationのNotes欄にも追記しました。

追加で必要な情報があればご連絡ください。

よろしくお願いいたします。
