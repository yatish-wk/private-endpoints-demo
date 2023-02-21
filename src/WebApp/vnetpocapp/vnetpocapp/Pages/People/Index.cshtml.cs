using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using vnetpocapp.Models;

namespace vnetpocapp.Pages.Peopple
{
    public class IndexModel : PageModel
    {
        private readonly PoCContext _context;

        public IndexModel(PoCContext context)
        {
            _context = context;
        }

        public IList<Person> Person { get;set; } = default!;
        public string DbError { get; set; } 

        public async Task OnGetAsync()
        {
          //try
          //{
            if (_context.Person != null)
            {
              Person = await _context.Person.ToListAsync();
            }
          //}catch(Exception e)
          //{
            //DbError = $"{e.Message}<br>{e.StackTrace}";
          //}
        }
    }
}
