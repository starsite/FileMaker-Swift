# FileMaker iOS App SDK + Swift AppDelegate

Create and use a Swift `AppDelegate` in a FIAS project. Also shows an example of how to fire a FileMaker script from the `completedReturnToForegroundActive()` delegate method.

🔥 Updated for Xcode 11

In older versions of Xcode, obtaining the symbolic name for a Swift AppDelegate required using the command line utility `otool`, which is no longer available (staring with Xcode 10). This walkthrough has been updated for Xcode 10 and 11 and uses the `objdump` tool.

- - -

### What You'll Learn
* How to build a simple FIAS project in Xcode with a Swift AppDelegate.
* How to trigger a script from the AppDelegate.
 
### What This Post Is Not
* A tutorial on Xcode
* A tutorial on Swift
* A tutorial on Terminal
 
### Requirements
* iOS App SDK 17+
* Xcode 10+
 
### What We're Going To Do
* Navigate to our FIAS directory and create a project
* Add a Swift AppDelegate class
* Create and edit a `Bridging-Header.h`
* Finish the AppDelegate class
* Build (test)
* Navigate to `.../DerivedData/.../MyProject.app/`
* Get an object reference for our AppDelegate using `objdump`
* Assign our AppDelegate reference in `configFile.txt`
* Build and run app
* Profit!

* Not plagiarize other developers' work with a blog post (ahem). If you find this walkthrough helpful, link back to it, or write your own tutorial. Please and thank you. ❤️
 
- - -
 
### Ok, Let's Make A Project

In Terminal, cd to your FIAS directory, wherever that is. Mine lives in `/Applications`, so:
<pre>cd /Applications/iOSAppSDKPackage_18.0.3</pre>

Create a project. Leading dot, yo.
<pre>./makeprojdir ProjectDirectory MyProject com.domain.MyProject</pre>

After FIAS returns a prompt, you can open the project with:
<pre>open ProjectDirectory/MyProject.xcodeproj</pre>

- - -
 
### Xcode: Create AppDelegate

In the Project Navigator (left sidebar), right-click on the Custom Application Resources folder and choose `New File`. This will be our AppDelegate class. Choose `Swift File`, name it `SwiftAppDelegate`, and click Create. In earlier versions of Xcode, this used to fire a prompt about a bridging header. If Xcode gives you a bridging header prompt, choose `Create Bridging Header` and name it `MyProject-Bridging-Header.h`. Mind the naming convention here, it's not optional. It's always `<projectName>-Bridging-Header.h`
 
- - -

### Xcode: Create Bridging Header (if necessary)

If Xcode _didn't_ prompt you about a bridging header, we need to create it ourselves.

In the Project Navigator (left sidebar), right-click on the Custom Application Resources folder and choose `New File`. Select `Header File` as the type and click Next. Save the file as `<projectName>-Bridging-Header.h`, again, minding the naming convention. Then click Create.

Because we created our bridging header manually, we also need to update our build settings. Select your project name (topmost item in the ProjectNavigator). Select your target, then click the `Build Settings` tab (top center). Scroll down and find `Swift Compiler - General`. Double click the empty space next to `Objective-C Bridging Header` to open a popover. From the Project Navigator (left sidebar), drag `MyProject-Bridging-Header.h` into the popover. That will ensure the correct path is set, without any typos.

- - -
 
### Xcode: Edit Bridging Header

Open `MyProject-Bridging-Header.h` from the Project Navigator and add these 2 import statements:

```objective-c
#import "UIKit/UIKit.h"
#import "FMX_Exports.h"
```

Build the project (Command-B). You shouldn't have any errors.
 
- - -
 
### Xcode: Edit SwiftAppDelegate
Open `SwiftAppDelegate.swift` from the Project Navigator and finish it out like this (updated for Swift 5):

```swift
import Foundation

class SwiftAppDel: UIResponder, UIApplicationDelegate {
   
    var window: UIWindow?
    
    // did finish launching
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
        print("\n\n swift app delegate! \n\n") // disco!
        
        return true
    }
    
    
    // return foreground active.. this is a FIAS delegate and not part of UIKit
    func completedReturnToForegroundActive() {
 
        print("return foreground active!")
        
        // fire a script, requires fmurlscript extended privilege in your fmp12 file
        FMX_Queue_Script("PlaceHolder.fmp12", "MyScript", FMX_ScriptControl(kFMXT_Resume), nil, nil) 
    }
}
```
 
 
 
 
Build Project (Command-B). Take care of any errors or typos before proceeding.
 
- - -
 
### Terminal: Navigate To DerivedData

`/DerivedData` is where Xcode stores your project build data. The FileMaker iOS App SDK (currently 18.0.3) is _still_ based on Objective-C. Boo. In order to get FIAS to 'see' our SwiftAppDelegate, we'll need to use a command line tool called `objdump`. First, cd to DerivedData/ all-the-way-to /MyProject.app (*MyProject.app is a directory*):
<pre>> cd ~/Library/Developer/Xcode/DerivedData/MyProject-gznmjbw.../Build/Products/Release-iphoneos/MyProject.app/</pre>

If you're familiar with Terminal, this can all be done rather quickly using [tab] auto-complete.
 
- - -
 
### Terminal: Get Object Reference To SwiftAppDelegate

When you've successfully landed in the `MyProject.app` directory, do this:
<pre>objdump -all-headers MyProject</pre>

This outputs a _ton_ of metadata for the MyProject Unix executable inside of `MyProject.app`. What we need is the symbolic name of our AppDelegate. Do a `[Command] + [F]`, and search for `_OBJC_CLASS_`. Don't forget the underscores. Depending on the folder stucture of your project, you may need to `[Command] + [G]` a couple times to cycle through the matches. Be on the lookout for something like this:

<pre>_OBJC_CLASS_$__TtC4MyProject10SwiftAppDelegate`</pre>

The value we need here is the `TtC4MyProject10SwiftAppDelegate`. Copy it to your clipboard.
 
- - -
 
### Xcode: Update FIAS Config File

Return to Xcode, select `configFile.txt` from the Project Navigator, and update these settings:

```
launchSolution           = PlaceHolder.fmp12 (or your solution file)
solution CopyOption      = 1
applicationDelegateClass = _TtC4MyProject10SwiftAppDelegate   // Add -one- leading underscore
```

- - -

### Xcode: Run

Click the 'Play' button in Xcode (or Command-R) to run the project. Shortly after your app launches you should see a "swift app delegate!" message in the console/debug area. High-five yourself or the person nearest you.
 
Now press your device Home button and re-launch the app (from the device). This time, `completedReturnToForegroundActive()` should fire and post a "return foreground active!" message to the console. If you go back and include a 'MyScript' in your solution, it should fire.

Note: Firing scripts from a FIAS app requires the `fmurlscript` permission to be selected in your .fmp12 solution.
 
- - -
 
### Further Reading

There are lots of iOS app lifecycle (delegate) methods. You can read more about them here:

https://developer.apple.com/documentation/uikit/uiapplicationdelegate
  
- - -
 
### Extra Credit
Here's a peek at the `FMX_Exports.h` Objective-C header, to give you an idea how `FMX_Queue_Script()` works.
 
My last two `nil` arguments in the Swift example (above) are for a script parameter and a variables Dictionary, respectively. The script parameter object is typed as a `String`. The Dictionary is typed as `[String: String]`, instead of the more common `[String: Any]` you might expect. Also note that the Swift `FMX_Queue_Script()` function signature varies slightly from its Objective-C counterpart. This is because Swift needs to cast `kFMXT_Resume` back to a `UInt8`.
 
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
