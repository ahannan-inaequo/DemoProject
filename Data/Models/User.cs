using System;
using System.Collections.Generic;

#nullable disable

namespace Data.Models
{
    public partial class User
    {
        public User()
        {
            UserInRoles = new HashSet<UserInRole>();
        }

        public int Id { get; set; }
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
        public DateTime CreatedOn { get; set; }
        public int? UpdatedBy { get; set; }
        public DateTime? UpdatedOn { get; set; }

        public virtual City City { get; set; }
        public virtual Country Country { get; set; }
        public virtual State State { get; set; }
        public virtual ICollection<UserInRole> UserInRoles { get; set; }
    }
}
