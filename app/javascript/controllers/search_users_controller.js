import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["searchInput", "userSelect", "userIds", "selectedUsers"];

  selectedUserIds = [];

  search() {
    if(this.searchInputTarget.value.length > 3) {
      clearTimeout(this.timeout)
      this.timeout = setTimeout(() => {
        this.element.requestSubmit()
      }, 250)
    }
  }

  selectResult(event) {
    if(this.userIdsTarget.value.includes(event.target.value)) {
      const userIds = JSON.parse(this.userIdsTarget.value || '[]');
      this.userIdsTarget.value = JSON.stringify(userIds.filter(id => id !== event.target.value));
    } else {
      const userIds = JSON.parse(this.userIdsTarget.value || '[]');
      userIds.push(event.target.value);
      this.userIdsTarget.value = JSON.stringify(userIds);
    }
    this.toggleSelectedUser(event.target);
  }

  toggleSelectedUser(target) {
    if(this.selectedUserIds.includes(target.value)) {
      this.selectedUserIds = this.selectedUserIds.filter(id => id !== target.value);
      this.selectedUsersTarget.querySelector(`[data-value="${target.value}"]`).remove();
      return;
    } else {
      this.selectedUserIds.push(target.value);
      this.selectedUsersTarget.insertAdjacentHTML(
        'beforeend',
        `<div class="selected-user" data-value="${target.value}">${target.innerText}</div>`
      );
    }
  }
}
