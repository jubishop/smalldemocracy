import { Editable } from '../lib/editable'

class Group {
  static domLoaded() {
    const elementXPath = document.evaluate(
      "//li[@class='editable' and not(./div)]", document);
    const elements = [];
    let element = elementXPath.iterateNext();
    while (element) {
      elements.push(element);
      element = elementXPath.iterateNext()
    }
    new Editable(
      document.getElementById('member-list'),
      elements,
      document.getElementById('add-member'),
      '/group/add_member',
      '/group/delete_member',
      (memberEmailToAdd) => {
        return 'hello from add';
      },
      (elementToDelete) => {
        return 'hello from delete';
      },
      {
        inputType: 'email',
        placeholderText: 'Add member'
      });
  }
}

document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
