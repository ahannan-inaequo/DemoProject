using System;
using System.Collections.Generic;
using System.Text;

namespace Data.Common
{
    public class Utils
    {
        public static string Encrypt(string str)
        {
            try
            {
                char[] arr = str.ToCharArray();
                Array.Reverse(arr);
                string temp = new string(arr);
                byte[] encData_byte = System.Text.Encoding.UTF8.GetBytes(temp);
                string encodedData = Convert.ToBase64String(encData_byte);
                return encodedData;
            }
            catch (Exception ex)
            {
                return str;
            }
        }
        public static string Decrypt(string str)
        {
            try
            {
                byte[] decData_byte = System.Convert.FromBase64String(str);
                string decodedData = System.Text.Encoding.UTF8.GetString(decData_byte);
                char[] arr = decodedData.ToCharArray();
                Array.Reverse(arr);
                decodedData = new string(arr);
                return decodedData;
            }
            catch (Exception ex)
            {
                return str;
            }
        }
    }
}
