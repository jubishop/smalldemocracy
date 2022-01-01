class Listable {
  constructor(listElement, buttonElement, options = {}) {
    this.listElement = listElement;
    this.buttonElement = buttonElement;
    this.options = options;
    this.items = [];
    this.buttonElement.addEventListener('click',
                                        () => this.addButtonClicked());
  }

  option(key, fallback = '') {
    return this.options.hasOwnProperty(key) ? this.options[key] : fallback;
  }

  addButtonClicked() {
    const emptyItem = this.items.find((item) => !item.inputElement.value);
    if (emptyItem) {
      emptyItem.inputElement.focus();
      return;
    }

    const listItem = this.buildListItem();
    const inputElement = this.buildInputElement();
    const deleteButton = this.buildDeleteButton();
    listItem.appendChild(inputElement);
    listItem.appendChild(deleteButton);
    this.listElement.appendChild(listItem);

    const item = {listItem, inputElement};
    this.items.push(item);

    deleteButton.addEventListener('click',
                                  () => this.deleteButtonClicked(item));
    inputElement.focus();
  }

  deleteButtonClicked(item) {
    this.items.splice(this.items.indexOf(item), 1);
    item.listItem.remove();
  }

  buildListItem() {
    const listItem = document.createElement('li');
    listItem.classList.add(...this.option('listItemClasses', ['listable']));
    return listItem;
  }

  buildInputElement() {
    const inputElement = document.createElement('input');
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
    const deleteButton = document.createElement('div');
    const deleteIcon = document.createElement('i');
    deleteIcon.classList.add(
        ...this.option('deleteButtonClasses',
                       ['delete-button', 'fa-duotone', 'fa-trash-can']));
    deleteButton.appendChild(deleteIcon);
    return deleteButton;
  }
}
