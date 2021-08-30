using Microsoft.Extensions.Configuration;
using System;
using System.IO;

namespace DemoApplication.Common
{
    public static class Connection
    {
        public static IConfiguration Configuration { get; set; }
        public static string GetConnectionString()
        {
            string connectionString = "";

            var builder = new ConfigurationBuilder().SetBasePath(Directory.GetCurrentDirectory()).AddJsonFile("appsettings.json");
            Configuration = builder.Build();  

            string strDbConnType = Configuration.GetSection("AppSettings").GetSection("DbConnectionType").Value;
            string strDatabase = Configuration.GetSection("AppSettings").GetSection("Database").Value;
            string strConnEncrypted = Configuration.GetSection("AppSettings").GetSection("DbConnectionString").Value; 

            if (strDatabase.ToLower() == "sql")
            {
                string server = Configuration.GetSection("AppSettings").GetSection("dbServer").Value;
                string dbName = Configuration.GetSection("AppSettings").GetSection("dbName").Value;
                string dbUser = Configuration.GetSection("AppSettings").GetSection("dbUser").Value;
                string dbPassword = Configuration.GetSection("AppSettings").GetSection("dbPassword").Value;         
                connectionString = "Data Source=" + server + ";Initial Catalog=" + dbName + ";uid=" + dbUser + ";pwd=" + dbPassword;
            }

            return connectionString;
        }

        public static string GetConnectionString(string dbType, string dbName, string dbUser, string dbPassword)
        {
            string connectionString = "";
            var builder = new ConfigurationBuilder().SetBasePath(Directory.GetCurrentDirectory()).AddJsonFile("appsettings.json");
            Configuration = builder.Build();

            string strDbConnType = Configuration.GetSection("AppSettings").GetSection("DbConnectionType").Value;// AppSettings["DbConnectionType"];
            string strDatabase = Configuration.GetSection("AppSettings").GetSection("Database").Value;// ConfigurationManager.AppSettings["Database"];
            string strConnEncrypted = Configuration.GetSection("AppSettings").GetSection("DbConnectionString").Value; // ConfigurationManager.AppSettings["DbConnectionString"];

            if (dbType.ToLower() == "sql")
            {
                string server = Configuration.GetSection("AppSettings").GetSection("dbServer").Value;//ConfigurationManager.AppSettings["dbServer"];

                connectionString = "Data Source=" + server + ";Initial Catalog=" + dbName + ";uid=" + dbUser + ";pwd=" + dbPassword;
            }

            return connectionString;
        }

    }
}