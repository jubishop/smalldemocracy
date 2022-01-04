import { Listable } from '../listable.js';

class Group {
  static domLoaded() {
    let listable = new Listable(
        document.getElementById('member-list'),
        document.getElementById('add-member'),
        {
          placeholderText: 'Email address...',
          inputType: 'email',
          inputName: 'members[]',
        });
  }
}

document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
