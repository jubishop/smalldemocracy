class Goldens {
  static domLoaded() {
    const rejectButtons = Array.from(document.getElementsByClassName('reject'));
    rejectButtons.forEach((rejectButton) => {
      rejectButton.addEventListener('click', () => {
        this.respond('/reject', rejectButton);
      });
    });

    const acceptButtons = Array.from(document.getElementsByClassName('accept'));
    acceptButtons.forEach((acceptButton) => {
      acceptButton.addEventListener('click', () => {
        this.respond('/accept', acceptButton);
      });
    });
  }

  static respond(endpoint, buttonElement) {
    fetch(endpoint, {
      method: 'POST',
      body: JSON.stringify({
        index: buttonElement.value,
      }),
      headers: { 'Content-Type': 'application/json' }
    }).then(res => {
      if (res.status == 201) {
        return false;
      } else {
        return res.text();
      }
    }).then(error_message => {
      if (error_message) {
        alert('Error: ' + error_message);
      } else {
        var imagesElement = buttonElement.closest('.images');
        imagesElement.remove();
      }
    });
  }
}

document.addEventListener("DOMContentLoaded", () => Goldens.domLoaded());
