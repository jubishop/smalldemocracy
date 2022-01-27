import { EditableList } from '../lib/editable_list'
import { EditableField } from '../lib/editable_field'
import { Modal } from '../lib/modal'
import { getElementsByXPath, eventEnter } from '../lib/dom'
import { post } from '../lib/ajax'

class Poll {
  static domLoaded() {
    // Extract poll `hashid` first.
    const choicesList = document.getElementById('choices');
    const hashID = choicesList.getAttribute("data-id");

    // Edit title.
    const editTitleButton = document.getElementById('edit-title-button');
    if (editTitleButton) {
      new EditableField(
        document.getElementById('poll-title'),
        editTitleButton,
        '/poll/title',
        (textContent) => { // editCallback
          return {
            hash_id: hashID,
            title: textContent
          };
        }
      );
    }

    // Edit question.
    const editQuestionButton = document.getElementById('edit-question-button');
    if (editQuestionButton) {
      new EditableField(
        document.getElementById('poll-question'),
        editQuestionButton,
        '/poll/question',
        (textContent) => { // editCallback
          return {
            hash_id: hashID,
            question: textContent
          };
        },
        () => { }, // successCallback
        {
          textElementType: 'h4'
        }
      );
    }

    // Add and remove choices.
    const addChoiceButton = document.getElementById('add-choice');
    if (addChoiceButton) {
      new EditableList(
        choicesList,
        getElementsByXPath("//li[@class='editable']"),
        addChoiceButton,
        '/poll/add_choice',
        '/poll/remove_choice',
        (choiceToAdd) => {
          return {
            hash_id: hashID,
            choice: choiceToAdd,
          };
        },
        (elementToDelete) => {
          return {
            hash_id: hashID,
            choice: elementToDelete.firstElementChild.textContent.trim()
          };
        },
        {
          placeholderText: 'Add choice'
        });
    }

    // Edit expiration.
    const expirationButton = document.getElementById('update-expiration');
    const expirationInput = document.getElementsByName('expiration')[0];
    const postCallback = () => {
      post('/poll/expiration',
        {
          hash_id: hashID,
          expiration: expirationInput.value
        },
        () => { }, //successCallback
        () => { // errorCallback
          expirationButton.disabled = false;
        });
    }
    expirationButton.addEventListener('click', (event) => {
      expirationButton.disabled = true;
      postCallback();
    });
    eventEnter(expirationInput, (event) => {
      expirationButton.disabled = true;
      postCallback();
    });
    expirationInput.addEventListener('change', (event) => {
      expirationButton.disabled = false;
    });

    // Delete poll.
    const deleteButton = document.getElementById('delete-poll');
    deleteButton.addEventListener('click', () => {
      const modal = new Modal(
        'Are you sure?',
        "Deleting this poll will also delete all it's responses", {
        'Cancel': {
          classes: ['secondary']
        },
        'Do It': {
          callback: () => {
            post('/poll/destroy',
              { hash_id: hashID },
              () => window.location.replace('/'), // successCallback
              false, // errorCallback
              () => modal.close()); // finallyCallback
          },
          classes: ['primary']
        }
      }).display();
    });
  }
}

document.addEventListener("DOMContentLoaded", () => Poll.domLoaded());
