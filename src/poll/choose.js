class Poll {
  static domLoaded() {
    const choicesElement = document.getElementById('choices');
    this.hashID = choicesElement.getAttribute('hash-id');

    this.choicesArray = Array.from(
        choicesElement.getElementsByClassName('choice'));
    this.choicesArray.forEach((choice) => {
      choice.addEventListener('click', () => this.choiceClicked(choice));
      choice.disabled = false;
    });
  }

  static async choiceClicked(choice) {
    this.choicesArray.forEach((choice) => { choice.disabled = true; });
    fetch('/poll/respond', {
      method: 'POST',
      body: JSON.stringify({
        hash_id: this.hashID,
        choice_id: choice.getAttribute('data-id'),
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
