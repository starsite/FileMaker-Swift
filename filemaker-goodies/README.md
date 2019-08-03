FileMaker Cloud timeStamps are UTC, not local time. Because of this, you may have trouble working with timeStamps on your workstation. You may also want to work with FileMaker Cloud timeStamps in Xcode. In either case, you'll find these calcs handy.


#### UTC -> FileMaker
```
GetAsTimestamp ( ( GetAsNumber ( timestamp_utc ) )

  + GetAsNumber ( Timestamp ( "01/01/1970" ; "00:00:00" ) )
  + GetAsNumber ( Get ( CurrentTimestamp ) )
  - Floor ( Get ( CurrentTimeUTCMilliseconds ) / 1000 ) )
```
- - -
#### FileMaker -> UTC
```
GetAsNumber ( timestamp_fmp ) 
    
  - GetAsNumber ( Timestamp ( "1/1/1970" ; "00:00:00" ) )
  + Floor ( Get ( CurrentTimeUTCMilliseconds ) / 1000 )
  - GetAsNumber ( Get ( CurrentTimestamp ) )
```
- - -
#### Xcode (Swift)
```swift
let dateInt = Int( Date().timeIntervalSince1970 )
```




### UTC-functions
Native FileMaker calcs to convert a FileMaker timeStamp to UTC, and back.
* https://github.com/starsite/SwiftFM/blob/master/filemaker-goodies/UTC-functions.md

- - -

### URL-schemes
A list of URL schemes to use with `Open URL []` to launch other iOS apps
* https://github.com/starsite/SwiftFM/blob/master/filemaker-goodies/URL-schemes.md
