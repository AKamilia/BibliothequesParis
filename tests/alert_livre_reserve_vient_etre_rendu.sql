-- Un livre réservé vient d'être rendu, donc alerte
create or replace function test()
returns void as $$
declare
  u_id int;
  uu_id int;
  s_id int;
  d_id int;
  l_id int;
  e_id int;
  loan_id int;
  ss_id int;
begin
  perform delete_all_tables();
  select into u_id create_user('prénom 1', 'nom 1', 'user-1@example.com');
  select into uu_id create_user('prénom 2', 'nom 2', 'user-2@example.com');
  select into s_id create_subscription('souscription 1', 2);
  select into ss_id create_subscription('souscription 2', 2);
  perform add_subscription_to_user(s_id, u_id);
  perform add_subscription_to_user(ss_id, uu_id);
  select into l_id create_library('diderot');
  select into d_id create_document('fr', 'document 1', 2016, 'isbn-abcdef', 2, 10.00, false);
  select into e_id create_exemplaire(d_id, l_id, 'sn', 'bc');
  select into loan_id create_loan(e_id, u_id);
  perform create_reservation(e_id, uu_id);
  perform return_document(loan_id);
end;
$$ language plpgsql

select test();
select * from reservations;
select * from loans;
select * from date;
