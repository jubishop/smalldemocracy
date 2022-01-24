// src/lib/modal.js
var Modal = class {
  constructor(title, body, buttons = false) {
    this.dialog = document.createElement("dialog");
    const article = document.createElement("article");
    const header = document.createElement("header");
    header.textContent = title;
    const closeButton = document.createElement("a");
    closeButton.classList.add("close");
    closeButton.style.cursor = "pointer";
    closeButton.addEventListener("click", () => this.close());
    header.appendChild(closeButton);
    article.appendChild(header);
    const bodyElement = document.createElement("p");
    bodyElement.textContent = body;
    article.appendChild(bodyElement);
    if (buttons) {
      const footer = document.createElement("footer");
      for (const buttonText in buttons) {
        const buttonInfo = buttons[buttonText];
        const button = document.createElement("a");
        button.setAttribute("role", "button");
        button.setAttribute("href", "#");
        button.textContent = buttonText;
        if (buttonInfo.hasOwnProperty("classes")) {
          button.classList.add(...buttonInfo.classes);
        }
        if (buttonInfo.hasOwnProperty("callback")) {
          button.addEventListener("click", () => buttonInfo.callback());
        } else {
          button.addEventListener("click", () => this.close());
        }
        footer.appendChild(button);
      }
      article.appendChild(footer);
    }
    this.dialog.appendChild(article);
  }
  display() {
    this.dialog.setAttribute("open", true);
    document.body.prepend(this.dialog);
    document.documentElement.classList.add("modal-is-open");
    return this;
  }
  close() {
    this.dialog.setAttribute("open", false);
    this.dialog.remove();
    document.documentElement.classList.remove("modal-is-open");
    return this;
  }
};

// src/lib/ajax.js
function post(path, params, successCallback, errorCallback = false, finallyCallback = () => {
}) {
  fetch(path, {
    method: "POST",
    body: JSON.stringify(params),
    headers: { "Content-Type": "application/json" }
  }).then((response) => {
    if (response.status == 201) {
      return void 0;
    } else {
      return response.text();
    }
  }).then((error_message) => {
    if (error_message) {
      if (errorCallback) {
        errorCallback(error_message);
      } else {
        new Modal("Error", error_message).display();
      }
    } else {
      successCallback();
    }
  }).catch((error_message) => {
    if (errorCallback) {
      errorCallback(error_message);
    } else {
      new Modal("Error", error_message).display();
    }
  }).finally(() => {
    finallyCallback();
  });
}

// src/lib/editable_list.js
var EditableList = class {
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
    post(this.addPath, this.addCallback(this.inputElement.value.trim()), () => {
      const textElement = this.buildTextElement();
      textElement.textContent = this.inputElement.value.trim();
      this.listItem.removeChild(this.inputElement);
      this.listItem.appendChild(textElement);
      this.addDeleteButtonToElement(this.listItem);
      this.listItem = null;
      this.inputElement = null;
      this.addButton.disabled = false;
    }, (error_message) => {
      new Modal("Error", error_message).display();
      this.inputElement.disabled = false;
    });
  }
  deleteItem(element) {
    post(this.deletePath, this.deleteCallback(element), () => this.listElement.removeChild(element));
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

// src/lib/editable_field.js
var EditableField = class {
  constructor(fieldElement, editButton, editPath, editCallback, successCallback = () => {
  }, options = {}) {
    this.fieldElement = fieldElement;
    this.editButton = editButton;
    this.editPath = editPath;
    this.editCallback = editCallback;
    this.successCallback = successCallback;
    this.options = Object.assign({
      textElementType: "h2"
    }, options);
    this.editButton.addEventListener("click", () => this.showInputField());
  }
  showInputField() {
    const textElement = this.fieldElement.firstElementChild;
    textElement.remove();
    this.editButton.remove();
    const inputElement = document.createElement("input");
    inputElement.value = textElement.textContent.trim();
    this.fieldElement.appendChild(inputElement);
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
        inputElement.disabled = true;
        post(this.editPath, this.editCallback(inputElement.value.trim()), () => {
          inputElement.remove();
          this.showTextField(inputElement.value.trim());
        }, (error_message) => {
          new Modal("Error", error_message).display();
          inputElement.disabled = false;
        });
        return false;
      }
    });
  }
  showTextField(textContent) {
    const textElement = document.createElement(this.options["textElementType"]);
    textElement.textContent = textContent;
    this.fieldElement.appendChild(textElement);
    this.fieldElement.appendChild(this.editButton);
    this.successCallback(textContent);
  }
};

// src/lib/dom.js
function getElementsByXPath(xpath) {
  const elementXPath = document.evaluate(xpath, document);
  const elements = [];
  let element = elementXPath.iterateNext();
  while (element) {
    elements.push(element);
    element = elementXPath.iterateNext();
  }
  return elements;
}

// src/group/creator_view.js
var Group = class {
  static domLoaded() {
    const listElement = document.getElementById("member-list");
    const hashID = listElement.getAttribute("data-id");
    new EditableField(document.getElementById("group-name"), document.getElementById("edit-group-button"), "/group/name", (textContent) => {
      return {
        hash_id: hashID,
        name: textContent
      };
    }, (textContent) => {
      const createLink = document.getElementById("create-link");
      createLink.innerHTML = `Create new poll for <em>${textContent}</em>`;
    });
    new EditableList(listElement, getElementsByXPath("//li[@class='editable' and not(./div)]"), document.getElementById("add-member"), "/group/add_member", "/group/remove_member", (memberEmailToAdd) => {
      return {
        hash_id: hashID,
        email: memberEmailToAdd.trim()
      };
    }, (elementToDelete) => {
      return {
        hash_id: hashID,
        email: elementToDelete.firstElementChild.textContent.trim()
      };
    }, {
      inputType: "email",
      placeholderText: "Add member"
    });
    const deleteButton = document.getElementById("delete-group");
    deleteButton.addEventListener("click", () => {
      const modal = new Modal("Are you sure?", "Deleting this group will also delete all it's polls", {
        "Cancel": {
          classes: ["secondary"]
        },
        "Do It": {
          callback: () => {
            post("/group/destroy", { hash_id: hashID }, () => window.location.replace("/"), false, () => modal.close());
          },
          classes: ["primary"]
        }
      }).display();
    });
  }
};
document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
