# UTC Conversion

FileMaker Cloud timeStamps are UTC, not local time. Because of this, you may have trouble syncing against timeStamps on your workstation. You may also need to work with FileMaker timeStamp values in Xcode. In either case, you should find these calcs handy. 🙂

#### FileMaker » UTC

```
GetAsNumber ( timestamp_fmp ) 
    
  - GetAsNumber ( Timestamp ( "1/1/1970" ; "00:00:00" ) )
  + Floor ( Get ( CurrentTimeUTCMilliseconds ) / 1000 )
  - GetAsNumber ( Get ( CurrentTimestamp ) )
```

#### UTC » FileMaker
```
GetAsTimestamp ( ( GetAsNumber ( timestamp_utc ) )

  + GetAsNumber ( Timestamp ( "01/01/1970" ; "00:00:00" ) )
  + GetAsNumber ( Get ( CurrentTimestamp ) )
  - Floor ( Get ( CurrentTimeUTCMilliseconds ) / 1000 ) )
```

#### Xcode (Swift)
```swift
let dateInt = Int( Date().timeIntervalSince1970 )
```

- - -
# URL schemes for Go, App SDK, and Swift

I've tested all of the Apple and FileMaker URL schemes, and most of the third-party app schemes (for the apps/services I have). URL schemes can, and sometimes do, change, so this list will be updated as needed. If you see something wrong, send me a message. This isn't meant to be an exhaustive list. The aim is to maintain a list of widely used/common apps for reference, for Go and FIAS developers.

How to use: In any FileMaker Go or FIAS app, add a URL scheme to a simple `Open URL []` script step. The corresponding app, if present on device, will launch. All of these will work with no parameters if you simply want to open an app to no particular destination. Others can take a variety of parameters. I've included a few that I use regularly.


#### Apple
```swift
Apple Music     - music://geo.itunes.apple.com/us/albums/<albumID>
                - music://geo.itunes.apple.com/us/artists/<artistID>
 
Apple News      - applenews://
App Store       - itms-apps://itunes.apple.com/app/<appID>
Apple TV        - videos://
Calendar        - calshow://
Calendar (Add)  - webcal://<calendarURL>
Contacts        - (no API or scheme available outside of Swift)
iBooks          - ibooks:// or itms-books://
iTunes Remote   - remote://
Maps            - map:// or maps://
Mail            - message:// or mailto://
 
Messages        - sms://<1234567890>   (digits only, ex. sms://8885551212)
                - sms://<1234567890>&body=<hello>
 
Notes           - mobilenotes://
Phone           - tel://<1234567890>   (digits only)
Photos          - photos-redirect://
Reminders       - x-apple-reminder://
Safari          - http:// or https://   (Swift and FIAS only, Go apps will present a web viewer)
Safari (FTP)    - ftp://
Settings        - App-prefs://   (case sensitive!)
Wallet          - shoebox://
```

#### Third-Party
```swift
Airbnb          - airbnb://rooms/<listingID>  (can an airbnb user confirm this one, please?)
 
Facebook        — fb://profile?id=<pageID>    (numeric *page* ID, can't open personal profiles)
                – fb://event?id=<eventID>     (numeric event ID)
 
Gmail           — googlegmail://
Google          — google://
Google Calendar — googlecalendar://
Google Docs     — googledocs://
Google Chrome   — googlechrome://
Google Drive    — googledrive://
Google Maps     — googlemaps://
Google Photos   — googlephotos://
Google Voice    — googlevoice://
Instagram       — instagram://user?username=<userID>
Messenger       — fb-messenger://
Netflix         — nflx://
PayPal          — paypal://
Pinterest       — pinterest://
Signal          — sgnl://
Skype           — skype://
Snapchat        — snapchat://
 
Spotify         — spotify://spotify:album:<albumID>
                – spotify://spotify:artist:<artistID>
 
Tumblr          – tumblr://
Twitter         — twitter://user?screen_name=<userID>
TweetBot        — tweetbot://
Waze            — waze://
WhatsApp        — whatsapp://
YouTube         – youtube://watch?v=<videoID>
```

#### FileMaker
```swift
fmp://<hostName>/<fileName>   // .fmp12 not required
fmp://<user>:<pass>@<hostName>/<fileName>
fmp://<hostName>/<fileName>?script=<scriptName>&param=<parameter>
fmp://<hostName>/<fileName>?script=<scriptName>&variable=<variable>
fmp://~/<fileName>   // an unopened file, from ~/Documents
fmp://$/<fileName>   // currently open file
```
