using BLL.CustomModels;
using Data.Models;
using System.Collections.Generic;

namespace BLL.Handlers
{
    public interface IEmployeeHandler
    {
        ApiResponseMessage Save(Employee emp);
        ApiResponseMessage Get(int id);
        ApiResponseMessage List();
        ApiResponseMessage Delete(List<int> ids);
    }
}
