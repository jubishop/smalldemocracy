// src/lib/editable.js
var Editable = class {
  constructor() {
  }
};

// src/group/view.js
var Group = class {
  static domLoaded() {
    new Editable();
  }
};
document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
