// We need to import the CSS so that webpack will load it.
// The ExtractTextPlugin is used to separate it out into
// its own CSS file.
import "../css/app.css";
import "../css/fonts.css";

// webpack automatically concatenates all files in your
// watched paths. Those paths can be configured as
// endpoints in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import * as Main from "./modules/main";
import * as Home from "./modules/home";
import * as SvgToElm from "./modules/svg_to_elm";
import * as Background from "./background";
import * as Honeybadger from "honeybadger-js";
import "./custom_elements/rendered_html";
import "./custom_elements/clipboard_button";
import "./custom_elements/post_editor";
import smoothscroll from 'smoothscroll-polyfill';

// Initialize the smoothscroll polyfill
smoothscroll.polyfill();

// Initialize service worker
Background.registerWorker();

// Initialize the current page module
const moduleNode = document.head.querySelector("meta[name='module']");

if (moduleNode) {
  switch (moduleNode.content) {
    case "main":
      Main.initialize();
      break;

    case "home":
      Home.initialize();
      break;

    case "svg_to_elm":
      SvgToElm.initialize();

    default:
      break;
  }
}

// Track scroll position and set a .scrolled-top class
setInterval(() => {
  if (window.scrollY < 5) {
    document.body.classList.add("scrolled-top");
  } else {
    document.body.classList.remove("scrolled-top");
  }
}, 100);

// Setup error tracking
const env = document.head.querySelector("meta[name='env']").content;
const hbApiKey = document.head.querySelector(
  "meta[name='honeybadger_js_api_key']"
).content;

if (hbApiKey) {
  Honeybadger.configure({
    apiKey: hbApiKey,
    environment: env
  });
}
