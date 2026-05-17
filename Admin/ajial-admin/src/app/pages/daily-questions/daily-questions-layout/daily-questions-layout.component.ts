import { Component, OnInit } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-daily-questions-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './daily-questions-layout.component.html',
  styleUrl: './daily-questions-layout.component.scss'
})
export class DailyQuestionsLayoutComponent implements OnInit {
  ngOnInit() {
    document.body.className = 'theme-daily-questions';
  }
}
