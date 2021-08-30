using System;
using Microsoft.AspNetCore.Mvc;
using System.Net;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Diagnostics;

namespace DemoApplication.Controllers
{
    [Produces("application/json")]
    [Route("api/Message")]
    public class ErrorController : Controller
    {
        [HttpPost]
        public IActionResult Error()
        {
            // Gets the status code from the exception or web server.
            var statusCode = HttpContext.Features.Get<IExceptionHandlerFeature>()?.Error is HttpException httpEx ?
                httpEx.StatusCode : (HttpStatusCode)Response.StatusCode;

            // For API errors, responds with just the status code (no page).
            if (HttpContext.Features.Get<IHttpRequestFeature>().RawTarget.StartsWith("/api/", StringComparison.Ordinal))
                return StatusCode((int)statusCode);

            // Creates a view model for a user-friendly error page.
            string text = null;
            switch (statusCode)
            {
                case HttpStatusCode.NotFound: text = "Page not found."; break;
                    // Add more as desired.
            }
            return Ok(text);
        }
    }
    public class HttpException : Exception
    {
        public HttpException(HttpStatusCode statusCode) { StatusCode = statusCode; }
        public HttpStatusCode StatusCode { get; private set; }
    }
}