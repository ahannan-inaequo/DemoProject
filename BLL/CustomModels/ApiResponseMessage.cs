using System;
using System.Collections.Generic;
using System.Net;
using System.Text;

namespace BLL.CustomModels
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
