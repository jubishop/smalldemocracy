import { post } from '../../lib/ajax'

class Poll {
  static domLoaded() {
    const choicesElement = document.getElementById('choices');
    this.hashID = choicesElement.getAttribute('data-id');

    this.choicesArray = Array.from(
      choicesElement.getElementsByClassName('choice'));
    this.choicesArray.forEach((choice) => {
      choice.addEventListener('click', (event) => {
        if (event.target.tagName === 'A') return;
        this.choiceClicked(choice);
      });
      choice.disabled = false;
    });
  }

  static async choiceClicked(choice) {
    this.choicesArray.forEach((choice) => { choice.disabled = true; });
    post('/poll/respond',
      { hash_id: this.hashID, choice_id: choice.getAttribute('data-id') },
      () => location.reload());
  }
}

document.addEventListener("DOMContentLoaded", () => Poll.domLoaded());
