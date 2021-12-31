class Poll {
  static domLoaded() {
    alert("hello world");
  }
}

document.addEventListener("DOMContentLoaded", () => Poll.domLoaded());
