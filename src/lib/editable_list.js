export { EditableList }

import { Modal } from './modal'
import { post } from './ajax'

class EditableList {
  constructor(listElement,
    elements,
    addButton,
    addPath,
    deletePath,
    addCallback,
    deleteCallback,
    options = {}) {
    this.listElement = listElement;
    this.addButton = addButton;
    this.addButton.addEventListener('click', () => this.addInputElement());
    this.addPath = addPath;
    this.deletePath = deletePath;
    this.addCallback = addCallback;
    this.deleteCallback = deleteCallback;
    this.options = Object.assign({
      deleteButtonClasses: ['delete-icon', 'fa-duotone', 'fa-trash-can'],
      inputClasses: ['input'],
      inputType: 'text',
      listItemClasses: ['editable'],
      placeholderText: '',
      textClasses: ['text']
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
    post(this.addPath, this.addCallback(this.inputElement.value),
      () => { // successCallback
        const textElement = this.buildTextElement();
        textElement.textContent = this.inputElement.value;
        this.listItem.removeChild(this.inputElement);
        this.listItem.appendChild(textElement);
        this.addDeleteButtonToElement(this.listItem);
        this.listItem = null;
        this.inputElement = null;
        this.addButton.disabled = false;
      },
      (error_message) => { // errorCallback
        new Modal('Error', error_message).display();
        this.inputElement.disabled = false;
      });
  }

  deleteItem(element) {
    post(this.deletePath, this.deleteCallback(element),
      () => this.listElement.removeChild(element));
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
    deleteButton.addEventListener('click', () => this.deleteItem(element));
  }

  buildListItem() {
    const listItem = document.createElement('li');
    listItem.classList.add(...this.options['listItemClasses']);
    return listItem;
  }

  buildTextElement() {
    const textElement = document.createElement('p');
    textElement.classList.add(...this.options['textClasses']);
    return textElement;
  }

  buildInputElement() {
    const inputElement = document.createElement('input');
    inputElement.classList.add(...this.options['inputClasses']);
    inputElement.setAttribute('type', this.options['inputType']);
    inputElement.setAttribute('placeholder', this.options['placeholderText']);
    inputElement.addEventListener('keydown', (event) => {
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
    const deleteButton = document.createElement('div');
    const deleteIcon = document.createElement('i');
    deleteIcon.classList.add(...this.options['deleteButtonClasses'])
    deleteButton.appendChild(deleteIcon);
    return deleteButton;
  }
}
