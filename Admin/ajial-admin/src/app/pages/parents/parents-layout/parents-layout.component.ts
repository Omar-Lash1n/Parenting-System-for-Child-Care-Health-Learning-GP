import { Component, OnInit } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';

@Component({
  selector: 'app-parents-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './parents-layout.component.html',
  styleUrl: './parents-layout.component.scss'
})
export class ParentsLayoutComponent implements OnInit {
  ngOnInit() {
    const isLight = document.body.classList.contains('light-mode');
    document.body.className = isLight ? 'light-mode theme-parents' : 'theme-parents';
  }
}
