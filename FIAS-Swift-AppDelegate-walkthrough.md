# FileMaker iOS App SDK + Swift AppDelegate

Updated for the FileMaker 19 SDK 🎉

In this walkthrough, you'll learn how to create and use a Swift AppDelegate in a FIAS project. Includes an example of how to fire a FileMaker script using `FMX_Queue_Script` from `applicationDidBecomeActive()`.

In older versions of Xcode, obtaining the symbolic header name for a Swift AppDelegate required using the command line utility `otool`, which is no longer available (starting with Xcode 10). This walkthrough has been updated for Xcode 11 and uses the `objdump` tool.

---

### What You'll Learn

* How to build a simple FIAS project in Xcode with a Swift AppDelegate.
* How to trigger a script from `MyAppDelegate.swift`.

### What This Post Is Not

* A tutorial on Xcode
* A tutorial on Swift
* A tutorial on Terminal

### Requirements

* iOS App SDK 17+
* Xcode 10+

### What We're Going To Do

* Navigate to our FIAS directory and create a project
* Add a Swift AppDelegate
* Create and edit a `Bridging-Header.h`
* Finish the `MyAppDelegate.swift` class
* Build (test)
* Navigate to `.../DerivedData/.../MyProject.app/`
* Get an object reference for our AppDelegate using `objdump`
* Assign our AppDelegate reference in `configFile.txt`
* Build and run app
* Profit!
* Not plagiarize other developers' work with a blog post (ahem). If this walkthrough is helpful, give it a ⭐️, link back to it, or write your own tutorial. Please and thank you. ❤️

---

### Ok, Let's Make A Project

In Terminal, cd to your FIAS directory, wherever that is. Mine lives in `/Applications`, so:

```html
cd /Applications/iOSAppSDKPackage_19.0.10088
```

Create a project. Leading dot, yo.

```html
./makeprojdir ~/Desktop/ProjectDirectory MyProject com.domain.MyProject
```

After FIAS returns a prompt, you can open the project with:
```html
open ~/Desktop/ProjectDirectory/MyProject.xcodeproj
```

---

### Xcode: Create AppDelegate

In the Project Navigator (left sidebar), right-click on the Custom Application Resources folder and choose `New File`. This will be our AppDelegate class. Choose `Swift File`, name it `MyAppDelegate`, and click Create. In earlier versions of Xcode, this used to fire a prompt about a bridging header. If Xcode gives you a bridging header prompt, create one and name it `MyProject-Bridging-Header.h`. Mind the naming convention here, it's not optional. It's always `<projectName>-Bridging-Header.h`

---

### Xcode: Create Bridging Header (if necessary)

If Xcode _didn't_ prompt you about a bridging header, we need to create one.

In the Project Navigator (left sidebar), right-click on the Custom Application Resources folder and choose `New File`. Select `Header File` as the type and click Next. Save the file as `<projectName>-Bridging-Header.h`, again, minding the naming convention. Then click Create.

Because we created our bridging header manually, we also need to update our build settings. Select your project (topmost item in the ProjectNavigator). Select your target, then click `Build Settings - All` (top center). Scroll down to `Swift Compiler - General`. Double click the empty space next to `Objective-C Bridging Header` to open a popover. From the Project Navigator, drag `MyProject-Bridging-Header.h` into the popover. That will ensure the correct path is set, without any typos.

---

### Xcode: Edit Bridging Header

Open `MyProject-Bridging-Header.h` from the Project Navigator and add these 2 import statements after the `#define` statement:

```objective-c
#import "UIKit/UIKit.h"
#import "FMX_Exports.h"
```

Build the project (Command-B). You shouldn't have any errors.

---

### Xcode: Edit MyAppDelegate
Open `MyAppDelegate.swift` from the Project Navigator and finish it out like this (Swift 5):

