# Setup Guide: PowerHash Suite

Follow these steps to install the PowerHash Suite manually and register it as a global command in your terminal.

---

## 1. Choose an Installation Folder

Move all the project files to a permanent location. Avoid using temporary folders like `Downloads`.

- **Recommended Path:** `C:\Resources\bin\PowerHash`

**Required Files:**

- `PowerHash.ps1` (Controller)
- `PowerHash-Checksum.ps1` (Worker)
- `PowerHash-Verify.ps1` (Worker)
- `PowerHash.bat` (CLI Shim)

---

## 2. Unblock the Scripts

Windows blocks scripts downloaded from the web by default. You must unblock them to allow execution.

1. Open **PowerShell** as Administrator.
2. Run the following command (update the path to match your folder):
   ```powershell
   Unblock-File -Path "C:\Resources\bin\PowerHash\PowerHash*.ps1"
   ```

## 3. Registering the Windows Environment Path

To call `PowerHash` from any folder, Windows needs to know where the `.bat` shim is located.

1.  **Open Environment Variables:**
    - Press `Win + R`, type `sysdm.cpl`, and hit **Enter**.
    - Navigate to the **Advanced** tab.
    - Click the **Environment Variables...** button at the bottom.

2.  **Edit the System Path:**
    - In the **System variables** section (the bottom half), find the variable named **Path**.
    - Select it and click **Edit...**.
    - Click **New** in the top right of the popup.
    - Paste the full path to your folder (e.g., `C:\Resources\bin\PowerHash`).

3.  **Confirm and Refresh:**
    - Click **OK** on all three windows.
    - **Crucial:** You must close and reopen any active Command Prompt or PowerShell windows for the change to take effect.
