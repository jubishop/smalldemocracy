window.addEventListener('DOMContentLoaded', () => {
  const choicesElement = document.getElementById('choices');

  const options = {
    animation: 100,
  }
  if(window.matchMedia("(pointer: coarse)").matches) {
    options.handle = '.grip';
  }
  const sortable = Sortable.create(choicesElement, options);

  const pollID = choicesElement.getAttribute('poll_id');
  const responderSalt = choicesElement.getAttribute('responder_salt');

  submitButton = document.getElementById('submit');
  submitButton.addEventListener('click', () => {
    message = document.createElement('p');
    message.textContent = 'Now submitting...';
    submitButton.parentNode.replaceChild(message, submitButton);

    fetch('/poll/respond', {
      method: 'POST',
      body: JSON.stringify({
        poll_id: pollID,
        responder: responderSalt,
        responses: sortable.toArray()
      })
    }).then(res => {
      if (res.status == 201) {
        location.reload();
      } else {
        alert('Something went wrong :(');
      }
    });
  })
  setTimeout(() => { submitButton.disabled = false; }, 500);
});
