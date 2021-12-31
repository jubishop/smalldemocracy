class Group {
  static domLoaded() {
    let listable = new Listable(document.getElementById('member-list'),
                                document.getElementById('add-member'));
  }
}

document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
