import { Component, OnInit } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-lessons-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './lessons-layout.component.html',
  styleUrl: './lessons-layout.component.scss'
})
export class LessonsLayoutComponent implements OnInit {
  ngOnInit() {
    document.body.className = 'theme-lessons';
  }
}
