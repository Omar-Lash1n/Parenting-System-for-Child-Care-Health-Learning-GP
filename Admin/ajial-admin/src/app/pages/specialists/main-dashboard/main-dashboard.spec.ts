import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MainDashboard } from './main-dashboard';

describe('MainDashboard', () => {
  let component: MainDashboard;
  let fixture: ComponentFixture<MainDashboard>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MainDashboard],
    }).compileComponents();

    fixture = TestBed.createComponent(MainDashboard);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
