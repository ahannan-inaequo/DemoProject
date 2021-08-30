using BLL.Handlers;
using Data.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DemoApplication.Controllers
{
    [Produces("application/json")]
    [Route("api/user")]
    public class UserController : Controller
    {
        UserHandler userHandler = null;

        public UserController()
        {
            userHandler = new UserHandler();
        }

        [AllowAnonymous]
        [HttpPost]
        [Route("sign-up")]
        public ActionResult SignUp([FromBody] User user)
        {
            var result = userHandler.SignUp(user);
            return Ok(result);
        }
    }
}
