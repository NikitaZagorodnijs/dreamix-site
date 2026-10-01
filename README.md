# Dreamix Site (production version)

Static site (GitHub Pages) + Supabase (login, database, photo storage, live chat). Free tiers.

## Setup
1. supabase.com > New project (free). Save the database password.
2. SQL Editor > New query > paste `schema.sql` > Run.
3. Authentication > Sign In / Providers > Email: turn OFF "Confirm email". Save.
4. Authentication > Users > Add user > Create new user: your own email + password, tick "Auto Confirm User".
   Then SQL Editor, run: insert into public.admins select id from auth.users where email='YOUR-EMAIL';
5. Project Settings > API: copy Project URL and the anon public key into `config.js`.
6. Upload all files (index.html, config.js, .nojekyll, README.md) to a PUBLIC GitHub repository.
   Settings > Pages > Deploy from branch > main / root. Your link: https://USERNAME.github.io/REPO/
7. Authentication > URL Configuration: set Site URL to that link.

## Use
- Admin: log in with your email + password. Create an object (name, client login, client password). The password is shown once; send it to the client with the link.
- Customer: opens the link, logs in with the login/password, sees only their own object.

## Security notes
- The anon key in config.js is public by design. Access is enforced by row-level security in schema.sql.
- Anyone can technically create an account, but an account without an assigned object sees nothing.
- Deleting an object removes its data; files in storage stay until deleted in Supabase > Storage.
- Free Supabase projects pause after about 1 week without activity (resume with one click).
