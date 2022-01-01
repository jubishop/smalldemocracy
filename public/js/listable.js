class Listable {
  constructor(listElement, buttonElement, options = {}) {
    this.listElement = listElement;
    this.buttonElement = buttonElement;
    this.options = options;
    this.buttonElement.addEventListener('click',
                                        () => this.addButtonClicked());
  }

  option(key, fallback = '') {
    return this.options.hasOwnProperty(key) ? this.options[key] : fallback;
  }

  addButtonClicked() {
    let listItem = this.buildListItem();
    let inputElement = this.buildInputElement();
    let deleteButton = this.buildDeleteButton();
    deleteButton.addEventListener('click',
                                  () => this.deleteButtonClicked(listItem));
    listItem.appendChild(inputElement);
    listItem.appendChild(deleteButton);
    this.listElement.appendChild(listItem);
    inputElement.focus();
  }

  deleteButtonClicked(listItem) {
    listItem.remove();
  }

  buildListItem() {
    let listItem = document.createElement('li');
    listItem.classList.add(...this.option('listItemClasses', ['listable']));
    return listItem;
  }

  buildInputElement() {
    let inputElement = document.createElement('input');
    inputElement.classList.add(...this.option('textClasses', ['text']));
    inputElement.setAttribute('type', this.option('inputType', 'text'));
    inputElement.setAttribute('name', this.option('inputName', 'item[]'))
    inputElement.setAttribute('required', true);
    inputElement.setAttribute('placeholder', this.option('placeholderText'));
    inputElement.addEventListener('keydown', (event) => {
      if (event.key == "Enter") {
        event.preventDefault();
        return false;
      }
    });
    inputElement.addEventListener("keyup", (event) => {
      if (event.key == "Enter" && inputElement.reportValidity()) {
        this.addButtonClicked();
      }
    });
    return inputElement;
  }

  buildDeleteButton() {
    let deleteButton = document.createElement('div');
    let deleteIcon = document.createElement('i');
    deleteIcon.classList.add(
        ...this.option('deleteButtonClasses',
                       ['delete-button', 'fa-duotone', 'fa-trash-can']));
    deleteButton.appendChild(deleteIcon);
    return deleteButton;
  }
}
