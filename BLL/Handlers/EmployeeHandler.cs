using BLL.CustomModels;
using Data.Models;
using Data.Repositories;
using System;
using System.Collections.Generic;
using System.Net;
using System.Text;

namespace BLL.Handlers
{
    public class EmployeeHandler : IEmployeeHandler 
    { 
        /// <summary>
        /// This will handle the save and update of Employee
        /// </summary>
        /// <param name="emp"></param>
        /// <returns></returns>
        public ApiResponseMessage Save(Employee emp)
        {
            var result = new Employee();
            var response = new ApiResponseMessage();
            response.Status = HttpStatusCode.OK;
            using (var empData = new EmployeeRepository())
            {
                if (emp != null && emp.Id > 0)
                {
                    emp.UpdatedBy = 1;
                    emp.UpdatedOn = DateTime.Now;
                    result = empData.Update(emp);
                }
                else
                {
                    emp.CreatedBy = 1;
                    emp.CreatedOn = DateTime.Now;
                    result = empData.Add(emp);
                }
            }

            if (result.Id > 0)
            {
                response.Message = "Employee added successfully";
                response.Response = result;
            }
            else
            {
                response.Message = "Failed, an error has occured.";
                response.Response = "";
            }
            return response;
        }

        /// <summary>
        /// This will be used to get the employee by id
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public ApiResponseMessage Get(int id)
        {
            var result = new Employee();
            var response = new ApiResponseMessage();
            response.Status = HttpStatusCode.OK;
            using (var empData = new EmployeeRepository())
            {
                if (id > 0)
                {
                    result = empData.Get(id);
                }
            }

            if (result.Id > 0)
            {
                response.Message = "User found.";
                response.Response = result;
            }
            else
            {
                response.Message = "Failed, an error has occured.";
                response.Response = "";
            }
            return response;
        }

        public ApiResponseMessage List()
        {
            var result = new List<Employee>();
            var response = new ApiResponseMessage();
            response.Status = HttpStatusCode.OK;
            using (var empData = new EmployeeRepository())
            {
                result = empData.List();
            }

            if (result.Count > 0)
            {
                response.Message = "Users found.";
                response.Response = result;
            }
            else
            {
                response.Message = "Failed, an error has occured.";
                response.Response = "";
            }
            return response;
        }

        public ApiResponseMessage Delete(List<int> ids)
        {
            bool isDeleted = false;
            var response = new ApiResponseMessage();
            response.Status = HttpStatusCode.OK;
            using (var empData = new EmployeeRepository())
            {
                if (ids.Count > 0)
                {
                    isDeleted = empData.Delete(ids);
                }
            }

            if (isDeleted)
            {
                response.Message = "User deleted successfully";
                response.Response = isDeleted;
            }
            else
            {
                response.Message = "Failed, an error has occured.";
                response.Response = "";
            }
            return response;
        }

    }
}
