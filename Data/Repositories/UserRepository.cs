using Data.Models;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Data.Repositories
{
    public class UserRepository : IDisposable
    {
        public User Add(User user)
        {
            try
            {
                using (var _context = Db.Create())
                {
                    _context.Add(user);
                    _context.SaveChanges();
                }

                return user;
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public User Update(User user)
        {
            try
            {
                using (var _context = Db.Create())
                {
                    _context.Update(user);
                    _context.SaveChanges();
                }

                return user;
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public bool Delete(List<int> userIds)
        {
            try
            {
                using (var _context = Db.Create())
                {

                    var user = _context.Users.Where(o => userIds.Contains(o.Id)).ToList();
                    _context.RemoveRange(user);
                    _context.SaveChanges();
                }

                return true;
            }
            catch (Exception ex)
            {
                return false;
            }
        }

        public User Get(int id)
        {
            try
            {
                using (var _context = Db.Create())
                {

                    var user = _context.Users.FirstOrDefault(o => o.Id == id);
                    return user;
                }
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public User Login(string username,string password)
        {
            try
            {
                using (var _context = Db.Create())
                {
                    var user = _context.Users.FirstOrDefault(o => o.Username == username && o.Password == password && (o.IsVerified == null ? false : true) == true);
                    return user;
                }
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public List<User> GetAll()
        {
            List<User> users = new List<User>();
            try
            {
                using (var _context = Db.Create())
                {
                    users = _context.Users.ToList();
                }
            }
            catch (Exception ex)
            {
            }
            return users;

        }

        public void Dispose()
        {
            GC.SuppressFinalize(true);
        }

    }
}
