class Poll {
  static domLoaded() {
    const choicesElement = document.getElementById('choices');
    const bottomChoicesElement = document.getElementById('bottom-choices')

    const options = {
      animation: 100,
      group: 'choices'
    }
    if(window.matchMedia("(pointer: coarse)").matches) {
      options.handle = '.grip';
    }
    this.sortable = Sortable.create(choicesElement, options);
    if (bottomChoicesElement) {
      this.bottomSortable = Sortable.create(bottomChoicesElement, options);
    }

    this.pollID = choicesElement.getAttribute('poll_id');
    this.responderSalt = choicesElement.getAttribute('responder_salt');

    this.submitButton = document.getElementById('submit');
    this.submitButton.addEventListener('click', () => this.submitClicked());
    this.submitButton.disabled = false;
  }

  static async submitClicked() {
    const message = document.createElement('p');
    message.textContent = 'Now submitting...';
    this.submitButton.parentNode.replaceChild(message, this.submitButton);
    fetch('/poll/respond', {
      method: 'POST',
      body: JSON.stringify({
        poll_id: this.pollID,
        responder: this.responderSalt,
        responses: this.sortable.toArray(),
        bottom_responses: this?.bottomSortable?.toArray(),
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
        location.reload();
      }
    });
  }
}

document.addEventListener("DOMContentLoaded", () => Poll.domLoaded());
