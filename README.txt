CM CAREER STUDIO — PROFESSIONAL BUILD

FILES
- index.html             Public landing page
- auth.html              Sign in / register / forgot password
- dashboard.html         Saved CV dashboard
- builder.html           Professional CV editor + live preview + PDF print
- templates.html         Template gallery
- checker.html           Client-side CV/job description matcher
- cover-letter.html      Saved cover letter builder
- profile.html           Profile + password settings
- supabase-setup.sql     Full database, triggers, RLS and permissions
- assets/css/app.css     Shared design system
- assets/js/*            Shared app + page logic

SUPABASE
Project URL and publishable key are already configured in assets/js/config.js.
The publishable key is intentionally frontend-safe. Never place a service_role key in browser code.

SETUP
1. Open Supabase > SQL Editor.
2. Run the entire supabase-setup.sql file.
3. Authentication > Providers > Email: enable Email.
4. Authentication > URL Configuration:
   - Set your final Site URL.
   - Add your auth/profile redirect URLs.
5. Upload all files to your web host preserving the folder structure.

LOCAL TESTING
Use a local web server rather than file:// because auth redirects are more reliable over http://localhost.
Examples:
- VS Code Live Server
- npx serve .
- python -m http.server 8080

PDF
The Download PDF button opens the browser print dialog with A4 print CSS. Choose "Save as PDF".

NOTES
- CVs and cover letters are saved in Supabase with RLS.
- ATS/job matching is currently client-side keyword analysis and does not invent skills.
- Templates: Modern, Classic, Minimal.
