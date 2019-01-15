# NonScrollView

[![CI Status](http://img.shields.io/travis/int123c/NonScrollView.svg?style=flat)](https://travis-ci.org/int123c/NonScrollView)
[![Version](https://img.shields.io/cocoapods/v/NonScrollView.svg?style=flat)](http://cocoapods.org/pods/NonScrollView)
[![License](https://img.shields.io/cocoapods/l/NonScrollView.svg?style=flat)](http://cocoapods.org/pods/NonScrollView)
[![Platform](https://img.shields.io/cocoapods/p/NonScrollView.svg?style=flat)](http://cocoapods.org/pods/NonScrollView)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

NonScrollView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'NonScrollView'
pod 'NonScrollView/Containers' # to install example containers that you should never use in production
```

## Usage

### ViewPlacer

You need to provide a `NonScrollViewLayout` for `NonScrollView` to layout subviews. A `NonScrollViewLayout` consists of a few `ViewPlacer`s for `NonScrollView` to place its subviews, a block to generate contentSize and a block to generate contentInset.

Please check `ScrollViewChainController` for example.

### NonScrollViewScrollRecognizer

You may also treat `NonScrollView` as a gesture recognizer. Please check `HeaderSegmentController` for example.

You are not recommended to use any of the containers in `NonScrollView/Containers`, they are for experiments only. Though they should work, edge cases may not be handled correctly.

## License

NonScrollView is available under the MIT license. See the LICENSE file for more info.