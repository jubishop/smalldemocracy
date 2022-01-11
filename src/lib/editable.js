export { Editable }

class Editable {
  constructor(addPath,
              deletePath,
              editableElements,
              addCallback,
              deleteCallback,
              options = {}) {
    this.addPath = addPath;
    this.deletePath = deletePath;
    this.elements = editableElements;
    this.addCallback = addCallback;
    this.deleteCallback = deleteCallback;
    this.options = Object.assign({
      deleteContainerClass: 'deletable'
    }, options);
    for (const element of this.elements) {
      const deleteElement = element.getElementsByClassName(
        this.options['deleteContainerClass'])[0];
      deleteElement.addEventListener('click',
        () => this.deleteItem(element));
    }
  }

  deleteItem(element) {
    console.log(this.deleteCallback(element));
  }
}
