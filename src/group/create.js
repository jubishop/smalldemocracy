import { Listable } from '../lib/listable'

class Group {
  static domLoaded() {
    new Listable(
      document.getElementById('member-list'),
      document.getElementById('add-member'),
      {
        placeholderText: 'Email address...',
        inputType: 'email',
        inputName: 'members[]'
      });
  }
}

document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
