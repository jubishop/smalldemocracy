class Group {
  static domLoaded() {
    alert("hello world");
  }
}

document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
