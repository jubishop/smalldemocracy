// src/lib/listable.js
var Listable = class {
  constructor(listElement, buttonElement, options = {}) {
    this.listElement = listElement;
    this.buttonElement = buttonElement;
    this.options = Object.assign({
      deleteButtonClasses: ["delete-icon", "fa-duotone", "fa-trash-can"],
      inputName: "item[]",
      inputType: "text",
      listItemClasses: ["listable"],
      placeholderText: "",
      textClasses: ["text"]
    }, options);
    this.items = [];
    this.buttonElement.addEventListener("click", () => this.addItem());
  }
  addItem() {
    const emptyOrInvalidItem = this.items.find((item2) => {
      return !item2.inputElement.value || !item2.inputElement.reportValidity();
    });
    if (emptyOrInvalidItem) {
      emptyOrInvalidItem.inputElement.focus();
      return;
    }
    const listItem = this.buildListItem();
    const inputElement = this.buildInputElement();
    const deleteButton = this.buildDeleteButton();
    listItem.appendChild(inputElement);
    listItem.appendChild(deleteButton);
    this.listElement.appendChild(listItem);
    const item = { listItem, inputElement };
    this.items.push(item);
    deleteButton.addEventListener("click", () => this.deleteItem(item));
    inputElement.focus();
  }
  deleteItem(item) {
    this.items.splice(this.items.indexOf(item), 1);
    item.listItem.remove();
  }
  buildListItem() {
    const listItem = document.createElement("li");
    listItem.classList.add(...this.options["listItemClasses"]);
    return listItem;
  }
  buildInputElement() {
    const inputElement = document.createElement("input");
    inputElement.classList.add(...this.options["textClasses"]);
    inputElement.setAttribute("type", this.options["inputType"]);
    inputElement.setAttribute("name", this.options["inputName"]);
    inputElement.setAttribute("required", true);
    inputElement.setAttribute("placeholder", this.options["placeholderText"]);
    inputElement.addEventListener("keydown", (event) => {
      if (event.key == "Enter") {
        event.preventDefault();
        return false;
      }
    });
    inputElement.addEventListener("keyup", (event) => {
      if (event.key == "Enter") {
        event.preventDefault();
        this.addItem();
        return false;
      }
    });
    return inputElement;
  }
  buildDeleteButton() {
    const deleteButton = document.createElement("div");
    const deleteIcon = document.createElement("i");
    deleteIcon.classList.add(...this.options["deleteButtonClasses"]);
    deleteButton.appendChild(deleteIcon);
    return deleteButton;
  }
};

// src/poll/create.js
var Poll = class {
  static domLoaded() {
    new Listable(document.getElementById("choice-list"), document.getElementById("add-choice"), {
      placeholderText: "Enter choice...",
      inputName: "choices[]"
    });
  }
};
document.addEventListener("DOMContentLoaded", () => Poll.domLoaded());
