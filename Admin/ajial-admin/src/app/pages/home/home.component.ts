import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [RouterLink],
  templateUrl: './home.component.html',
  styleUrl: './home.component.scss'
})
export class HomeComponent {
  logoSrc: string;

  constructor() {
    // Reset body theme class on home page but preserve light-mode
    const isLight = document.body.classList.contains('light-mode');
    document.body.className = isLight ? 'light-mode' : '';
    this.logoSrc = isLight ? '/images/logo-primary-color.png' : '/images/logo.png';
  }
}
