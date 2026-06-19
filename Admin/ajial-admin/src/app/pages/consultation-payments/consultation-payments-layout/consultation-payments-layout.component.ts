import { Component, OnInit } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';

@Component({
  selector: 'app-consultation-payments-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './consultation-payments-layout.component.html',
  styleUrl: './consultation-payments-layout.component.scss'
})
export class ConsultationPaymentsLayoutComponent implements OnInit {
  ngOnInit() {
    const isLight = document.body.classList.contains('light-mode');
    document.body.className = isLight ? 'light-mode theme-consultation-payments' : 'theme-consultation-payments';
  }
}
