"use strict";

// Keep every existing callable/export in index.js and load the new
// server-side transaction processor from the same Firebase Functions entrypoint.
require("./index.js");
require("./transactionFlow.js");
