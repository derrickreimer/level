exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: "js/app.js"

      // To use a separate vendor.js bundle, specify two files path
      // http://brunch.io/docs/config#-files-
      // joinTo: {
      //  "js/app.js": /^(web\/static\/js)/,
      //  "js/vendor.js": /^(web\/static\/vendor)|(deps)/
      // }
      //
      // To change the order of concatenation of files, explicitly mention here
      // order: {
      //   before: [
      //     "web/static/vendor/js/jquery-2.1.1.js",
      //     "web/static/vendor/js/bootstrap.min.js"
      //   ]
      // }
    },
    stylesheets: {
      joinTo: {
        "css/themes/dark.css": /^(css\/dark)/
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/,
    ignored: [/\/_/, /vendor\/(node|j?ruby-.+|bundle)\//, /elm-stuff/]
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: ["static", "css", "elm", "js", "vendor"],

    // Where to compile files to
    public: "../priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    },
    sass: {
      mode: "native",
      options: {
        includePaths: ['node_modules/normalize.css']
      }
    },
    elmBrunch: {
      executablePath: '../node_modules/elm/binwrappers',
      elmFolder: 'elm',
      mainModules: ['src/Main.elm', 'src/Signup.elm'],
      outputFolder: '../../priv/static/js',
      outputFile: 'bundle.js',
      makeParameters: ['--warn']
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  overrides: {
    development: {
      plugins: {
        elmBrunch: {
          makeParameters: ['--warn', '--debug']
        }
      }
    }
  },

  npm: {
    enabled: true
  }
};
