# Zemind.Work
Work log

# August 13
## Task 1 Set multiple targets at the same project.
For now, we use the same project **Stuff** as a base project and make changes directly on it. We want to build many projects from this project, how could we do that.

We use multiple targets to solve that.

The step is following:
1. Create multiple targets, following this [How to create multiple targets](http://samwize.com/2014/05/22/create-multiple-targets-slash-apps-for-1-xcode-project/)
2. We use .xcconfig file to add additional flag to provide more info [How to config .xcconfig](http://www.jontolof.com/cocoa/using-xcconfig-files-for-you-xcode-project/)
3. We could use this code in .xcconfig to set our settings, this could affect **Project Build Settings**, also could add variables that could be used at .plist file
4. We use **configuration.plist** to config the source of URL as well as other info, the correct config file could obtained through **Post-Build.sh** e.g debug or release
5. different file could add to different targets.
6. Use combination of plist and xcconfig, to use sources in code.

```
// This is in our .xcconfig
//:configuration = Debug
PRODUCT_NAME = TheCut

DEFAULT_BRAND_COLOUR = #39A32D
DEFAULT_BRAND_NAV_TITLE_COLOUR = #ffffff
DEFAULT_BRAND_NAV_TINT_COLOUR = #ffffff
```