```swift
import Foundation

class MyAppDelegate: UIResponder, UIApplicationDelegate {
   
    var window: UIWindow?
    
    // did finish launching
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
        print("\n\n swift app delegate! \n\n") // disco!
        
        return true
    }
    
    
    // return foreground active - doesn't work anymore, proprietary FIAS delegate (not part of UIKit)
    func completedReturnToForegroundActive() {
 
        print("return foreground active! - FIAS")
        
        // fire a script, requires fmurlscript extended privilege in your fmp12 file
        FMX_Queue_Script("PlaceHolder.fmp12", "MyScript", FMX_ScriptControl(kFMXT_Resume), nil, nil) 
    }
    
    
    // did become active - standard UIKit delegate, which now fires correctly for FIAS projects. Hooray!
    func applicationDidBecomeActive(_ application: UIApplication) {
    
        print("did become active! - UIKit")

        // fire a script, requires fmurlscript extended privilege in your fmp12 file
        FMX_Queue_Script("PlaceHolder.fmp12", "MyScript", FMX_ScriptControl(kFMXT_Resume), nil, nil) 
    }
}
```

 Build Project (Command-B). Take care of any errors or typos before proceeding.

---

### Terminal: Navigate To DerivedData

`/DerivedData` is where Xcode stores your project build data. The FileMaker iOS App SDK (currently 19.0.10088) is _still_ based on Objective-C. Boo. 👎 In order to get FIAS to 'see' our Swift AppDelegate, we need to use a command line tool called `objdump`. First, cd to DerivedData/ all-the-way-to /MyProject.app (*MyProject.app is a directory*):

```html
cd ~/Library/Developer/Xcode/DerivedData/MyProject-gznmjbw.../Build/Products/Release-iphoneos/MyProject.app/
```

If you're familiar with Terminal, this can be done rather quickly using [tab] auto-complete.

---

### Terminal: Get Object Reference To MyAppDelegate

Once you've successfully landed in the `MyProject.app` directory, try this:
```html
objdump -all-headers MyProject
```
If you have a more recent version of objdump, you may need to use _this_ instead:
```html
objdump -t MyProject
```

This outputs a ton of metadata for the Unix executable inside of `MyProject.app`. What we need is the symbolic header name for our AppDelegate. Do a `[Command] + [F]` and search for `_OBJC_CLASS_`. Don't forget the underscores. You may need to `[Command] + [G]` a couple times to cycle through the matches. Be on the lookout for something like this 🔎:

```html
_OBJC_CLASS_$__TtC4MyProject10SwiftAppDel
```

The value we need here is the `TtC4MyProject10SwiftAppDel`. Copy it to your clipboard. 🚨 _This changed slightly in the 19 SDK. In previous SDKs, it appears as `TtC4MyProject10SwiftAppDelegate`._

---

### Xcode: Update FIAS Config File

Return to Xcode, select `configFile.txt` from the Project Navigator, and update these settings:

```
launchSolution           = PlaceHolder.fmp12 (or your solution file)
solution CopyOption      = 1
applicationDelegateClass = _TtC4MyProject10SwiftAppDel   // Add -one- leading underscore
```

---

### Xcode: Run

Click the 'Play' button in Xcode (or Command-R) to run the project. Shortly after your app launches you should see a "swift app delegate!" message in the console/debug area. High-five yourself or the person nearest you. 🤚

🚨 _Now that the iOS App SDK (v19) supports the UIKit standard `applicationDidBecomeActive()` delegate, you should also get a "did become active!" message. If you go back and include a 'MyScript' in your solution, that should fire as well._

Note: Firing scripts from a FIAS app requires the `fmurlscript` permission to be selected in your .fmp12 solution.

🚨 _In the 18 (and 19) SDK, FileMaker's proprietary `completedReturnToForegroundActive()` delegate method no longer fires (as it did in older SDKs). It's possible this delegate was removed, since the standard UIKit delegate `applicationDidBecomeActive()` now fires correctly for FIAS projects. Hard to say. FIAS is a black box, so I don't know, really. Just a hunch._

---

### Further Reading

There are lots of iOS app lifecycle delegate methods. You can read more about them here:

https://developer.apple.com/documentation/uikit/uiapplicationdelegate

---

### Extra Credit
Here's a peek at the `FMX_Exports.h` Objective-C header, to give you an idea how `FMX_Queue_Script()` works.

My last two `nil` arguments in `MyAppDelegate.swift` (above) are for a script parameter and a variables Dictionary, respectively. The script parameter object is typed as a `String`. The Dictionary is typed as `[String: String]`, instead of the more common `[String: Any]` you might expect. Also note that the Swift `FMX_Queue_Script()` function signature varies slightly from its Objective-C counterpart. This is because Swift needs to cast `kFMXT_Resume` back to a `UInt8`.

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
