import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdpown"
export default class extends Controller {
  static targets = ["filterContainer", "filterButton"];
  connect() {
    const urlParams = new URLSearchParams(window.location.search);
    const filters = [];

    urlParams.forEach((value, key) => {
      if (key.startsWith("filters[")) {
        const filterName = key.slice(8, -1); // Extract the key inside "filters[]"
        filters.push({ [filterName]: value });
      }
    });

    if (filters.length > 0) {
      this.filterButtonTarget.classList.add('bg-primary');

      if (this.filterContainerTarget) {
        filters.forEach(filter => {
          // Create a new div element for each filter
          const filterElementId = `filter-${Object.keys(filter)[0]}`;
          if (document.getElementById(filterElementId)) {
            return; // Skip if the filter element already exists
          }
          const filterElement = document.createElement('div');
          filterElement.classList.add('filter-item');
          filterElement.id = filterElementId;

          const [key, value] = Object.entries(filter)[0];
          const capitalizedKey = key.charAt(0).toUpperCase() + key.slice(1);
          filterElement.textContent = `${capitalizedKey}: ${value}`;
          filterElement.classList.add('badge', 'bg-secondary');

          // Create close button
          const closeButton = document.createElement('button');
          closeButton.classList.add('btn-close');
          closeButton.type = 'button';
          closeButton.onclick = () => {
            // Remove the filter from the URL and reload the page
            urlParams.delete(`filters[${key}]`);
            window.location.search = urlParams.toString();
          };
          closeButton.setAttribute('aria-label', 'Close');

          // Append the close button to the filter element
          filterElement.appendChild(closeButton);
          this.filterContainerTarget.appendChild(filterElement);
        });
      }
    }
    else {
      this.filterButtonTarget.classList.remove('bg-primary');
      if (this.filterContainerTarget) {
        this.filterContainerTarget.innerHTML = ''; // Clear the filter container
      }
    }
  }
}