import { Component, OnInit, ViewChild, ElementRef, inject, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AnalyticsService, Parent, ParentSummary } from '../../../services/analytics.service';
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
  
  parents: Parent[] | null = null;
  summary: ParentSummary | null = null;
  loading = true;

  @ViewChild('ageGroupChart') ageGroupChart!: ElementRef;
  @ViewChild('genderChart') genderChart!: ElementRef;
  @ViewChild('citiesChart') citiesChart!: ElementRef;
  @ViewChild('regionsChart') regionsChart!: ElementRef;

  ngOnInit() {
    this.fetchData();
  }

  fetchData() {
    this.analyticsService.getParentsSummary().subscribe({
      next: (res) => {
        if (res.success) {
          this.summary = res.data;
          this.checkAndInitCharts();
        }
      }
    });

    this.analyticsService.getParentsAnalytics().subscribe({
      next: (res) => {
        if (res.success) {
          this.parents = res.data;
          this.checkAndInitCharts();
        }
      }
    });
  }

  checkAndInitCharts() {
    // Only init when both APIs are loaded
    if (this.summary && this.parents !== null && this.loading) {
      this.loading = false;
      this.cdr.detectChanges(); // force rendering of canvases
      this.initCharts();
    }
  }

  initCharts() {
    if (!this.summary) return;

    // Destroy existing charts to prevent duplication on re-render
    if ((this.ageGroupChart.nativeElement as any).__chart) (this.ageGroupChart.nativeElement as any).__chart.destroy();
    if ((this.genderChart.nativeElement as any).__chart) (this.genderChart.nativeElement as any).__chart.destroy();
    if ((this.citiesChart.nativeElement as any).__chart) (this.citiesChart.nativeElement as any).__chart.destroy();
    if ((this.regionsChart.nativeElement as any).__chart) (this.regionsChart.nativeElement as any).__chart.destroy();

    // Age Groups Chart
    const ageLabels = this.summary.ageGroups.map(a => a.ageGroup);
    const ageData = this.summary.ageGroups.map(a => a.count);
    (this.ageGroupChart.nativeElement as any).__chart = new Chart(this.ageGroupChart.nativeElement, {
      type: 'pie',
      data: {
        labels: ageLabels,
        datasets: [{
          data: ageData,
          backgroundColor: ['#6366f1', '#8b5cf6', '#f472b6', '#14b8a6', '#f59e0b'],
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
    const cityLabels = this.summary.citiesDistribution.map(c => c.city);
    const cityData = this.summary.citiesDistribution.map(c => c.count);
    (this.citiesChart.nativeElement as any).__chart = new Chart(this.citiesChart.nativeElement, {
      type: 'bar',
      data: {
        labels: cityLabels,
        datasets: [{
          label: 'عدد الوالدين',
          data: cityData,
          backgroundColor: '#6366f1',
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

    // Regions Chart
    const regionLabels = this.summary.regionsDistribution.map(r => r.region);
    const regionData = this.summary.regionsDistribution.map(r => r.count);
    (this.regionsChart.nativeElement as any).__chart = new Chart(this.regionsChart.nativeElement, {
      type: 'pie',
      data: {
        labels: regionLabels,
        datasets: [{
          data: regionData,
          backgroundColor: ['#10b981', '#f59e0b', '#3b82f6', '#ef4444'],
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

