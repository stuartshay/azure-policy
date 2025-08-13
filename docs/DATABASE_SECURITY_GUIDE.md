# Database Security Configuration Guide

## Environment Variable Configuration

### Development Access IP

For security reasons, the development IP address should not be hardcoded in the Terraform configuration. Instead, use environment variables:

#### Option 1: Environment Variable (Recommended)
```bash
# Set your development IP address
export TF_VAR_dev_access_ip="your.ip.address.here"

# Run terraform commands
make terraform-database-plan
make terraform-database-apply
```

#### Option 2: Using .env File
Create a `.env` file in the project root (not committed to version control):
```bash
# .env file (add to .gitignore)
TF_VAR_dev_access_ip=your.ip.address.here
```

#### Option 3: Terraform Cloud Variables
In Terraform Cloud workspace, set as sensitive environment variable:
- **Variable Name**: `TF_VAR_dev_access_ip`
- **Value**: `your.ip.address.here`
- **Category**: Environment variable
- **Sensitive**: ✅ Yes

### Security Best Practices

1. **Never hardcode IP addresses** in Terraform configuration files
2. **Use environment variables** for sensitive network configuration
3. **Mark variables as sensitive** in Terraform Cloud
4. **Add .env files to .gitignore** to prevent accidental commits
5. **Use CIDR blocks** instead of individual IPs when possible
6. **Regularly rotate** access credentials and IP allowlists

### Development Workflow

```bash
# 1. Get your current public IP
curl -s ifconfig.me

# 2. Set environment variable
export TF_VAR_dev_access_ip="$(curl -s ifconfig.me)"

# 3. Deploy database
make terraform-database-apply

# 4. Verify access
psql -h your-db-server.postgres.database.azure.com -U psqladmin -d azurepolicy
```

### CI/CD Pipeline Configuration

For GitHub Actions or other CI/CD systems:

```yaml
# GitHub Actions example
env:
  TF_VAR_dev_access_ip: ${{ secrets.DEV_ACCESS_IP }}
```

### Terraform Cloud Configuration

1. **Navigate** to your Terraform Cloud workspace
2. **Go to** Variables tab
3. **Add** environment variable:
   - Name: `TF_VAR_dev_access_ip`
   - Value: Your IP address
   - Category: Environment variable
   - Sensitive: ✅ Checked

### Alternative: Using allowed_cidrs

For broader access patterns, use the `allowed_cidrs` variable:

```bash
# terraform.tfvars
allowed_cidrs = [
  "10.0.0.0/8",      # Corporate network
  "172.16.0.0/12",   # VPN range
]
```

This approach provides better security and maintainability than hardcoded individual IP addresses.
