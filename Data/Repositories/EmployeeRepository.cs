using Data.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Data.Repositories
{
    public partial class EmployeeRepository : IDisposable
    {
        public Employee Add(Employee employee)
        {
            try
            {
                using (var _context = Db.Create())
                {
                    _context.Add(employee);
                    _context.SaveChanges();
                }

                return employee;
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public Employee Update(Employee employee)
        {
            try
            {
                using (var _context = Db.Create())
                {
                    _context.Update(employee);
                    _context.SaveChanges();
                }

                return employee;
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public bool Delete(List<int> employeeIds)
        {
            try
            {
                using (var _context = Db.Create())
                {

                    var user = _context.Employees.Where(o => employeeIds.Contains(o.Id)).ToList();
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

        public Employee Get(int id)
        {
            try
            {
                using (var _context = Db.Create())
                {

                    var employee = _context.Employees.FirstOrDefault(o => o.Id == id);
                    return employee;
                }
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public List<Employee> List()
        {
            try
            {
                using (var _context = Db.Create())
                {

                    var employee = _context.Employees.ToList();
                    return employee;
                }
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        public void Dispose()
        {
            GC.SuppressFinalize(true);
        }

    }
}
