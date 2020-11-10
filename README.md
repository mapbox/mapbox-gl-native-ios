# Generated documentation

This branch publishes the generated documentation for the most recent releases at https://docs.mapbox.com/ios/maps/api/X.X.X/

To learn how to add documentation see: [CONTRIBUTING.md](https://github.com/mapbox/mapbox-gl-native-ios/blob/master/CONTRIBUTING.md).

In addition to deploying documentation from this repo, you may also need to update version constants in https://github.com/mapbox/ios/ and https://github.com/mapbox/help/. Reach out to @mapbox/docs if you have any questions. To learn more about how generated docs work, see: https://github.com/mapbox/documentation/blob/hey-pages/docs/generated-docs.md.

## Manually invoking docs automation

The docs in this repo should be generated automatically each time a tagged release goes out. However, there are times when a tag is incorrect or some other circumstance requires a manual trigger. To build docs and open a PR using the docs automation pipeline, you can manually trigger a build in Travis: 

1. Go to https://travis-ci.com/github/mapbox/mapbox-gl-native-ios.
2. Click the "hamburger" menu icon next to the "More options" button and select "Trigger build". 
3. In the build dialog box, select the branch that contains the source code from which you would like to generate docs.
4. In the "Custom commit message" box, enter "[maps] sdk docs update x.x.x", replacing `x.x.x` with the version you plan to generate.
5. In the "Custom config" box, enter the following, again replacing `x.x.x` with the release tag you would like to use:
  ```
  merge_mode: deep_merge
  env:
  - SDK_FLAVOR=maps RELEASE_TAG=ios-vx.x.x
  ```
6. Click the "trigger custom build" button. If the build finishes successfully, you should see a PR from the `MapboxCI` user.
