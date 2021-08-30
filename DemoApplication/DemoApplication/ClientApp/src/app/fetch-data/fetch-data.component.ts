import { Component, Inject, OnDestroy } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { ApiService } from '../Services/APIService';
import { Observable, Subscription } from 'rxjs';

@Component({
  selector: 'app-fetch-data',
  templateUrl: './fetch-data.component.html'
})
export class FetchDataComponent implements OnDestroy {
  public forecasts: WeatherForecast[];
  public observavles = new Subscription();
  constructor(http: HttpClient, apiService: ApiService) {

    this.observavles.add(apiService.fetch_data().subscribe(x => {
      this.forecasts = x;
    }))
  }
  ngOnDestroy(): void {
    this.observavles.unsubscribe();
  }
}

interface WeatherForecast {
  date: string;
  temperatureC: number;
  temperatureF: number;
  summary: string;
}
