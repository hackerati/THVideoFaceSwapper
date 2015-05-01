# THVideoFaceSwapper
Live video face swapping on iOS. Choose a face from the preloaded faces, or take one yourself!

![Demo](http://imgur.com/ERkEh9e)

#Building and Running the App
The header search path for the openFramework libs should 3 levels up from this project (`../../..`). Saving this repo within `~/path/to/openFrameworks/apps/myApps/` and building and running the app will most likely work unless you've configured your openFrameoworks directory differently. 

If you want to save you this within a different directory that is not 3 levels below the openFrameworks root, then you will need to change the `OF_PATH` in the `Project.xcconfig` (not recommended).

#Contributing
Only alter the `src` Group within this project. If you add new Groups and/or files, please follow the directions below.

The file structure for this project is maintained via [synx](https://github.com/venmo/synx). It mirrors the abstract Xcode file structure in Finder. When using on this project, there are a number of Groups to exclude due to openFrameworks needing an unaltered file structure. Once you've made your changes within the `src` folder, run `synx -e /openFrameworks -e /addons -e /libs -e /Products THVideoFaceSwapper.xcodeproj/`
This will exclude all of the openFramework Groups.

#Other Notes
###Adding Faces
Faces go into `bin/data/faces/` as a JPG, JPEG or PNG

###Maydayfile
Adds supplemental warnings and errors to your Xcode project via regex. For more info see [mayday](https://github.com/marklarr/mayday)