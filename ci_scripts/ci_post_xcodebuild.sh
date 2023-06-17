#!/bin/zsh
#  ci_post_xcodebuild.sh


if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
  TESTFLIGHT_DIR_PATH=../TestFlight
  KNOWN_ISSUES="
  - There is a bug in iOS where sometimes the audio session fails to activate after a few button presses in the widget. Then you'll have to force close the app and try again. I've filed a radar!
  "
  mkdir $TESTFLIGHT_DIR_PATH
  echo -e "You are getting the latest updates to Klang hot off the press! Here is what has changed recently:\n" > $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  git fetch --deepen 3 
  git log -3 --pretty=format:"%s%n%b%n" >> $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  echo -e "** Known Issues **$KNOWN_ISSUES\n" >> $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  echo -e "Thanks for testing and let me know what else you would like to see." >> $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
fi