using BLL.CustomModels;
using Data.Common;
using Data.Models;
using Data.Repositories;
using System;
using System.Net;

namespace BLL.Handlers
{
    public class UserHandler : IDisposable
    {
        public ApiResponseMessage SignUp(User user)
        {
            var response = new ApiResponseMessage();
            response.Status = HttpStatusCode.OK;

            var encryptedPw = Utils.Encrypt(user.Password);
            user.Password = encryptedPw;
            user.CreatedOn = DateTime.Now;

            User result = new UserRepository().Add(user);
            if (result.Id > 0)
            {
                response.Message = "User added successfully";
                response.Response = result;
            }
            else
            {
                response.Message = "Failed, an error has occured.";
                response.Response = "";
            }
            return response;
        }

        public User Login(string username, string password)
        {
            var encryptedPw = Utils.Encrypt(password);
            User result = new UserRepository().Login(username, encryptedPw);
            return result;
        }

        public void Dispose()
        {
            GC.SuppressFinalize(true);
        }
    }
}
