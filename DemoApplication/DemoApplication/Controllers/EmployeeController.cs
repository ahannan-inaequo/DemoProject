using BLL.Handlers;
using Data.Models;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;

namespace DemoApplication.Controllers
{
    [Produces("application/json")]
    [Route("api/employee")]  //We can also do this like api/[controller]
    public class EmployeeController : Controller
    {
        private EmployeeHandler _employeeHandler;

        public EmployeeController(EmployeeHandler employeeHandler)
        {
            _employeeHandler = employeeHandler;
        }

        [HttpPost]
        [Route("save")]
        public ActionResult Save([FromBody] Employee user)
        {
            var result = _employeeHandler.Save(user);
            return Ok(result);
        }

        [HttpGet]
        [Route("get")]
        public ActionResult Save(int id)
        {
            var result = _employeeHandler.Get(id);
            return Ok(result);
        }

        [HttpDelete]
        [Route("list")]
        public ActionResult delete()
        {
            var result = _employeeHandler.List();
            return Ok(result);
        }

        [HttpDelete]
        [Route("delete")]
        public ActionResult delete([FromBody] List<int> ids)
        {
            var result = _employeeHandler.Delete(ids);
            return Ok(result);
        }
    }
}
