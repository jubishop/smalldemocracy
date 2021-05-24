class Poll {
  static domLoaded() {
    const choicesElement = document.getElementById('choices');
    this.pollID = choicesElement.getAttribute('poll_id');
    this.responderSalt = choicesElement.getAttribute('responder_salt');

    const choicesArray = Array.from(document.getElementsByClassName('choice'));
    choicesArray.forEach((choice) => {
      choice.addEventListener('click', () => this.choiceClicked(choice));
      choice.getElementsByClassName('text')[0].disabled = false;
    });
  }

  static async choiceClicked(choice) {
    alert(choice.getAttribute('data-id'));
  }
}

document.addEventListener("DOMContentLoaded", () => Poll.domLoaded());
