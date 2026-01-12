# Network Scripts

Collection of bash scripts for network administration and automation.

**📋 Infrastructure Reference:** See `/homelab-infrastructure/INFRASTRUCTURE.md` for:
- Complete network topology (VLANs, subnets, routing)
- All network devices (UniFi switches, APs, firewalls)
- Server IP addresses and SSH access
- DNS infrastructure across VLANs
- Network service ports and protocols

**SSH Access Pattern:**
```bash
ssh -i ~/.ssh/mareox-auth mareox@<server-ip-or-hostname>
```

## Scripts

- **Backup Scripts** - Database and system backups
- **Certificate Management** - SSL/TLS certificate automation
- **NFS Mounting** - Network file system utilities
- **System Updates** - Update automation scripts
- **SNMP Configuration** - SNMP daemon setup

## Usage

Each script includes inline documentation. Run with `-h` or `--help` for details.

## Contributing

Contributions welcome! Please open an issue or submit a pull request.

## License

[Choose appropriate license]
