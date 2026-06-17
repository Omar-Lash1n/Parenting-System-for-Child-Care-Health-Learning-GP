import { Component, OnInit, ElementRef, ViewChild, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AnalyticsService, Child } from '../../../services/analytics.service';
import Chart from 'chart.js/auto';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  analyticsService = inject(AnalyticsService);
  cdr = inject(ChangeDetectorRef);

  children: Child[] = [];
  loading = true;
  hasError = false;

  summary = {
    totalChildren: 0,
    maleCount: 0,
    femaleCount: 0,
    averageAge: 0,
  };

  @ViewChild('ageGroupChart') ageGroupChart!: ElementRef;
  @ViewChild('genderChart') genderChart!: ElementRef;
  @ViewChild('citiesChart') citiesChart!: ElementRef;
  @ViewChild('activeChart') activeChart!: ElementRef;

  ngOnInit() {
    this.fetchData();
  }

  fetchData() {
    this.loading = true;
    this.hasError = false;
    this.cdr.detectChanges();

    this.analyticsService.getChildrenAnalytics().subscribe({
      next: (res) => {
        if (res.success) {
          this.children = res.data;
          this.computeSummary();
          this.loading = false;
          this.cdr.detectChanges(); // force view update
          this.initCharts();
        }
      },
      error: (err) => {
        console.error('Children analytics fetch error:', err);
        this.hasError = true;
        this.loading = false;
        this.cdr.detectChanges();
      }
    });
  }

  computeSummary() {
    this.summary.totalChildren = this.children.length;
    this.summary.maleCount = this.children.filter(c => c.childGender === 'ذكر').length;
    this.summary.femaleCount = this.children.filter(c => c.childGender === 'أنثى').length;
    
    if (this.children.length > 0) {
      const totalAge = this.children.reduce((sum, c) => sum + c.childAge, 0);
      this.summary.averageAge = Math.round(totalAge / this.children.length);
    }
  }

  initCharts() {
    if (this.children.length === 0) return;

    // Destroy existing charts to prevent duplication on re-render
    if ((this.ageGroupChart.nativeElement as any).__chart) (this.ageGroupChart.nativeElement as any).__chart.destroy();
    if ((this.genderChart.nativeElement as any).__chart) (this.genderChart.nativeElement as any).__chart.destroy();
    if ((this.citiesChart.nativeElement as any).__chart) (this.citiesChart.nativeElement as any).__chart.destroy();
    if ((this.activeChart.nativeElement as any).__chart) (this.activeChart.nativeElement as any).__chart.destroy();

    // Calculate distributions
    const ageGroups: { [key: string]: number } = {};
    const cities: { [key: string]: number } = {};
    let activeAccounts = 0;
    let inactiveAccounts = 0;

    this.children.forEach(child => {
      ageGroups[child.ageGroup] = (ageGroups[child.ageGroup] || 0) + 1;
      cities[child.cityNameAr] = (cities[child.cityNameAr] || 0) + 1;
      if (child.childHasAccount) activeAccounts++; else inactiveAccounts++;
    });

    // Age Groups Chart
    (this.ageGroupChart.nativeElement as any).__chart = new Chart(this.ageGroupChart.nativeElement, {
      type: 'pie',
      data: {
        labels: Object.keys(ageGroups),
        datasets: [{
          data: Object.values(ageGroups),
          backgroundColor: ['#f59e0b', '#10b981', '#3b82f6', '#f472b6', '#6366f1'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: 'bottom', labels: { color: '#8b8fa3' } } }
      }
    });

    // Gender Chart
    (this.genderChart.nativeElement as any).__chart = new Chart(this.genderChart.nativeElement, {
      type: 'pie',
      data: {
        labels: ['ذكور', 'إناث'],
        datasets: [{
          data: [this.summary.maleCount, this.summary.femaleCount],
          backgroundColor: ['#3b82f6', '#f472b6'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: 'bottom', labels: { color: '#8b8fa3' } } }
      }
    });

    // Cities Chart
    (this.citiesChart.nativeElement as any).__chart = new Chart(this.citiesChart.nativeElement, {
      type: 'bar',
      data: {
        labels: Object.keys(cities),
        datasets: [{
          label: 'عدد الأطفال',
          data: Object.values(cities),
          backgroundColor: '#10b981',
          borderRadius: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: { beginAtZero: true, grid: { color: '#2a2e3f' }, ticks: { color: '#8b8fa3' } },
          x: { grid: { display: false }, ticks: { color: '#8b8fa3' } }
        },
        plugins: { legend: { display: false } }
      }
    });

    // Accounts Chart
    (this.activeChart.nativeElement as any).__chart = new Chart(this.activeChart.nativeElement, {
      type: 'pie',
      data: {
        labels: ['لديهم حساب', 'بدون حساب'],
        datasets: [{
          data: [activeAccounts, inactiveAccounts],
          backgroundColor: ['#10b981', '#ef4444'],
          borderWidth: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { position: 'bottom', labels: { color: '#8b8fa3' } } }
      }
    });
  }
}
