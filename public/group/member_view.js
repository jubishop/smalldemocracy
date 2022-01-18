// src/lib/modal.js
var Modal = class {
  constructor(title, body, buttons = false) {
    this.dialog = document.createElement("dialog");
    const article = document.createElement("article");
    const header = document.createElement("header");
    header.textContent = title;
    const closeButton = document.createElement("a");
    closeButton.classList.add("close");
    closeButton.style.cursor = "pointer";
    closeButton.addEventListener("click", () => this.close());
    header.appendChild(closeButton);
    article.appendChild(header);
    const bodyElement = document.createElement("p");
    bodyElement.textContent = body;
    article.appendChild(bodyElement);
    if (buttons) {
      const footer = document.createElement("footer");
      for (const buttonText in buttons) {
        const buttonInfo = buttons[buttonText];
        const button = document.createElement("a");
        button.setAttribute("role", "button");
        button.setAttribute("href", "#");
        button.textContent = buttonText;
        if (buttonInfo.hasOwnProperty("classes")) {
          button.classList.add(...buttonInfo.classes);
        }
        if (buttonInfo.hasOwnProperty("callback")) {
          button.addEventListener("click", () => buttonInfo.callback());
        } else {
          button.addEventListener("click", () => this.close());
        }
        footer.appendChild(button);
      }
      article.appendChild(footer);
    }
    this.dialog.appendChild(article);
  }
  display() {
    this.dialog.setAttribute("open", true);
    document.body.prepend(this.dialog);
    document.documentElement.classList.add("modal-is-open");
    return this;
  }
  close() {
    this.dialog.setAttribute("open", false);
    this.dialog.remove();
    document.documentElement.classList.remove("modal-is-open");
    return this;
  }
};

// src/lib/ajax.js
function post(path, params, successCallback, errorCallback = false, finallyCallback = () => {
}) {
  fetch(path, {
    method: "POST",
    body: JSON.stringify(params),
    headers: { "Content-Type": "application/json" }
  }).then((res) => {
    if (res.status == 201) {
      return false;
    } else {
      return res.text();
    }
  }).then((error_message) => {
    if (error_message) {
      if (errorCallback) {
        errorCallback(error_message);
      } else {
        new Modal("Error", error_message).display();
      }
    } else {
      successCallback();
    }
    finallyCallback();
  });
}

// src/group/member_view.js
var Group = class {
  static domLoaded() {
    const listElement = document.getElementById("member-list");
    const hashID = listElement.getAttribute("data-id");
    const leaveButton = document.getElementById("leave-group");
    leaveButton.addEventListener("click", () => {
      const modal = new Modal("Leave Group", "Are you sure you want to leave this group?", {
        "Cancel": {
          classes: ["secondary"]
        },
        "Do It": {
          callback() {
            post("/group/leave", { hash_id: hashID }, () => window.location.replace("/"), false, () => modal.close());
          },
          classes: ["primary"]
        }
      }).display();
    });
  }
};
document.addEventListener("DOMContentLoaded", () => Group.domLoaded());
