class Poll {
  static domLoaded() {
    let listable = new Listable(
        document.getElementById('choice-list'),
        document.getElementById('add-choice'),
        {
          placeholderText: 'Enter choice...',
          inputName: 'choices[]',
        });
  }
}

document.addEventListener("DOMContentLoaded", () => Poll.domLoaded());
