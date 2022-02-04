import { Listable } from '../lib/listable'

class Poll {
  static domLoaded() {
    const listable = new Listable(
      document.getElementById('choice-list'),
      document.getElementById('add-choice'),
      {
        placeholderText: 'Enter choice...',
        inputName: 'choices[]',
      });
    choices.forEach((choice) => {
      listable.addItem(choice, false)
    });
  }
}

document.addEventListener("DOMContentLoaded", () => Poll.domLoaded());
