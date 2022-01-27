import { EditableList } from '../lib/editable_list'
import { EditableField } from '../lib/editable_field'
import { Modal } from '../lib/modal'
import { getElementsByXPath } from '../lib/dom'
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
        () => {}, // successCallback
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

    // Delete group.
    // const deleteButton = document.getElementById('delete-group');
    // deleteButton.addEventListener('click', () => {
    //   const modal = new Modal(
    //     'Are you sure?',
    //     "Deleting this group will also delete all it's polls", {
    //     'Cancel': {
    //       classes: ['secondary']
    //     },
    //     'Do It': {
    //       callback: () => {
    //         post('/group/destroy',
    //           { hash_id: hashID },
    //           () => window.location.replace('/'), // successCallback
    //           false, // errorCallback
    //           () => modal.close()); // finallyCallback
    //       },
    //       classes: ['primary']
    //     }
    //   }).display();
    // });
  }
}

document.addEventListener("DOMContentLoaded", () => Poll.domLoaded());
