import { Editable } from '../lib/editable'

class Group {
  static domLoaded() {
    const listElement = document.getElementById('member-list');
    const hashID = listElement.getAttribute("hash-id");
    const elementXPath = document.evaluate(
      "//li[@class='editable' and not(./div)]", document);
    const elements = [];
    let element = elementXPath.iterateNext();
    while (element) {
      elements.push(element);
      element = elementXPath.iterateNext()
    }
    new Editable(
      listElement,
      elements,
      document.getElementById('add-member'),
      '/group/add_member',
      '/group/remove_member',
      (memberEmailToAdd) => {
        return {
          hash_id: hashID,
          email: memberEmailToAdd,
        }
      },
      (elementToDelete) => {
        return {
          hash_id: hashID,
          email: elementToDelete.getElementsByTagName('p')[0].textContent.trim()
        }
      },
      {
        inputType: 'email',
        placeholderText: 'Add member'
      });
  }
}

document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
