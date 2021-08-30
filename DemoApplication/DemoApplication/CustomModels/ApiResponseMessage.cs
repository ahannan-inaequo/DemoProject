using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;

namespace DemoApplication.Models
{
    public class ApiResponseMessage
    {
        public ApiResponseMessage()
        {
            this.Message = "Request Failed.";
        }
        public HttpStatusCode Status { get; set; }
        public string Message { get; set; }
        public object Response { get; set; }
    }
}
