export { Modal }

class Modal {
  constructor(
    title,
    body,
    buttons = []) {
    this.dialog = document.createElement('dialog');
    const article = document.createElement('article');
    const header = document.createElement('header');
    header.textContent = title;
    article.appendChild(header);
    const bodyElement = document.createElement('p');
    bodyElement.textContent = body;
    article.appendChild(bodyElement);
    this.dialog.appendChild(article);
  }

  display() {
    this.dialog.setAttribute('open', true);
    document.body.prepend(this.dialog);
  }
}
