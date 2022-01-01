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
    this.listElement.appendChild(this.buildListItem());
  }

  buildListItem() {
    let listItem = document.createElement('li');
    listItem.classList.add(...this.option('listItemClasses', ['listable']));
    listItem.appendChild(this.buildInputElement());
    listItem.appendChild(this.buildDeleteButton());
    return listItem;
  }

  buildInputElement() {
    let inputElement = document.createElement('input');
    inputElement.classList.add(...this.option('textClasses', ['text']));
    inputElement.setAttribute('type', this.option('inputType', 'text'));
    inputElement.setAttribute('name', this.option('inputName', 'item[]'))
    inputElement.setAttribute('required', true);
    inputElement.setAttribute('placeholder', this.option('placeholderText'));
    return inputElement;
  }

  buildDeleteButton() {
    let deleteButton = document.createElement('i');
    deleteButton.classList.add(
        ...this.option('deleteButtonClasses',
                       ['delete-button', 'fa-duotone', 'fa-trash-can']));
    return deleteButton;
  }
}
