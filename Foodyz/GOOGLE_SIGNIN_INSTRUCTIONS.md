# Google Sign-In Setup Instructions

The error `Unable to find module dependency: 'GoogleSignIn'` occurs because the **GoogleSignIn** library has not been added to the Xcode project yet.

## 1. Add the Package Dependency
1. Open **Foodyz.xcodeproj** in Xcode.
2. Go to **File > Add Packages...**.
3.  In the search bar at the top right (where it says "Search or Enter Package URL"), paste this URL:
    ```
    https://github.com/google/GoogleSignIn-iOS
    ```
    *Note: Ignore the "swift-algorithms" or other packages that might appear in the list by default.*
4.  Press Enter.
5.  Select **GoogleSignIn-iOS** when it appears in the list.
6.  Click **Add Package**.
5. Ensure the `GoogleSignIn` library is added to the `Foodyz` target.

## 2. Configure Info.plist
You need to add a URL scheme to your `Info.plist` to handle the sign-in redirect.
1. Open **Info.plist** in Xcode.
2. Right-click and choose **Add Row**.
3. Select **URL types**.
4. Expand the item (Item 0) and set **URL Schemes** (Item 0) to your **Reverse Client ID**.
   - You can find the Reverse Client ID in the `GoogleService-Info.plist` file (if you have one) or in the Google Cloud Console.
   - It usually looks like: `com.googleusercontent.apps.YOUR-CLIENT-ID`.

## 3. Code Updates
I have automatically updated `FoodyzApp.swift` to handle the URL redirect:
```swift
.onOpenURL { url in
    _ = GoogleSignInManager.shared.handleURL(url)
}
```

Once you add the package, the build error should disappear.
