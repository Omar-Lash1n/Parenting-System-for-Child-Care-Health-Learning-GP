import { Component, OnInit } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-ranking-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './ranking-layout.component.html',
  styleUrl: './ranking-layout.component.scss'
})
export class RankingLayoutComponent implements OnInit {
  ngOnInit() {
    const isLight = document.body.classList.contains('light-mode');
    document.body.className = isLight ? 'light-mode theme-ranking' : 'theme-ranking';
  }
}
