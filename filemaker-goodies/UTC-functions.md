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
