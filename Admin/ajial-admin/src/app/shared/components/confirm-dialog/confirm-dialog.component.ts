import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';

export type ConfirmDialogType = 'danger' | 'warning' | 'info';

@Component({
  selector: 'app-confirm-dialog',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './confirm-dialog.component.html',
  styleUrl: './confirm-dialog.component.scss'
})
export class ConfirmDialogComponent {
  @Input({ required: true }) title = '';
  @Input({ required: true }) message = '';
  @Input() confirmText = 'تأكيد';
  @Input() cancelText = 'إلغاء';
  @Input() type: ConfirmDialogType = 'info';

  @Output() closed = new EventEmitter<boolean>();
}
