# Klang - Soundboard Widget

Klang uses the interactive widget introduced in iOS 17 to add a soundboard straight to your home screen (and lock screen). You can create sounds or import them and organize your sounds into boards. 

## Requirements
- iOS 17 or later
- Xcode 15 or later

## Installation

If you only want to use the app (not develop it), the easiest way is to join the TestFlight beta:  https://testflight.apple.com/join/tAlSw1v8

In case, you want to run the app locally, make sure to follow these instructions to get code signing to work:

1. Clone the repository.

2. Open the file `Klang.xcodeproj` in Xcode.

3. In the left sidebar, click on `Klang` under "PROJECT".

4. In the main panel, go to `Signing & Capabilities`. 

5. In the `Team` dropdown list, select your name/organization.

6. Connect your iOS device to your Mac, and select it from the dropdown menu in the toolbar.

7. Press ⌘R or click `Product` > `Run` from the menu. 

8. Once complete, Klang will be installed on your iOS device.

## Contributing & License
While Klang is open-source, and you are free to use code and files from the app within your projects, redistribution of the Klang app itself, with minor or even considerable changes, is strictly prohibited. I'm yet to find a good license that reflects this policy, so recommendations are welcome.

If you're interested in contributing to the improvement and development of Klang, kindly fork the repository, make your changes, and submit a pull request.

I'm also looking to add a pre-built library of soundboards to the app, but I lack the skill to compile this myself. If you are interested in contributing here, please let me know!

## Roadmap

The goal is to launch Klang on the App Store when iOS 17 launches. Until then, I want to try to add the following features.

- [ ] Soundboard Library (pre-built soundboards of different topics)
- [ ] Trimming and Normalizing Sounds

You are welcome to suggest more features in GitHub issues!
