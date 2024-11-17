import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle-dark-mode"
export default class extends Controller {
  static targets = ["activeThemeIcon", "lightThemeButton", "darkThemeButton", "autoThemeButton"];

  connect() {
    const storedTheme = this.getStoredTheme();
    if (storedTheme) {
      this.setTheme(storedTheme);
      this.showActiveTheme(storedTheme);
    } else {
      this.setTheme('auto');
      this.showActiveTheme('auto');
    }

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      const storedTheme = this.getStoredTheme()
      if (storedTheme !== 'light' && storedTheme !== 'dark') {
        this.setTheme(this.getPreferredTheme())
      }
    })
  }

  getStoredTheme() {
    return localStorage.getItem('theme');
  }

  setStoredTheme(theme) {
    localStorage.setItem('theme', theme);
  }

  getPreferredTheme() {
    const storedTheme = this.getStoredTheme();
    if (storedTheme) {
      return storedTheme;
    }

    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
  }

  changeTheme(event) {
    this.setTheme(event.target.dataset.themeValue);
    this.setStoredTheme(event.target.dataset.themeValue);
    this.showActiveTheme(event.target.dataset.themeValue);
  }

  setTheme(theme) {
    if (theme === 'auto') {
      document.documentElement.setAttribute('data-bs-theme', (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'))
    } else {
      document.documentElement.setAttribute('data-bs-theme', theme)
    }
  }

  showActiveTheme(theme) {
    const themeClasses = {
        dark: 'bi-moon-stars-fill',
        light: 'bi-sun-fill',
        auto: 'bi-circle-half'
    };

    const themeButtons = [
        this.lightThemeButtonTarget,
        this.darkThemeButtonTarget,
        this.autoThemeButtonTarget
    ];

    themeButtons.forEach(button => button.classList.remove('active'));
    this.activeThemeIconTarget.classList.remove(...Object.values(themeClasses));

    if (themeClasses[theme]) {
        this.activeThemeIconTarget.classList.add(themeClasses[theme]);
        this[`${theme}ThemeButtonTarget`].classList.add('active');
    }
}
}
