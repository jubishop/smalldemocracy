import { Editable } from '../lib/editable'

class Group {
  static domLoaded() {
    const editableElementXPath = document.evaluate(
      "//li[@class='editable' and ./div[@class='deletable']]", document);
    const editableElements = [];
    let editableElement = editableElementXPath.iterateNext();
    while (editableElement) {
      editableElements.push(editableElement);
      editableElement = editableElementXPath.iterateNext()
    }
    new Editable(
      '/group/add_member',
      '/group/delete_member',
      editableElements,
      (elementToAdd) => {
        return 'hello from add';
      },
      (elementToDelete) => {
        return 'hello from delete';
      });
  }
}

document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
