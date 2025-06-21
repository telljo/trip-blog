import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdpown"
export default class extends Controller {
  connect() {
  }

  toggleFilters(event) {
    event.preventDefault();
    event.stopPropagation();
    const submenu = event.currentTarget.closest('.dropdown-submenu');
    const dropdownMenu = submenu.querySelector('.dropdown-menu');

    // Add your logic to show/hide filters here
    dropdownMenu.classList.add('show');
  }

  hideNestedDropdown() {
    // Find and hide any nested dropdown menus
    const nestedDropdowns = this.element.querySelectorAll('.dropdown-menu');
    nestedDropdowns.forEach(menu => menu.classList.remove('show'));
  }
}