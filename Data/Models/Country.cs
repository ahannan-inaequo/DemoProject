using System;
using System.Collections.Generic;

#nullable disable

namespace Data.Models
{
    public partial class Country
    {
        public Country()
        {
            Users = new HashSet<User>();
        }

        public int Id { get; set; }
        public string ShortName { get; set; }
        public string Name { get; set; }
        public int? PhoneCode { get; set; }

        public virtual ICollection<User> Users { get; set; }
    }
}
