export { getElementsByXPath, eventEnter }

function getElementsByXPath(xpath) {
  const elementXPath = document.evaluate(xpath, document);
  const elements = [];
  let element = elementXPath.iterateNext();
  while (element) {
    elements.push(element);
    element = elementXPath.iterateNext()
  }
  return elements;
}

function eventEnter(element, callback) {
  element.addEventListener('keydown', (event) => {
    if (event.key == 'Enter') {
      event.preventDefault();
      return false;
    }
  });
  element.addEventListener('keyup', (event) => {
    if (event.key == 'Enter') {
      event.preventDefault();
      callback(event);
      return false;
    }
  });
}
