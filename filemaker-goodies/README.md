# UTC Conversion

FileMaker Cloud timeStamps are UTC, not local time. Because of this, you may have trouble syncing against timeStamps on your workstation. You may also need to work with FileMaker timeStamp values in Xcode. In either case, you should find these calcs handy. :)

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

I've tested all of the Apple and FileMaker URL schemes, and most of the third-party app schemes (for the apps/services I have). URL schemes can/and sometimes do change, so this list will be updated as needed. If you see something wrong, send me a message. This isn't meant to be an exhaustive list. The aim is to maintain a list of widely used/common apps for reference, for Go and FIAS developers.

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

#### Error Codes (courtesy of Mike Lemm)

How to use in a script
If [ Get(LastError) <> 0 ]
Show Custom Dialog [ "Error!" ; "FileMaker Error # " & Get(LastError) & " " & JSONGetElement ( cf_FM_Errors; Get(LastError)) ]
End If

-----

JSONFormatElements (
JSONSetElement ( "{}" ;
["-1";"Unknown error";JSONString];
["0";"No error";JSONString];
["1";"User canceled action";JSONString];
["2";"Memory error";JSONString];
["3";"Command is unavailable (for example wrong operating system or mode)";JSONString];
["4";"Command is unknown";JSONString];
["5";"Command is invalid (for example a Set Field script step does not have a calculation specified)";JSONString];
["6";"File is read-only";JSONString];
["7";"Running out of memory";JSONString];
["8";"Empty result";JSONString];
["9";"Insufficient privileges";JSONString];
["10";"Requested data is missing";JSONString];
["11";"Name is not valid";JSONString];
["12";"Name already exists";JSONString];
["13";"File or object is in use";JSONString];
["14";"Out of range";JSONString];
["15";"Can't divide by zero";JSONString];
["16";"Operation failed; request retry (for example a user query)";JSONString];
["17";"Attempt to convert foreign character set to UTF-16 failed";JSONString];
["18";"Client must provide account information to proceed";JSONString];
["19";"String contains characters other than A-Z, a-z, 0-9 (ASCII)";JSONString];
["20";"Command/operation canceled by triggered script";JSONString];
["21";"Request not supported (for example, when creating a hard link on a file system that does not support hard links)";JSONString];
["100";"File is missing";JSONString];
["101";"Record is missing";JSONString];
["102";"Field is missing";JSONString];
["103";"Relationship is missing";JSONString];
["104";"Script is missing";JSONString];
["105";"Layout is missing";JSONString];
["106";"Table is missing";JSONString];
["107";"Index is missing";JSONString];
["108";"Value list is missing";JSONString];
["109";"Privilege set is missing";JSONString];
["110";"Related tables are missing";JSONString];
["111";"Field repetition is invalid";JSONString];
["112";"Window is missing";JSONString];
["113";"Function is missing";JSONString];
["114";"File reference is missing";JSONString];
["115";"Menu set is missing";JSONString];
["116";"Layout object is missing";JSONString];
["117";"Data source is missing";JSONString];
["118";"Theme is missing";JSONString];
["130";"Files are damaged or missing and must be reinstalled";JSONString];
["131";"Language pack files are missing";JSONString];
["200";"Record access is denied";JSONString];
["201";"Field cannot be modified";JSONString];
["202";"Field access is denied";JSONString];
["203";"No records in file to print, or password doesn't allow print access";JSONString];
["204";"No access to field(s) in sort order";JSONString];
["205";"User does not have access privileges to create new records; import will overwrite existing data";JSONString];
["206";"User does not have password change privileges";JSONString];
["207";"User does not have privileges to change database schema, or file is not modifiable";JSONString];
["208";"Password does not contain enough characters";JSONString];
["209";"New password must be different from existing one";JSONString];
["210";"User account is inactive";JSONString];
["211";"Password has expired¬†";JSONString];
["212";"Invalid user account and/or password; please try again";JSONString];
["214";"Too many login attempts";JSONString];
["215";"Administrator privileges cannot be duplicated";JSONString];
["216";"Guest account cannot be duplicated";JSONString];
["217";"User does not have sufficient privileges to modify administrator account";JSONString];
["218";"Password and verify password do not match";JSONString];
["300";"File is locked or in use";JSONString];
["301";"Record is in use by another user";JSONString];
["302";"Table is in use by another user";JSONString];
["303";"Database schema is in use by another user";JSONString];
["304";"Layout is in use by another user";JSONString];
["306";"Record modification ID does not match";JSONString];
["307";"Transaction could not be locked because of a communication error with the host";JSONString];
["308";"Theme is locked and in use by another user";JSONString];
["400";"Find criteria are empty";JSONString];
["401";"No records match the request";JSONString];
["402";"Selected field is not a match field for a lookup";JSONString];
["404";"Sort order is invalid";JSONString];
["405";"Number of records specified exceeds number of records that can be omitted";JSONString];
["406";"Replace/reserialize criteria are invalid";JSONString];
["407";"One or both match fields are missing (invalid relationship)";JSONString];
["408";"Specified field has inappropriate data type for this operation";JSONString];
["409";"Import order is invalid";JSONString];
["410";"Export order is invalid";JSONString];
["412";"Wrong version of FileMaker Pro Advanced used to recover file";JSONString];
["413";"Specified field has inappropriate field type";JSONString];
["414";"Layout cannot display the result";JSONString];
["415";"One or more required related records are not available";JSONString];
["416";"A primary key is required from the data source table";JSONString];
["417";"File is not a supported data source";JSONString];
["418";"Internal failure in INSERT operation into a field";JSONString];
["500";"Date value does not meet validation entry options";JSONString];
["501";"Time value does not meet validation entry options";JSONString];
["502";"Number value does not meet validation entry options";JSONString];
["503";"Value in field is not within the range specified in validation entry options";JSONString];
["504";"Value in field is not unique, as required in validation entry options";JSONString];
["505";"Value in field is not an existing value in the file, as required in validation entry options";JSONString];
["506";"Value in field is not listed in the value list specified in validation entry option";JSONString];
["507";"Value in field failed calculation test of validation entry option";JSONString];
["508";"Invalid value entered in Find mode";JSONString];
["509";"Field requires a valid value";JSONString];
["510";"Related value is empty or unavailable";JSONString];
["511";"Value in field exceeds maximum field size";JSONString];
["512";"Record was already modified by another user";JSONString];
["513";"No validation was specified but data cannot fit into the field";JSONString];
["600";"Print error has occurred";JSONString];
["601";"Combined header and footer exceed one page";JSONString];
["602";"Body doesn't fit on a page for current column setup";JSONString];
["603";"Print connection lost";JSONString];
["700";"File is of the wrong file type for import";JSONString];
["706";"EPS file has no preview image";JSONString];
["707";"Graphic translator cannot be found";JSONString];
["708";"Can't import the file, or need color monitor support to import file";JSONString];
["711";"Import translator cannot be found";JSONString];
["714";"Password privileges do not allow the operation";JSONString];
["715";"Specified Excel worksheet or named range is missing";JSONString];
["716";"A SQL query using DELETE, INSERT, or UPDATE is not allowed for ODBC import";JSONString];
["717";"There is not enough XML/XSL information to proceed with the import or export";JSONString];
["718";"Error in parsing XML file (from Xerces)";JSONString];
["719";"Error in transforming XML using XSL (from Xalan)";JSONString];
["720";"Error when exporting; intended format does not support repeating fields";JSONString];
["721";"Unknown error occurred in the parser or the transformer";JSONString];
["722";"Cannot import data into a file that has no fields";JSONString];
["723";"You do not have permission to add records to or modify records in the target table";JSONString];
["724";"You do not have permission to add records to the target table";JSONString];
["725";"You do not have permission to modify records in the target table";JSONString];
["726";"Source file has more records than the target table; not all records were imported";JSONString];
["727";"Target table has more records than the source file; not all records were updated";JSONString];
["729";"Errors occurred during import; records could not be imported";JSONString];
["730";"Unsupported Excel version; convert file to the current Excel format and try again";JSONString];
["731";"File you are importing from contains no data";JSONString];
["732";"This file cannot be inserted because it contains other files";JSONString];
["733";"A table cannot be imported into itself";JSONString];
["734";"This file type cannot be displayed as a picture";JSONString];
["735";"This file type cannot be displayed as a picture; it will be inserted and displayed as a file";JSONString];
["736";"Too much data to export to this format; data will be truncated";JSONString];
["738";"The theme you are importing already exists";JSONString];
["800";"Unable to create file on disk";JSONString];
["801";"Unable to create temporary file on System disk";JSONString];
["802";"Unable to open file";JSONString];
["803";"File is single-user, or host cannot be found";JSONString];
["804";"File cannot be opened as read-only in its current state";JSONString];
["805";"File is damaged; use Recover command";JSONString];
["806";"File cannot be opened with this version of a FileMaker client";JSONString];
["807";"File is not a FileMaker Pro Advanced file or is severely damaged";JSONString];
["808";"Cannot open file because access privileges are damaged";JSONString];
["809";"Disk/volume is full";JSONString];
["810";"Disk/volume is locked";JSONString];
["811";"Temporary file cannot be opened as FileMaker Pro Advanced file";JSONString];
["812";"Exceeded host‚Äôs capacity";JSONString];
["813";"Record synchronization error on network";JSONString];
["814";"File(s) cannot be opened because maximum number is open";JSONString];
["815";"Couldn‚Äôt open lookup file";JSONString];
["816";"Unable to convert file";JSONString];
["817";"Unable to open file because it does not belong to this solution";JSONString];
["819";"Cannot save a local copy of a remote file";JSONString];
["820";"File is being closed";JSONString];
["821";"Host forced a disconnect";JSONString];
["822";"FileMaker Pro Advanced files not found; reinstall missing files";JSONString];
["823";"Cannot set file to single-user; guests are connected";JSONString];
["824";"File is damaged or not a FileMaker Pro Advanced file";JSONString];
["825";"File is not authorized to reference the protected file";JSONString];
["826";"File path specified is not a valid file path";JSONString];
["827";"File was not created because the source contained no data or is a reference";JSONString];
["850";"Path is not valid for the operating system";JSONString];
["851";"Cannot delete an external file from disk";JSONString];
["852";"Cannot write a file to the external storage";JSONString];
["853";"One or more containers failed to transfer";JSONString];
["900";"General spelling engine error";JSONString];
["901";"Main spelling dictionary not installed";JSONString];
["903";"Command cannot be used in a shared file";JSONString];
["905";"Command requires a field to be active";JSONString];
["906";"Current file is not shared; command can be used only if the file is shared";JSONString];
["920";"Cannot initialize the spelling engine";JSONString];
["921";"User dictionary cannot be loaded for editing";JSONString];
["922";"User dictionary cannot be found";JSONString];
["923";"User dictionary is read-only";JSONString];
["951";"An unexpected error occurred (*)";JSONString];
["952";"Invalid FileMaker Data API token (*)";JSONString];
["953";"Exceeded limit on data the FileMaker Data API can transmit (*)";JSONString];
["954";"Unsupported XML grammar (*)";JSONString];
["955";"No database name (*)";JSONString];
["956";"Maximum number of database sessions exceeded (*)";JSONString];
["957";"Conflicting commands (*)";JSONString];
["958";"Parameter missing (*)";JSONString];
["959";"Custom Web Publishing technology is disabled";JSONString];
["960";"Parameter is invalid";JSONString];
["1200";"Generic calculation error";JSONString];
["1201";"Too few parameters in the function";JSONString];
["1202";"Too many parameters in the function";JSONString];
["1203";"Unexpected end of calculation";JSONString];
["1204";"Number, text constant, field name, or \"(\" expected";JSONString];
["1205";"Comment is not terminated with \"*/\"";JSONString];
["1206";"Text constant must end with a quotation mark";JSONString];
["1207";"Unbalanced parenthesis";JSONString];
["1208";"Operator missing, function not found or \"(\" not expected";JSONString];
["1209";"Name (such as field name or layout name) is missing";JSONString];
["1210";"Plug-in function or script step has already been registered";JSONString];
["1211";"List usage is not allowed in this function";JSONString];
["1212";"An operator (for example +, - *) is expected here";JSONString];
["1213";"This variable has already been defined in the Let function";JSONString];
["1214";"Average, Count, Extend, GetRepetition, Max, Min, NPV,StDev, Sum, and GetSummary: expression found where a field alone is needed";JSONString];
["1215";"This parameter is an invalid Get function parameter";JSONString];
["1216";"Only summary fields are allowed as first argument in GetSummary";JSONString];
["1217";"Break field is invalid";JSONString];
["1218";"Cannot evaluate the number";JSONString];
["1219";"A field cannot be used in its own formula";JSONString];
["1220";"Field type must be normal or calculated";JSONString];
["1221";"Data type must be number, date, time, or timestamp";JSONString];
["1222";"Calculation cannot be stored";JSONString];
["1223";"Function referred to is not yet implemented";JSONString];
["1224";"Function referred to does not exist";JSONString];
["1225";"Function referred to is not supported in this context";JSONString];
["1300";"The specified name can't be used";JSONString];
["1301";"A parameter of the imported or pasted function has the same name as a function in the file";JSONString];
["1400";"ODBC client driver initialization failed; make sure ODBC client drivers are properly installed";JSONString];
["1401";"Failed to allocate environment (ODBC)";JSONString];
["1402";"Failed to free environment (ODBC)";JSONString];
["1403";"Failed to disconnect (ODBC)";JSONString];
["1404";"Failed to allocate connection (ODBC)";JSONString];
["1405";"Failed to free connection (ODBC)";JSONString];
["1406";"Failed check for SQL API (ODBC)";JSONString];
["1407";"Failed to allocate statement (ODBC)";JSONString];
["1408";"Extended error (ODBC)";JSONString];
["1409";"Error (ODBC)";JSONString];
["1413";"Failed communication link (ODBC)";JSONString];
["1414";"SQL statement is too long";JSONString];
["1450";"Action requires PHP privilege extension (*)";JSONString];
["1451";"Action requires that current file be remote";JSONString];
["1501";"SMTP authentication failed";JSONString];
["1502";"Connection refused by SMTP server";JSONString];
["1503";"Error with SSL";JSONString];
["1504";"SMTP server requires the connection to be encrypted";JSONString];
["1505";"Specified authentication is not supported by SMTP server";JSONString];
["1506";"Email message(s) could not be sent successfully";JSONString];
["1507";"Unable to log in to the SMTP server";JSONString];
["1550";"Cannot load the plug-in";JSONString];
["1551";"Cannot install the plug-in; cannot delete an existing plug-in or write to the folder or disk";JSONString];
["1552-1559 Returned by plug-ins; see the documentation that came with the plug-in";"";JSONString];
["1626";"Protocol is not supported";JSONString];
["1627";"Authentication failed";JSONString];
["1628";"There was an error with SSL";JSONString];
["1629";"Connection timed out; the timeout value is 60 seconds";JSONString];
["1630";"URL format is incorrect";JSONString];
["1631";"Connection failed";JSONString];
["1632";"The certificate has expired";JSONString];
["1633";"The certificate is self-signed";JSONString];
["1634";"A certificate verification error occurred";JSONString];
["1635";"Connection is unencrypted";JSONString]))


