// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import * as ActiveStorage from "@rails/activestorage";
ActiveStorage.start();

import "trix"
import "@rails/actiontext"
import "./direct_uploads"
import "./carousel_helper"


import 'bootstrap';
import * as bootstrap from 'bootstrap';

window.bootstrap = bootstrap;