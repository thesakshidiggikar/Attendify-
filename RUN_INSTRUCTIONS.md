# Running FaceAttend-Flutter

Follow these steps to ensure your environment is set up correctly and the project runs smoothly.

## 1. Environment Setup (Fix PATH Issues)

If you see the error `Unable to find git in your PATH`, your Windows Environment Variables are missing fundamental paths.

### Fix for Current Session (Temporary)
Run the following line in PowerShell before running `flutter`:

```powershell
$winPaths = "C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\Program Files\Git\cmd;C:\flutter\bin"
$env:PATH = "$winPaths;" + $env:PATH
```

### Permanent Fix (Recommended)
1. Search Windows for **"Edit the system environment variables"**.
2. Click **Environment Variables**.
3. Edit the **Path** variable under User (or System) variables.
4. Ensure these are present:
   - `C:\Windows\System32`
   - `C:\Windows`
   - `C:\Windows\System32\Wbem`
   - `C:\Windows\System32\WindowsPowerShell\v1.0\`
   - `C:\Program Files\Git\cmd`
   - `C:\flutter\bin`
5. Click **OK** on all and **Restart your IDE/Terminal**.

---

## 2. Running the Dashboard (Web)

1. Open a terminal in the project root.
2. Navigate to the dashboard directory:
   ```powershell
   cd .\dashboard_app\
   ```
3. Run with Flutter:
   ```powershell
   flutter run -d chrome --web-port 8080 --web-browser-flag "--disable-web-security"
   ```

---

## 3. Running the Kiosk App (Mobile/Desktop)

1. Navigate to the kiosk directory:
   ```powershell
   cd .\kiosk_app\
   ```
2. Run with Flutter:
   ```powershell
   flutter run
   ```

---

## 4. Verification

To check if your environment is ready, run:
```powershell
flutter doctor -v
```
Everything should be green (checkmarks), particularly the Flutter and Chrome/Windows toolchains.
