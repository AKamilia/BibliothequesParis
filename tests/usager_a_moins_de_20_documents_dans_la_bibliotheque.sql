-- Usager a bien moins de 20 documents dans la bibliothèque, donc tout va bien
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
  select into u_id create_user('Prénom 1', 'Nom 1', 'user-1@example.com');
  select into s_id create_subscription('Souscription 1', 0);
  perform add_subscription_to_user(s_id, u_id);
  select into d_id create_document('fr', 'Document 1', 2016, 'ISBN-abcdef', 0, 10.00, false);
  select into l_id create_library('diderot');

  select into e_id create_exemplaire(d_id, l_id, 'SN', 'BC');
  perform create_loan(e_id, u_id);
  select into e_id create_exemplaire(d_id, l_id, 'SN', 'BC');
  perform create_loan(e_id, u_id);
  select into e_id create_exemplaire(d_id, l_id, 'SN', 'BC');
  perform create_loan(e_id, u_id);
  select into e_id create_exemplaire(d_id, l_id, 'SN', 'BC');
  perform create_loan(e_id, u_id);
  select into e_id create_exemplaire(d_id, l_id, 'SN', 'BC');
  perform create_loan(e_id, u_id);
end;
$$ language plpgsql;

select test();
select * from users;
select * from documents;
select * from loans;
select * from date;

