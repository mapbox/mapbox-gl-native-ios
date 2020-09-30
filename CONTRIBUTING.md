# Contributing

If you have a usage question for a product built on Mapbox GL (such as our iOS or Android SDKs), please visit https://www.mapbox.com/help/.

If you want to contribute code:

1. Please familiarize yourself with the [install process](INSTALL.md).

1. Ensure that existing [pull requests](https://github.com/mapbox/mapbox-gl-native-ios/pulls) and [issues](https://github.com/mapbox/mapbox-gl-native-ios/issues) don’t already cover your contribution or question.

1. Pull requests are gladly accepted. If there are any changes that developers using one of the GL SDKs should be aware of, please update the **master** section of the relevant changelog(s):
  * [Mapbox Maps SDK for iOS](platform/ios/CHANGELOG.md)
  * [Mapbox Maps SDK for macOS](platform/macos/CHANGELOG.md)

1. Prefix your commit messages with the platform(s) your changes affect: `[ios]` or `[macos]`.

Please note the special instructions for contributing new source code files, asset files, or user-facing strings to the [iOS SDK](platform/ios/DEVELOPING.md#contributing) or [macOS SDK](platform/macos/DEVELOPING.md#contributing).

### Github issue labels

Our labeling system is:

 * **minimalistic:** Labels’ usefulness are inversely proportional to how many we have.
 * **objective:** Labels should be objective enough that any two people would agree on a labeling decision.
 * **useful:** Labels should track state or capture semantic meaning that would otherwise be hard to search for.

We’ve color-coded our labels by facet to make them easier to use:

 * type (blue)
 * platform (black)
 * actionable status (red)
 * non-actionable status (grey)
 * importance / urgency (green)
 * topic / project / misc (yellow)

### Generating documentation

This repository automates generating documentation using CircleCI and Travis.

When a new release tag is created, CircleCI will trigger `scripts/trigger-maps-documentation-deploy-steps.sh` twice: 

1. In this repository, the script will trigger Travis to fetch the release tag, generate documentation for that release, commit the files, and create a new branch and pull request against the publisher-production branch.
2. In https://github.com/mapbox/ios-sdk, the script will trigger Travis to update various metadata files with the latest version, commit the changes, and create a new branch and pull request against the publisher-production branch.