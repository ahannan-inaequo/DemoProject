using Data.Models;
using System;
using System.Collections.Generic;
using System.Text;

namespace BLL.CustomModels
{
    public class UserVM
    {
        public string Username { get; set; }
        public string Password { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public DateTime DateOfBirth { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        public int? CountryId { get; set; }
        public int? StateId { get; set; }
        public int? CityId { get; set; }
        public string Address { get; set; }
        public string Zip { get; set; }
        public bool? IsVerified { get; set; }
    }

    public class LoginModel
    {
        public string Username { get; set; }
        public string Password { get; set; }
    }

    public class PasswordModel
    {
        public string OldPassword { get; set; }
        public string Password { get; set; }
        public string ConfirmPassword { get; set; }
    }
}
