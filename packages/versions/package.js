Package.describe({
  name: 'ppettit:versions',
  version: '0.0.1',
  // Brief, one-line summary of the package.
  summary: 'Expose git/package version numbers at /versions.json',
  // URL to the Git repository containing the source code for this package.
  git: '',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: null
});

Package.onUse(function(api) {
  api.versionsFrom('1.4.3.2');
  api.use(['templating', 'coffeescript'], 'client');
  api.use('isobuild:compiler-plugin@1.0.0')
  api.mainModule('client/versions.coffee', 'client');
});

Package.registerBuildPlugin({
  name: 'versions',
  use: [],
  sources: [
    'plugin/versions.js'
  ],
  npmDependencies: []
})
