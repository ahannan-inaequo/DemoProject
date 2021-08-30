import { Inject, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  constructor(private http: HttpClient) { }


login(model):Observable<any>{
  return this.http.post<Object[]>('oauth/Token/CreateToken',model);
}

}
