class Poll {
  static domLoaded() {
    const choicesElement = document.getElementById('choices');
    const bottomChoicesElement = document.getElementById('bottom-choices');

    const choicesArray = Array.from(document.getElementsByClassName('choice'));
    this.choiceElements = Object.fromEntries(choicesArray.map((choice) => {
      return [
        choice.getAttribute('data-id'),
        choice.getElementsByClassName('score')[0]
      ];
    }));

    const options = {
      animation: 100,
      group: 'choices',
      onStart: () => { this.submitButton.disabled = true; },
      onEnd: () => this.updateScores()
    };
    if(window.matchMedia("(pointer: coarse)").matches) {
      options.handle = '.grip';
    }
    this.sortable = Sortable.create(choicesElement, options);
    if (bottomChoicesElement) {
      this.bottomSortable = Sortable.create(bottomChoicesElement, options);
    }

    this.pollID = choicesElement.getAttribute('poll_id');

    this.submitButton = document.getElementById('submit');
    this.submitButton.addEventListener('click', () => this.submitClicked());

    this.updateScores();
  }

  static updateScores() {
    let baseScore = 0;
    if (this.bottomSortable) {
      baseScore = this.bottomSortable.toArray().length;
      this.bottomSortable.toArray().forEach((choiceID) => {
        this.choiceElements[choiceID].textContent = '0 points';
      });
    }

    let topScore = this.sortable.toArray().length;
    if (!this.bottomSortable) {
      topScore -= 1;
    }
    this.sortable.toArray().forEach((choiceID) => {
      const currentScore = topScore + baseScore;
      topScore -= 1;
      const points = currentScore == 1 ? 'point' : 'points';
      this.choiceElements[choiceID].textContent = currentScore + ' ' + points;
    });
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
        responses: this.sortable.toArray(),
        bottom_responses: this?.bottomSortable?.toArray()
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
