-- Le pret est non renouvellable car il est en retard
create or replace function test()
returns void as $$
declare
  u_id int;
  s_id int;
  d_id int;
  l_id int;
  e_id int;
  loan_id int;
begin
  perform delete_all_tables();
  select into u_id create_user('Prénom 1', 'Nom 1', 'user-1@example.com');
  select into s_id create_subscription('Souscription 1', 2);
  perform add_subscription_to_user(s_id, u_id);
  select into d_id create_document('fr', 'Document 1', 2016, 'ISBN-abcdef', 2, 10.00, false);
  select into l_id create_library('diderot');
  select into e_id create_exemplaire(d_id, l_id, 'SN', 'BC');
  select into loan_id create_loan(e_id, u_id);
  perform add_to_date(40);
  perform renouvelement_pret(loan_id);
end;
$$ language plpgsql;

select test();
select * from users;
select * from loans;
select * from date;
