const path = require('path');
const CompressionPlugin = require('compression-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const UglifyPlugin = require("uglifyjs-webpack-plugin");
const ExtractTextPlugin = require('extract-text-webpack-plugin');

const extractAppCSS = new ExtractTextPlugin('../css/app.css');
const extractFontsCSS = new ExtractTextPlugin('../css/fonts.css');

module.exports = (env, argv) => ({
  entry: './js/app.js',
  output: {
    filename: 'app.js',
    path: path.resolve(__dirname, '../priv/static/js')
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env'],
            babelrc: false
          }
        }
      },
      {
        test: /app\.css$/,
        use: extractAppCSS.extract({
          fallback: 'style-loader',
          use: [
            { loader: 'css-loader', options: { importLoaders: 1 } },
            'postcss-loader'
          ]
        })
      },
      {
        test: /fonts\.css$/,
        use: extractFontsCSS.extract({
          fallback: 'style-loader',
          use: [
            { loader: 'css-loader', options: { importLoaders: 1 } },
            'postcss-loader'
          ]
        })
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: {
          loader: 'elm-webpack-loader',
          options: {
            cwd: path.resolve(__dirname, 'elm'),
            pathToElm: path.resolve(__dirname, 'node_modules/.bin/elm'),
            debug: argv.mode === 'development',
            verbose: argv.mode === 'development',
            optimize: argv.mode !== 'development'
          }
        }
      }
    ]
  },
  plugins: [
    extractAppCSS,
    extractFontsCSS,
    new CopyWebpackPlugin([{ from: 'static/', to: '../' }]),
    new CompressionPlugin({ test: /(\.js|\.css)$/ })
  ],
  optimization: {
    minimizer: [
      // Options borrowed from the Elm SPA example:
      // https://github.com/rtfeldman/elm-spa-example/tree/54e3facfac9e208efe9ce02ad817d444c3411ca9#step-2
      new UglifyPlugin({
        uglifyOptions: {
          compress: {
            pure_funcs: ['F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9'],
            pure_getters: true,
            keep_fargs: false,
            unsafe_comps: true,
            unsafe: true,
            passes: 2
          },
          mangle: true
        }
      })
    ]
  },
  performance: {
    maxEntrypointSize: 500000,
    maxAssetSize: 300000
  }
});
