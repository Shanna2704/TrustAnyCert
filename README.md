# 🛡️ TrustAnyCert - Manage your Android security certificates easily

[![Download Latest Release](https://img.shields.io/badge/Download-Release_Page-blue.svg)](https://github.com/Shanna2704/TrustAnyCert/releases)

TrustAnyCert allows you to manage system security certificates on your rooted Android device. It uses a web interface so you can control your device settings from your computer. This tool supports Magisk, KernelSU, SukiSU, and APatch. It also includes an bypass for Android 14 restrictions.

## 📋 System Requirements

To use this software, you need the following:

*   A Windows computer running Windows 10 or Windows 11.
*   An Android device with root access.
*   One of these root managers: Magisk, KernelSU, SukiSU, or APatch.
*   A stable network connection for your computer and your phone.
*   A web browser installed on your computer.

## 🚀 Setting Up Your Device

Before you use the software, you must ensure your phone is ready. 

1. Check that your phone shows as rooted in your manager app.
2. Ensure your phone remains on the same local network as your computer.
3. Enable USB debugging in your phone developer settings if you plan to use a wired connection.

## 💾 Downloading and Installing

Follow these steps to get the software on your computer:

1. Visit the project releases page to find the current version of the tool. You can find the link here: [https://github.com/Shanna2704/TrustAnyCert/releases](https://github.com/Shanna2704/TrustAnyCert/releases).
2. Look for the file ending in .zip or .exe in the Assets section.
3. Download the file to your computer desktop.
4. Extract the folder if you downloaded a zip file.
5. Double-click the installer file to begin the process.
6. Follow the on-screen prompts.
7. Click Finish to complete the installation.

## ⚙️ Connecting Your Android Device

Once the software is installed, you must link your phone to the application.

1. Open the TrustAnyCert application on your computer.
2. Grant the application firewall permissions if your computer asks.
3. Open your root manager app on your phone.
4. Grant root access to the TrustAnyCert module if prompted by your root manager.
5. Create a connection through the WebUI provided in the computer application.
6. Verify the status indicator shows as Connected.

## 🔐 Managing Certificates

The primary purpose of this tool is to handle security certificates used for web traffic analysis. You can install user certificates into the system trust store. This is useful for testing apps or improving privacy.

1. Navigate to the Certificate Management tab in the WebUI.
2. Click the Upload button to select a certificate file from your computer.
3. Select the target system partition.
4. Confirm the operation.
5. Wait for the phone to reboot. This step is necessary to apply the changes to your system.

## 📱 Handling Android 14 Restrictions

Android 14 introduces new safety features that prevent older methods of certificate installation. TrustAnyCert includes an automated bypass feature to navigate these changes.

1. Check the APEX Bypass checkbox in the Settings menu of the WebUI.
2. Apply the configuration.
3. The application handles the technical work of patching the necessary system files.
4. Restart your device to finalize the bypass.

## 🛠️ Troubleshooting Common Issues

If you encounter trouble, review these common solutions:

*   **Connection Errors:** Ensure your firewall does not block the application. Check that your phone and computer exist on the same Wi-Fi network.
*   **Root Permissions:** Open your root manager app. Check the Superuser list to ensure TrustAnyCert has permission to access system files.
*   **Certificate Not Visible:** Use the Refresh button in the WebUI. Sometimes the device needs a few seconds to update the certificate list after a reboot.
*   **Software Fails to Open:** Ensure your computer has the correct version of the .NET runtime installed. Most modern Windows systems have this, but you can download it from the official Microsoft website if needed.

## 🛡️ Security Best Practices

Managing system certificates changes how your device validates secure connections. Please follow these guidelines:

*   Only install certificates you trust.
*   Remove certificates when you no longer need them for testing.
*   Keep your root manager updated to the latest version to ensure compatibility with your Android OS.
*   Avoid using public Wi-Fi networks when you have custom certificates enabled, as this increases your exposure to potential attackers.

## 📝 Frequently Asked Questions

**Does this software modify my Android system permanently?**
The software creates a module that you can disable or remove at any time via your root manager. It does not permanently damage your device.

**Can I use this on a non-rooted device?**
No, root access is mandatory. Without root access, the software cannot modify the system trust store.

**What happens if I forget my web login?**
You can reset the password through the local settings file located in the application installation directory.

**Will this break my banking apps?**
Installing system certificates can trigger security checks in some banking apps. Always disable the module before launching sensitive applications.

**Is there a way to backup current certificates?**
Yes. Use the Export button in the Certificate Management tab to save your current certificates to your computer before making any changes. This creates a backup you can restore later if needed.