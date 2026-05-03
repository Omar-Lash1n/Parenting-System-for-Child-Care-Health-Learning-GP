import { Component, OnInit } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';

@Component({
  selector: 'app-specialists-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './specialists-layout.component.html',
  styleUrl: './specialists-layout.component.scss'
})
export class SpecialistsLayoutComponent implements OnInit {
  ngOnInit() {
    document.body.className = 'theme-specialists';
  }
}
