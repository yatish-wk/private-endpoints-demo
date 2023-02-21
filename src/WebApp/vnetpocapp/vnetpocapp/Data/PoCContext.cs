using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using vnetpocapp.Models;

    public class PoCContext : DbContext
    {
        public PoCContext (DbContextOptions<PoCContext> options)
            : base(options)
        {
        }

        public DbSet<vnetpocapp.Models.Person> Person { get; set; } = default!;
    }
