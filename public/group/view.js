// src/lib/editable.js
var Editable = class {
  constructor(addPath, deletePath, editableElements, addCallback, deleteCallback, options = {}) {
    this.addPath = addPath;
    this.deletePath = deletePath;
    this.elements = editableElements;
    this.addCallback = addCallback;
    this.deleteCallback = deleteCallback;
    this.options = Object.assign({
      deleteContainerClass: "deletable"
    }, options);
    for (const element of this.elements) {
      const deleteElement = element.getElementsByClassName(this.options["deleteContainerClass"])[0];
      deleteElement.addEventListener("click", () => this.deleteItem(element));
    }
  }
  deleteItem(element) {
    console.log(this.deleteCallback(element));
  }
};

// src/group/view.js
var Group = class {
  static domLoaded() {
    const editableElementXPath = document.evaluate("//li[@class='editable' and ./div[@class='deletable']]", document);
    const editableElements = [];
    let editableElement = editableElementXPath.iterateNext();
    while (editableElement) {
      editableElements.push(editableElement);
      editableElement = editableElementXPath.iterateNext();
    }
    new Editable("/group/add_member", "/group/delete_member", editableElements, (elementToAdd) => {
      return "hello from add";
    }, (elementToDelete) => {
      return "hello from delete";
    });
  }
};
document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
