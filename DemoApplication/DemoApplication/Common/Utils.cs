using Data.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace DemoApplication.Common
{
    public class Utils
    {
        private IConfiguration configuration;
        public Utils(IConfiguration _configuration)
        {
            configuration = _configuration;
        }

        public string BuildToken(User user)
        {
            string tokenStr = "";
            try
            {
                var claims = new[]
                        {
            new Claim(JwtRegisteredClaimNames.FamilyName, user.FirstName),
            new Claim(JwtRegisteredClaimNames.GivenName, user.LastName),
            new Claim(JwtRegisteredClaimNames.UniqueName, user.Username)
            };
                var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(configuration["Jwt:Key"]));
                var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
                var Issuer = configuration["Jwt:Issuer"] + "";

                var tokenString = new JwtSecurityToken(Issuer,
                Issuer,
                claims: claims,
                expires: DateTime.Now.AddMinutes(810),
                signingCredentials: creds);
                tokenStr = new JwtSecurityTokenHandler().WriteToken(tokenString);
            }
            catch (Exception ex)
            {
            }
            return tokenStr;

        }
    }
}
