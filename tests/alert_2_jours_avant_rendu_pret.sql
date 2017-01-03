-- alerte un livre doit être rendu dans deux jours
create or replace function test()
returns void as $$
declare
  u_id int;
  s_id int;
  d_id int;
  l_id int;
  e_id int;
begin
  perform delete_all_tables();
  select into u_id create_user('prénom 1', 'nom 1', 'user-1@example.com');
  select into s_id create_subscription('souscription 1', 2);
  perform add_subscription_to_user(s_id, u_id);
  select into l_id create_library('diderot');
  select into d_id create_document('fr', 'document 1', 2016, 'isbn-abcdef', 2, 10.00, false);
  select into e_id create_exemplaire(d_id, l_id, 'sn', 'bc');
  perform create_loan(e_id, u_id);

  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date();
  perform increment_date(); -- cette ligne lancera une alerte car il reste 2 jours avant la date de rendue prévue
end;
$$ language plpgsql;

select test();
select * from loans;
select * from date;
