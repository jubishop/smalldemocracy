// src/lib/editable.js
var Editable = class {
  constructor(listElement, elements, addButton, addPath, deletePath, addCallback, deleteCallback, options = {}) {
    this.listElement = listElement;
    this.addButton = addButton;
    this.addButton.addEventListener("click", () => this.addInputElement());
    this.addPath = addPath;
    this.deletePath = deletePath;
    this.addCallback = addCallback;
    this.deleteCallback = deleteCallback;
    this.options = Object.assign({
      deleteButtonClasses: ["delete-icon", "fa-duotone", "fa-trash-can"],
      inputClasses: ["input"],
      inputType: "text",
      listItemClasses: ["editable"],
      placeholderText: "",
      textClasses: ["text"]
    }, options);
    this.listItem = null;
    this.inputElement = null;
    for (const element of elements) {
      this.addDeleteButtonToElement(element);
    }
  }
  addItem() {
    if (!this.inputElement.value || !this.inputElement.reportValidity()) {
      this.inputElement.focus();
      return;
    }
    this.inputElement.disabled = true;
    fetch(this.addPath, {
      method: "POST",
      body: JSON.stringify(this.addCallback(this.inputElement.value)),
      headers: { "Content-Type": "application/json" }
    }).then((res) => {
      if (res.status == 201) {
        return false;
      } else {
        return res.text();
      }
    }).then((error_message) => {
      if (error_message) {
        alert("Error: " + error_message);
        this.inputElement.disabled = false;
      } else {
        const textElement = this.buildTextElement();
        textElement.textContent = this.inputElement.value;
        this.listItem.removeChild(this.inputElement);
        this.listItem.appendChild(textElement);
        this.addDeleteButtonToElement(this.listItem);
        this.listItem = null;
        this.inputElement = null;
      }
      this.addButton.disabled = false;
    });
  }
  deleteItem(element) {
    fetch(this.deletePath, {
      method: "POST",
      body: JSON.stringify(this.deleteCallback(element)),
      headers: { "Content-Type": "application/json" }
    }).then((res) => {
      if (res.status == 201) {
        return false;
      } else {
        return res.text();
      }
    }).then((error_message) => {
      if (error_message) {
        alert("Error: " + error_message);
      } else {
        this.listElement.removeChild(element);
      }
    });
  }
  addInputElement() {
    const listItem = this.buildListItem();
    const inputElement = this.buildInputElement();
    listItem.appendChild(inputElement);
    this.listElement.appendChild(listItem);
    this.listItem = listItem;
    this.inputElement = inputElement;
    this.addButton.disabled = true;
    this.inputElement.focus();
  }
  addDeleteButtonToElement(element) {
    const deleteButton = this.buildDeleteButton();
    element.appendChild(deleteButton);
    deleteButton.addEventListener("click", () => this.deleteItem(element));
  }
  buildListItem() {
    const listItem = document.createElement("li");
    listItem.classList.add(...this.options["listItemClasses"]);
    return listItem;
  }
  buildTextElement() {
    const textElement = document.createElement("p");
    textElement.classList.add(...this.options["textClasses"]);
    return textElement;
  }
  buildInputElement() {
    const inputElement = document.createElement("input");
    inputElement.classList.add(...this.options["inputClasses"]);
    inputElement.setAttribute("type", this.options["inputType"]);
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

// src/lib/modal.js
var Modal = class {
  constructor(title, body, buttons = []) {
    this.dialog = document.createElement("dialog");
    const article = document.createElement("article");
    const header = document.createElement("header");
    header.textContent = title;
    article.appendChild(header);
    const bodyElement = document.createElement("p");
    bodyElement.textContent = body;
    article.appendChild(bodyElement);
    this.dialog.appendChild(article);
  }
  display() {
    this.dialog.setAttribute("open", true);
    document.body.prepend(this.dialog);
  }
};

// src/group/creator_view.js
var Group = class {
  static domLoaded() {
    const listElement = document.getElementById("member-list");
    const hashID = listElement.getAttribute("hash-id");
    const nameContainer = document.getElementById("group-name");
    const editGroupButton = document.getElementById("edit-group-button");
    editGroupButton.addEventListener("click", () => {
      const textElement = document.querySelector("#group-name h2");
      textElement.remove();
      editGroupButton.remove();
      const inputElement = document.createElement("input");
      inputElement.value = textElement.textContent.trim();
      nameContainer.appendChild(inputElement);
      inputElement.focus();
      inputElement.addEventListener("keydown", (event) => {
        if (event.key == "Enter") {
          event.preventDefault();
          return false;
        }
      });
      inputElement.addEventListener("keyup", (event) => {
        if (event.key == "Enter") {
          event.preventDefault();
          fetch("/group/name", {
            method: "POST",
            body: JSON.stringify({
              hash_id: hashID,
              name: inputElement.value.trim()
            }),
            headers: { "Content-Type": "application/json" }
          }).then((res) => {
            if (res.status == 201) {
              return false;
            } else {
              return res.text();
            }
          }).then((error_message) => {
            if (error_message) {
              alert("Error: " + error_message);
            } else {
              inputElement.remove();
              const h2Element = document.createElement("h2");
              h2Element.textContent = inputElement.value.trim();
              nameContainer.appendChild(h2Element);
              nameContainer.appendChild(editGroupButton);
            }
          });
          return false;
        }
      });
    });
    const elementXPath = document.evaluate("//li[@class='editable' and not(./div)]", document);
    const elements = [];
    let element = elementXPath.iterateNext();
    while (element) {
      elements.push(element);
      element = elementXPath.iterateNext();
    }
    new Editable(listElement, elements, document.getElementById("add-member"), "/group/add_member", "/group/remove_member", (memberEmailToAdd) => {
      return {
        hash_id: hashID,
        email: memberEmailToAdd.trim()
      };
    }, (elementToDelete) => {
      return {
        hash_id: hashID,
        email: elementToDelete.querySelector("p").textContent.trim()
      };
    }, {
      inputType: "email",
      placeholderText: "Add member"
    });
    const deleteButton = document.getElementById("delete-group");
    deleteButton.addEventListener("click", () => {
      new Modal("hello", "world").display();
      console.log("delete group");
    });
  }
};
document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
