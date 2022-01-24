export { getElementsByXPath }

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
