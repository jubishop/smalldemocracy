import { Editable } from '../lib/editable'

class Group {
  static domLoaded() {
    new Editable();
  }
}

document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
