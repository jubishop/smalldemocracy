class Poll {
  static domLoaded() {
    const choicesElement = document.getElementById('choices');
    this.pollID = choicesElement.getAttribute('poll_id');
    this.responderSalt = choicesElement.getAttribute('responder_salt');

    this.choicesArray = Array.from(document.getElementsByClassName('choice'));
    this.choicesArray.forEach((choice) => {
      choice.addEventListener('click', () => this.choiceClicked(choice));
      choice.getElementsByClassName('text')[0].disabled = false;
    });
  }

  static async choiceClicked(choice) {
    this.choicesArray.forEach((choice) => {
      choice.getElementsByClassName('text')[0].disabled = true;
    });
    fetch('/poll/respond', {
      method: 'POST',
      body: JSON.stringify({
        poll_id: this.pollID,
        responder: this.responderSalt,
        choice: choice.getAttribute('data-id'),
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
