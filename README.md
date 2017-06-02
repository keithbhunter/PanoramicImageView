# PanoramicImageView
A simple image view to display [equirectangular](http://wiki.panotools.org/Panorama_formats) panoramic images using SceneKit. Supports pan gesture movemnet by default and can easily add core motion to allow device movement control as well. Example code included.

Example equirectangular image:

![](https://github.com/keithbhunter/PanoramicImageView/blob/master/Example/PanoramicImageView/room.jpg)

photo credit: jamescastle <a href="http://www.flickr.com/photos/24128368@N00/34645545782">Chancel of St. Andrew's Episcopal Church</a> via <a href="http://photopin.com">photopin</a> <a href="https://creativecommons.org/licenses/by-nc-sa/2.0/">(license)</a>

Rendered by `PanoramicImageView`:

![](https://github.com/keithbhunter/PanoramicImageView/blob/master/room.gif)

### Usage

Simply add the `PanoramicImageView` like you would any other view and set the image.

```
let imageView = PanoramicImageView()
imageView.image = // your image
view.addSubview(imageView)
```

To add device motion control, start a motion manager and apply the motion data.

```
motionManager.startDeviceMotionUpdates(to: .main) { deviceMotion, error in
	imageView.deviceMotion = deviceMotion
}
```

### Acknowledgements

Original idea for image mapping: [http://iosdeveloperzone.com/2016/05/02/using-scenekit-and-coremotion-in-swift/](http://iosdeveloperzone.com/2016/05/02/using-scenekit-and-coremotion-in-swift/)

Math from: [https://github.com/alfiehanssen/ThreeSixtyPlayer](https://github.com/alfiehanssen/ThreeSixtyPlayer) and [https://gist.github.com/travisnewby/96ee1ac2bc2002f1d480](https://gist.github.com/travisnewby/96ee1ac2bc2002f1d480)
