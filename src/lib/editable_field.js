export { EditableField }

import { Modal } from './modal'
import { eventEnter } from './dom'
import { post } from './ajax'

class EditableField {
  constructor(fieldElement,
    editButton,
    editPath,
    editCallback,
    successCallback = () => { },
    options = {}) {
    this.fieldElement = fieldElement;
    this.editButton = editButton;
    this.editPath = editPath;
    this.editCallback = editCallback;
    this.successCallback = successCallback;
    this.options = Object.assign({
      textElementType: 'h2'
    }, options);
    this.editButton.addEventListener('click', () => this.showInputField());
  }

  showInputField() {
    const textElement = this.fieldElement.firstElementChild;
    textElement.remove();
    this.editButton.remove();
    const inputElement = document.createElement('input');
    inputElement.value = textElement.textContent.trim();
    this.fieldElement.appendChild(inputElement);
    inputElement.focus();
    eventEnter(inputElement, (event) => {
      inputElement.disabled = true;
      post(this.editPath, this.editCallback(inputElement.value.trim()),
        () => { // successCallback
          inputElement.remove();
          this.showTextField(inputElement.value.trim());
        }, (error_message) => { // errorCallback
          new Modal('Error', error_message).display();
          inputElement.disabled = false;
        });
    });
  }

  showTextField(textContent) {
    const textElement = document.createElement(
      this.options['textElementType']);
    textElement.textContent = textContent;
    this.fieldElement.appendChild(textElement);
    this.fieldElement.appendChild(this.editButton);
    this.successCallback(textContent);
  }
}
