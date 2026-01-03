# Translation Guide for Portal

Please read this guide carefully and follow all instructions properly.

For efficiency, use a PC or laptop.

You can use text editors such as VSCode, Xcode, Notepad++, Notepad, or TextEdit.

## What You **Cannot** Do
- Do not remove or alter `#`, `##`, or `###`
- Do not remove `(accent://)` or the `[ ]` in titles
- Do not remove "`"
- Do not change the meaning of any text
- Do not remove spacing between steps and lines of text
- Do not add your own information
- Do not add additional steps

## What You **Can** Do
- Translate accurately and precisely
- Adjust punctuation, grammar, and some words for clarity in your language
- You may translate titles
- You may change text inside `[ ]`
- You may change text after `#`, `##`, or `###`

## Additional Notes
- Do not translate terms like "madNS Config Profile" to aid us in troubleshooting
  
- Keep Certain English Terms Unchanged:
  - Discord
  - Portal
  - Revoked
  - Certs or Certificates
  - ESign
  - Feather
  - GBox
  - Scarlet
  - Sources
  - Post Install Notes
  - DNS Servers
  - WSF Config Profile
  - WSF Config Profile + Update Blocker
  - madNS Config Profile + Update Blocker
  - madNS Config Profile + Update Blocker + Ad-Blocker
  - madNS Config Profile + Ad-Blocker
  - madNS Config Profile
  - CFDNS Config Profile
  - CFDNS Config Profile + Update Blocker
  - DNS over HTTPS
  - DNS Servers
  - Any Certificate names
  - Any iOS terms such as General, VPN and Device Management, Files, etc.
    
  - Any other terms if you feel the need to keep them unchanged after consulting with the team

If you have any questions or notice missing information, please reach out in `#contributor-chat` for assistance.

---

## Part [1/2]

1. **Download Guides:**
   - Download the `.zip` file from [GitHub](https://github.com/WhySooooFurious/Ultimate-Sideloading-Guide/archive/refs/heads/main.zip)

2. **Extract Folder:**
   - Extract the .zip file
   - Navigate to the folder and then go into `wsf-app-guides` and then the `en` folder to find all necessary guides to be translated
   - Delete other language folders that you don't need
     
3. **Translating the Maintainer Information:**
   - Open `maintainer_information.md`
   - Keep in mind that `maintainer_information.md` is the only file where you should replace the text with the template provided below
   - All other .md files you can translate directly
     
     Here's how you should translate the maintainer information file. There is an example below in Spanish:
     
   
     ```xml
     ## [Maintainer Information](accent://)

     Information about who is currently maintaining this language.

     ### [Maintained By](accent://)

     (your_name_or_username_here_social_links_are_also_accepted)

     All information here is maintained by a translator and may not be accurate or up to date.

     If you require help, join the [Discord Server](https://discord.gg/wsf)
     ```
    
     ```xml
     ## [Información del mantenedor](accent://)

     Información sobre quién mantiene actualmente este idioma.

     ### [Mantenido por](accent://)

     Jimmy

     Toda la información aquí es mantenida por un traductor y puede no ser precisa o no estar actualizada.

     Si necesitas ayuda, únete al [Discord Server](https://discord.gg/wsf)
     ```

     Notice how the text was changed without altering any special characters, spacing was preserved, and important English words such as "Discord Server" remained the same?
     
     This is an example of a good translation.

4. **Saving:**
   - Save your translated file
   - Congratulations, you have successfully translated a file!
     
5. **More Translation:**
   - Translate all other .md files in the folder!

---

## Part [2/2]

1. **Changing Titles:**
   
   - After you have translated every .md file, you need to edit the title names in `Markdown_filenames.plist`
   - Do this for every .md file as well. There is an example below in Spanish:
   
   - Open `Markdown_filenames.plist`
  
   - Translate ONLY the `<string>Maintainer Information</string>` part in this case
   - Do NOT change any keys or other strings!
     
     ```xml
     <dict>
         <key>file_title</key>
         <string>Maintainer Information</string>
         <key>file_name</key>
         <string>maintainer_information.md</string>
     </dict>
     ```
     ```xml
     <dict>
         <key>file_title</key>
         <string>Información del mantenedor</string>
         <key>file_name</key>
         <string>maintainer_information.md</string>
     </dict>
     ```
     
     This is an example of a good translation.
    
     Do this for all other .md file titles in `Markdown_filenames.plist`

2. **Double-Check Files:**
   
   - Double-check all files for spelling, grammar, punctuation, and spacing errors

3. **Send Your Files:**
   
   - Zip up your files if you can and submit them on Discord or GitHub!
   - Or fork the repository and once you are done, make a pull request on GitHub

4. **The End!**
   
   - The WSF Team will review your submission. Thank you for taking part in helping Portal become better!
