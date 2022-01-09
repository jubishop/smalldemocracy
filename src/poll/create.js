import { Listable } from '../lib/listable'

class Poll {
  static domLoaded() {
    new Listable(
      document.getElementById('choice-list'),
      document.getElementById('add-choice'),
      {
        placeholderText: 'Enter choice...',
        inputName: 'choices[]',
      });
  }
}

document.addEventListener("DOMContentLoaded", () => Poll.domLoaded());
