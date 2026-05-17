import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';

export type LoadingSpinnerSize = 'sm' | 'md' | 'lg';

@Component({
  selector: 'app-loading-spinner',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './loading-spinner.component.html',
  styleUrl: './loading-spinner.component.scss'
})
export class LoadingSpinnerComponent {
  @Input() size: LoadingSpinnerSize = 'md';
  @Input() overlay = false;
}
