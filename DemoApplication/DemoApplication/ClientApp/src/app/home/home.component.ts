import { Component } from '@angular/core';
import { ApiService } from '../Services/APIService';
import { Observable, Subscription } from 'rxjs';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
})
export class HomeComponent {
  public observables = new Subscription();
  username;
  password;
  model;
  constructor(private apiService:ApiService){
  
  }

  public Login() 
  {
    this.model = {
    "UserName":this.username,
    "Password":this.password
  }
  this.observables.add(this.apiService.login(this.model).subscribe(x => {

  }))
  }
  ngOnDestroy(): void {
    this.observables.unsubscribe();
  }

  }

