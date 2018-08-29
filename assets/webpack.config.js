const path = require('path');
const ExtractTextPlugin = require('extract-text-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const UglifyPlugin = require("uglifyjs-webpack-plugin");


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
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
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
    new ExtractTextPlugin('../css/app.css'),
    new CopyWebpackPlugin([{ from: 'static/', to: '../' }])
  ],
  optimization: {
    minimizer: [
      new UglifyPlugin({
        uglifyOptions: {
          compress: {
            pure_funcs: "F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",
            pure_getters: "true",
            keep_fargs: "false",
            unsafe_comps: true,
            unsafe: true,
            passes: 2
          }
        }
      }),
      new UglifyPlugin({
        uglifyOptions: {
          compress: false,
          mangle: true
        }
      })
    ]
  }
});
