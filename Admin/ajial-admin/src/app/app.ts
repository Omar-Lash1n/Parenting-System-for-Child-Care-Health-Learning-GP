import { Component, signal, OnInit } from '@angular/core';
import { RouterOutlet, RouterLink } from '@angular/router';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App implements OnInit {
  protected readonly title = signal('ajial-admin');
  isLightMode = false;

  ngOnInit() {
    const savedTheme = localStorage.getItem('ajial-theme');
    if (savedTheme === 'light') {
      this.isLightMode = true;
      document.body.classList.add('light-mode');
    } else {
      // Default is dark mode
      this.isLightMode = false;
      document.body.classList.remove('light-mode');
    }
  }

  toggleTheme() {
    this.isLightMode = !this.isLightMode;
    if (this.isLightMode) {
      document.body.classList.add('light-mode');
      localStorage.setItem('ajial-theme', 'light');
    } else {
      document.body.classList.remove('light-mode');
      localStorage.setItem('ajial-theme', 'dark');
    }
  }
}
