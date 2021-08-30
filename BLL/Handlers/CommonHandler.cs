using BLL.CustomModels;
using Data.Repositories;
using System;
using System.Linq;

namespace BLL.Handlers
{
    public class CommonHandler : IDisposable
    {
        public object Countries()
        {
            var countries = new CommonRepository().ListCountries();
            var result  = countries.Select(x => new SelectListItem()
            {
                Id = x.Id,
                Text = x.Name,
                Code = x.ShortName
            }).ToList();
            return result;
        }

        public object States(int countryid)
        {
            var states = new CommonRepository().ListStates(countryid);
            var result = states.Select(x => new SelectListItem()
            {
                Id = x.Id,
                Text = x.Name
            }).ToList();
            return result;
        }

        public object Cities(int stateId)
        {
            var cities = new CommonRepository().ListCities(stateId);
            var result = cities.Select(x => new SelectListItem()
            {
                Id = x.Id,
                Text = x.Name
            }).ToList();
            return result;
        }

        public object Desingtions()
        {
            var transactions = new CommonRepository().ListDesingtions();
            var result = transactions.Select(x => new SelectListItem()
            {
                Id = x.Id,
                Text = x.Title
            }).ToList();
            return result;
        }

        public void Dispose()
        {
            GC.SuppressFinalize(true);
        }
    }
}
