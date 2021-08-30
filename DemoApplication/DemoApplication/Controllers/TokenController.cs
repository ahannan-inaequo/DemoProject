using BLL.CustomModels;
using BLL.Handlers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System;
using DemoApplication.Common;

namespace DemoApplication.Controllers
{
    [Produces("application/json")]
    [Route("oauth/Token")]
    public class TokenController : Controller
    {
        private IConfiguration configuration;

        public TokenController(IConfiguration _configuration)
        {
            configuration = _configuration;
        }
        [AllowAnonymous]
        [HttpPost]
        [ActionName("CreateToken")]
        [Route("CreateToken")]
        public IActionResult CreateToken([FromBody] LoginModel Content)
        {
            string Username = Content.Username;
            string Password = Content.Password;

            if (!ModelState.IsValid)
                return BadRequest("Token failed to generate");

            var result = new UserHandler().Login(Username, Password);

            if (result == null || result.Id == 0)
                return Ok(new { responseMessage = "Please enter Valid Username and Password." });

            var tokenStr = new Utils(configuration).BuildToken(result);

            var response = new
            {
                Token = tokenStr,
                Expires = DateTime.Now.AddMinutes(810),
                UserDetails = result
            };

            return Ok(response);
        }

    }

}