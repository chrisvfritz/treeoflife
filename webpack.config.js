// Vendor
var getConfig = require('hjs-webpack');
var sass = require('node-sass');

// Base Config
var config = getConfig({
  in: 'src/app.ls',
  out: 'public',
  clearBeforeBuild: true,
  html: function (context) {
    return {
      'index.html': context.defaultTemplate({
        title: 'Exemplary Tree of Life',
        metaViewport: false,
        metaTags: {
          viewport: 'width=device-width, initial-scale=0.4, maximum-scale=0.4'
        },
        head: '<link href="https://fonts.googleapis.com/css?family=Open+Sans" rel="stylesheet" type="text/css">'
      })
    };
  }
});

// Add YAML Loader
config.module.loaders.push({
  key: 'yml',
  test: /\.ya?ml$/,
  loaders: ['json', 'yaml']
});

// Export
module.exports = config;
