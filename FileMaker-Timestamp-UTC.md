#### Unix -> FileMaker
```
GetAsTimestamp ( ( GetAsNumber ( timestamp_unix ) )

  + GetAsNumber ( Timestamp ( "01/01/1970" ; "00:00:00" ) )
  + GetAsNumber ( Get ( CurrentTimestamp ) )
  - Floor ( Get ( CurrentTimeUTCMilliseconds ) / 1000 ) )
 

#### FileMaker -> Unix
GetAsNumber ( timestamp_fmp ) 
    
  - GetAsNumber ( Timestamp ( "1/1/1970" ; "00:00:00" ) )
  + Floor ( Get ( CurrentTimeUTCMilliseconds ) / 1000 )
  - GetAsNumber ( Get ( CurrentTimestamp ) )


#### Xcode, Swift
let dateInt = Int( Date().timeIntervalSince1970 )
```
