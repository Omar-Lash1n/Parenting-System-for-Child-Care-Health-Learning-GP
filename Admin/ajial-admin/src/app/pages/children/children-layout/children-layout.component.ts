import { Component, OnInit } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';

@Component({
  selector: 'app-children-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './children-layout.component.html',
  styleUrl: './children-layout.component.scss'
})
export class ChildrenLayoutComponent implements OnInit {
  ngOnInit() {
    document.body.className = 'theme-children';
  }
}
