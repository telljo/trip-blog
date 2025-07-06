import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdpown"
export default class extends Controller {
  connect() {
    document.addEventListener('DOMContentLoaded', () => {

      this.setupHoverToggle();
    });
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

  setupHoverToggle() {
    if (window.matchMedia('(min-width: 1024px)').matches) {
      const dropdownSubmenus = document.querySelectorAll('.dropdown-submenu');

      dropdownSubmenus.forEach(function (submenu) {
        submenu.addEventListener('mouseover', function () {
          const dropdownMenu = submenu.querySelector('.dropdown-menu');
          if (dropdownMenu) {
            dropdownMenu.classList.add('show');
          }
        });

        let closeTimeout;

        submenu.addEventListener('mouseout', function () {
          closeTimeout = setTimeout(() => {
            const dropdownMenu = submenu.querySelector('.dropdown-menu');
            if (dropdownMenu) {
              dropdownMenu.classList.remove('show');
            }
          }, 300);
        });

        submenu.addEventListener('mouseover', function () {
          clearTimeout(closeTimeout);
        });
      });
    }
  }
}