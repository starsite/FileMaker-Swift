# FIAS Swift App Delegate

### What You'll Learn
* How to build a simple FIAS project in Xcode with a Swift App Delegate.
* How to trigger a script from the App Delegate.
 
### What This Post Is Not
* A tutorial on Xcode
* A tutorial on Swift
* A tutorial on Terminal
 
### Requirements
* iOS App SDK 17+ /comment
* Xcode 9+
 
### Here's What We're Going To Do
* Navigate to FIAS directory and create a project
* Add a Swift App Delegate class
* Edit `Bridging-Header.h`
* Finish the App Delegate class
* Build (test)
* Navigate to `../DerivedData/../MyProject.app`
* Get an object reference for our App Delegate using `otool`
* Assign object reference in `configFile.txt`
* Build and run app
* Profit! (lol)
 
- - -
 
### Ok, Let's Make A Project!

In Terminal, cd to your FIAS directory, wherever that is. Mine lives in `/Applications`, so:
<pre>> cd /Applications/iOSAppSDKPackage_17.0.2</pre>

Create a project.
<pre>> ./makeprojdir MyDirectory MyProject com.domain.MyProject</pre>

After FIAS returns a prompt, you can open the project with:
<pre>> open MyDirectory/MyProject.xcodeproj</pre>
 
- - -
 
### Xcode: Create SwiftAppDel File

In the Project Navigator (left sidebar), right-click on the Custom Application Resources folder and choose `New File`. This will be our Swift App Delegate class. Choose `Swift File`, name it `SwiftAppDel`, and click Create. Xcode will ask you about adding a bridging header. Choose `Create Bridging Header`.
 
This will drop you off in `SwiftAppDel.swift`. We can't do anything in here yet, we'll come back in a minute.
 
- - -
 
### Edit Bridging-Header.h

Open `MyProject-Bridging-Header.h` from the Project Navigator and add these 2 import statements:

```objective-c
#import "UIKit/UIKit.h"
#import "FMX_Exports.h"
```

Build the project (Command-B) and watch for errors. You shouldn't have any.
 
- - -
 
### SwiftAppDel Class
Open `SwiftAppDel.swift` from the Project Navigator and build it out like this:

```swift
import Foundation
 
 
class SwiftAppDel: UIResponder, UIApplicationDelegate {
   
    var window: UIWindow?
 
 
    // did finish launching
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
       
        // disco!
        print("swift app delegate!)
 
        return true
    }
    
 
    //return foreground active -> this is a FIAS delegate function and not part of UIKit
    func completedReturnToForegroundActive() {
 
        print("return foreground active!")
 
        // firing a script requires the 'fmurlscript' extended privilege in your fmp12 file
        FMX_Queue_Script("PlaceHolder.fmp12", "MyScript", FMX_ScriptControl(kFMXT_Resume), nil, nil) 
    }
}
```
 
 
 
 
Build Project (Command-B). Take care of any errors or typos before proceeding.
 
- - -
 
### Terminal: Navigate To DerivedData/...

`/DerivedData` is where Xcode stores project build data. To get FIAS to 'see' our Swift App Delegate, we need to use a command line tool called `otool`. First, cd to DerivedData/ all-the-way-to /MyProject.app (which is a directory):
<pre>> cd ~/Library/Developer/Xcode/DerivedData/MyProject-gznmjbw.../Build/Products/Release-iphoneos/MyProject.app/</pre>

If you're familiar with Terminal, this can all be done rather quickly using [tab] auto-complete.
 
- - -
 
### Get Object Reference To SwiftAppDel

When you've successfully landed in `MyProject.app`, do this:
<pre>> otool -o MyProject</pre>

This outputs metadata for the `MyProject` Unix executable inside of `MyProject.app`. Check the output for a reference like `_TtC4MyProject10SwiftAppDel`. Copy this value to the clipboard. Include the leading underscore.
 
- - -
 
### Xcode: Update FIAS Config File

Return to Xcode, open `configFile.txt` from the Project Navigator, and update these settings:

```
launchSolution           = PlaceHolder.fmp12 (or your solution file)
solution CopyOption      = 1
applicationDelegateClass = _TtC4MyProject10SwiftAppDel
```

- - -

### Run (Command-R)

Click the 'Play' button in Xcode (or Command-R) to run the project. Shortly after your app launches you should see a "swift app delegate!" message in the console/debug area. High-five yourself or the person nearest you.
 
Now press your device Home button and re-launch the app (from the device). This time, `completedReturnToForegroundActive()` should fire and post a "return foreground active!" message to the console. If you go back and include a 'MyScript' in your solution file (and enable fmurlscript), that will fire as well.
 
- - -
 
### Further Reading

There are lots of app lifecycle (delegate) methods. You can read more about them here:

https://developer.apple.com/documentation/uikit/uiapplicationdelegate
 
Happy Coding! 
 
- - -
 
### Extra Credit
Here's a peek at the `FMX_Exports.h` Objective-C header, to give you an idea how `FMX_Queue_Script()` works.
 
My last two `nil` arguments in the Swift example (above) are for a script parameter and a variables dictionary, respectively. The script parameter is typed as String. The dictionary is typed `[String: String]`, instead of the more common `[String: Any]` you might expect. Also note that the Swift `FMX_Queue_Script()` function signature varies slightly from its Objective-C counterpart. This is because Swift is casting `kFMXT_Resume` back to UInt8.
 
```objective-c
#ifndef FMX_Exports_h
#define FMX_Exports_h
 
#ifndef _h_Extern_
typedef unsigned char  FMX_ScriptControl;
enum
{
    kFMXT_Halt,
    kFMXT_Exit,
    kFMXT_Resume,
    kFMXT_Pause
};
#endif
 
// FMX_Queue_Script
//
// Queues script <scriptName> from file <fileName> to be queued to run.
// Parameter scriptParam will be passed to the script as a parameter.  scriptParam may be nil.
// The variables dictionary, if non-nil, supplies one or more local variables with values which
// will be set during execution of the script.
// The user account must have FMURLScript extended privilege. ** emphasis mine **
// Returns true if the script was successfully queued.
 
extern bool FMX_Queue_Script(NSString *fileName, NSString *scriptName, FMX_ScriptControl control, NSString *scriptParam, NSDictionary<NSString *, NSString *> *variables);
 
#endif /* FMX_Exports_h */
```
