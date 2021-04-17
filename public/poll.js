window.addEventListener('DOMContentLoaded', () => {
  const choicesElement = document.getElementById('choices');
  const sortable = Sortable.create(choicesElement, {
    handle: '.sort-handle'
  });

  const pollID = choicesElement.getAttribute('poll_id');
  const responderSalt = choicesElement.getAttribute('responder_salt');

  document.getElementById('submit').addEventListener('click', () => {
    fetch('/poll_response', {
      method: 'POST',
      body: JSON.stringify({
        poll_id: pollID,
        responder: responderSalt,
        responses: sortable.toArray()
      })
    }).then(res => {
      console.log('Request complete! response:', res);
    });
  })
});
