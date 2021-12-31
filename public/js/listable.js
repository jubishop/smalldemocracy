class Listable {
  constructor(listElement, buttonElement) {
    this.listElement = listElement;
    this.buttonElement = buttonElement;
    if (this.buttonElement) {
      this.buttonElement.addEventListener('click',
                                          () => this.addButtonClicked());
    }
  }

  addButtonClicked() {
    let node = document.createElement("li");
    let textnode = document.createTextNode("Water");
    node.appendChild(textnode);
    this.listElement.appendChild(node);
  }
}
