-- le montant d'amandes a atteint 15€
create or replace function test()
returns void as $$
declare
  u_id int;
  s_id int;
  d_id int;
  l_id int;
  e_id int;
  loan_id int;
  c_date date;
begin
  perform delete_all_tables();
  select into u_id create_user('prénom 1', 'nom 1', 'user-1@example.com');
  select into s_id create_subscription('souscription 1', 2);
  perform add_subscription_to_user(s_id, u_id);
  select into l_id create_library('diderot');
  select into d_id create_document('fr', 'document 1', 2016, 'isbn-abcdef', 2, 10.00, false);
  select into e_id create_exemplaire(d_id, l_id, 'sn', 'bc');
  select into loan_id create_loan(e_id, u_id);

  -- Premiers 21 jours sans frais car pas de retard
  -- derniers 100 jours on applique 0.15e par jours
  -- 0.15 * 100 = 15e
  for index in 1 .. 121 loop
    perform increment_date();
  end loop;
end;
$$ language plpgsql;

select test();
select * from users;
select * from date;
