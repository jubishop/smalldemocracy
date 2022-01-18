export { Modal }

class Modal {
  constructor(
    title,
    body,
    buttons = false) {
    this.dialog = document.createElement('dialog');
    const article = document.createElement('article');
    const header = document.createElement('header');
    header.textContent = title;
    const closeButton = document.createElement('a');
    closeButton.classList.add('close');
    closeButton.style.cursor = 'pointer';
    closeButton.addEventListener('click', () => this.close());
    header.appendChild(closeButton);
    article.appendChild(header);
    const bodyElement = document.createElement('p');
    bodyElement.textContent = body;
    article.appendChild(bodyElement);
    if (buttons) {
      const footer = document.createElement('footer');
      for (const buttonText in buttons) {
        const buttonInfo = buttons[buttonText];
        const button = document.createElement('a');
        button.setAttribute('role', 'button');
        button.setAttribute('href', '#');
        button.textContent = buttonText;
        if (buttonInfo.hasOwnProperty('classes')) {
          button.classList.add(...buttonInfo.classes)
        }
        if (buttonInfo.hasOwnProperty('callback')) {
          button.addEventListener('click', () => buttonInfo.callback());
        } else {
          button.addEventListener('click', () => this.close());
        }
        footer.appendChild(button);
      }
      article.appendChild(footer);
    }
    this.dialog.appendChild(article);
  }

  display() {
    this.dialog.setAttribute('open', true);
    document.body.prepend(this.dialog);
    document.documentElement.classList.add('modal-is-open');
    return this;
  }

  close() {
    this.dialog.setAttribute('open', false);
    this.dialog.remove();
    document.documentElement.classList.remove('modal-is-open');
    return this;
  }
}
