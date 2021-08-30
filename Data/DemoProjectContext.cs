using Data.Models;
using Microsoft.EntityFrameworkCore;

namespace Data
{
    public partial class DemoProjectContext : DbContext
    {
        public DemoProjectContext()
        {
        }

        public DemoProjectContext(DbContextOptions<DemoProjectContext> options)
            : base(options)
        {
        }

        public virtual DbSet<City> Cities { get; set; }
        public virtual DbSet<Country> Countries { get; set; }
        public virtual DbSet<Designation> Designations { get; set; }
        public virtual DbSet<Employee> Employees { get; set; }
        public virtual DbSet<Role> Roles { get; set; }
        public virtual DbSet<State> States { get; set; }
        public virtual DbSet<User> Users { get; set; }
        public virtual DbSet<UserInRole> UserInRoles { get; set; }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                optionsBuilder.UseSqlServer("Server=DESKTOP-G52KEMP\\SQLEXPRESS;Database=DemoProject;Trusted_Connection=True;");
            }
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.HasAnnotation("Relational:Collation", "SQL_Latin1_General_CP1_CI_AS");

            modelBuilder.Entity<City>(entity =>
            {
                entity.Property(e => e.Name)
                    .HasMaxLength(30)
                    .IsUnicode(false);
            });

            modelBuilder.Entity<Country>(entity =>
            {
                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(150)
                    .IsUnicode(false);

                entity.Property(e => e.ShortName)
                    .HasMaxLength(3)
                    .IsUnicode(false)
                    .IsFixedLength(true);
            });

            modelBuilder.Entity<Designation>(entity =>
            {
                entity.Property(e => e.Title)
                    .IsRequired()
                    .HasMaxLength(100)
                    .IsUnicode(false);
            });

            modelBuilder.Entity<Employee>(entity =>
            {
                entity.Property(e => e.CreatedOn).HasColumnType("datetime");

                entity.Property(e => e.Email)
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.FirstName)
                    .IsRequired()
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.LastName)
                    .IsRequired()
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.MobileNo)
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.UpdatedOn).HasColumnType("datetime");
            });

            modelBuilder.Entity<Role>(entity =>
            {
                entity.Property(e => e.Name)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);
            });

            modelBuilder.Entity<State>(entity =>
            {
                entity.Property(e => e.CountryId).HasDefaultValueSql("((236))");

                entity.Property(e => e.Name).HasMaxLength(50);
            });

            modelBuilder.Entity<User>(entity =>
            {
                entity.Property(e => e.Address)
                    .HasMaxLength(200)
                    .IsUnicode(false);

                entity.Property(e => e.CreatedOn).HasColumnType("datetime");

                entity.Property(e => e.DateOfBirth).HasColumnType("datetime");

                entity.Property(e => e.Email)
                    .IsRequired()
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.FirstName)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.LastName)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.Password)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.Phone)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.UpdatedOn).HasColumnType("datetime");

                entity.Property(e => e.Username)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.Zip)
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.HasOne(d => d.City)
                    .WithMany(p => p.Users)
                    .HasForeignKey(d => d.CityId)
                    .HasConstraintName("FK_Users_Cities");

                entity.HasOne(d => d.Country)
                    .WithMany(p => p.Users)
                    .HasForeignKey(d => d.CountryId)
                    .HasConstraintName("FK_Users_Countries");

                entity.HasOne(d => d.State)
                    .WithMany(p => p.Users)
                    .HasForeignKey(d => d.StateId)
                    .HasConstraintName("FK_Users_States");
            });

            modelBuilder.Entity<UserInRole>(entity =>
            {
                entity.HasOne(d => d.Role)
                    .WithMany(p => p.UserInRoles)
                    .HasForeignKey(d => d.RoleId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_UserInRoles_Roles");

                entity.HasOne(d => d.User)
                    .WithMany(p => p.UserInRoles)
                    .HasForeignKey(d => d.UserId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_UserInRoles_Users");
            });

            OnModelCreatingPartial(modelBuilder);
        }

        partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
    }
}
