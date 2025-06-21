import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdpown"
export default class extends Controller {
  connect() {
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