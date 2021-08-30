using System;
using System.Collections.Generic;
using System.Text;

namespace Data
{
    public static class Db
    {

        public static DemoProjectContext Create()
        {
            try
            {
                DemoProjectContext db = new DemoProjectContext();
                return db;
            }
            catch { return null; }
        }
    }
}
