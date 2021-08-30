using BLL.Handlers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DemoApplication.Controllers
{
    [Produces("application/json")]
    [Route("short/list")]
    public class CommonController : Controller
    {
        CommonHandler commonHandler = null;

        public CommonController()
        {
            commonHandler = new CommonHandler();
        } 

        [Authorize]
        [HttpGet]
        [Route("countries")]
        public ActionResult Countries()
        {
            var result = commonHandler.Countries();
            return Ok(result);
        }

        [Authorize]
        [HttpGet]
        [Route("cities")]
        public ActionResult Cities(int stateId)
        {
            var result = commonHandler.Cities(stateId);
            return Ok(result);
        }

        [Authorize]
        [HttpGet]
        [Route("states")]
        public ActionResult States(int countryId)
        {
            var result = commonHandler.States(countryId);
            return Ok(result);
        }

        [Authorize]
        [HttpGet]
        [Route("designations")]
        public ActionResult Desingtions()
        {
            var result = commonHandler.Desingtions();
            return Ok(result);
        }
    }
}
