import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdpown"
export default class extends Controller {
  static targets = ["filterContainerDesktop", "filterContainerMobile", "filterButton", "searchInput"];
  connect() {
    const filters = [];
    const urlParams = new URLSearchParams(window.location.search);

    urlParams.forEach((value, key) => {
      if (key.startsWith("filters[")) {
        const filterName = key.slice(8, -1); // Extract the key inside "filters[]"
        filters.push({ [filterName]: value });
      }
    });

    let filterContainer = null;

    if (window.innerWidth <= 768) {
      if (this.hasFilterContainerMobileTarget) {
        filterContainer = this.filterContainerMobileTarget;
      }
    } else {
      if (this.hasFilterContainerDesktopTarget) {
        filterContainer = this.filterContainerDesktopTarget;
      }
    }

    this.doFiltering(filters, urlParams, filterContainer);
  }

  doFiltering(filters, urlParams, filterContainer) {
    if (filters.length > 0) {
      this.filterButtonTarget.classList.add('bg-primary');

      if (filterContainer) {
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

          // Additional functionality for search filter
          if(capitalizedKey == "Query") {
            this.searchInputTarget.value = value;
          }

          // Create close button
          const closeButton = document.createElement('button');
          closeButton.classList.add('btn-close');
          closeButton.type = 'button';
          closeButton.onclick = () => {
            // Remove the filter from the URL and perform a Turbo reload
            urlParams.delete(`filters[${key}]`);
            Turbo.visit(`${window.location.pathname}?${urlParams.toString()}`);
          };
          closeButton.setAttribute('aria-label', 'Close');

          // Append the close button to the filter element
          filterElement.appendChild(closeButton);
          filterContainer.appendChild(filterElement);
        });
      }
    }
    else {
      this.filterButtonTarget.classList.remove('bg-primary');
      if (filterContainer) {
        filterContainer.innerHTML = ''; // Clear the filter container
      }
    }
  }
}