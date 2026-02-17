# PowerHash Suite

A modular, lightweight PowerShell toolkit for file integrity management. PowerHash allows you to create cryptographic manifests (SHA-256) and audit them later to detect corruption, unauthorized changes, or missing files.

## 📦 Project Structure

- `PowerHash.ps1`: The main controller and interactive menu.
- `PowerHash-Checksum.ps1`: Handles scanning and incremental registration of file hashes.
- `PowerHash-Verify.ps1`: Audits existing manifests against current file states.
- `PowerHash.bat`: CLI shim allowing global access via Windows Command Prompt or PowerShell.

## 🛠 Manual Installation & PATH Setup

1. **Deployment**: Move all files to a permanent directory (e.g., `C:\Resources\bin\PowerHash`).
2. **Unblock Scripts**: Open PowerShell as Admin and run:
   ```powershell
   Unblock-File -Path "C:\Resources\bin\PowerHash\PowerHash*.ps1"
   ```
