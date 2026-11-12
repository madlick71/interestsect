-- Interesse "Programmieren (Rust)" umbenennen in "Rust"
-- (passt den Namen an die übrigen Programmiersprachen-Angebote an,
-- siehe 20261111000011_softwareentwicklung.sql). Slug bleibt unverändert.
-- Idempotent: Bedingung prüft den alten Namen.

update public.interests
set name_de = 'Rust'
where slug = 'programmieren-rust'
  and name_de = 'Programmieren (Rust)';
