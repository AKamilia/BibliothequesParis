-- Les nouveautés sont limités à 3, usager a déjà 3 dvds nouveautés, donc pas possible de prendre plus
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
  select into s_id create_subscription('Souscription 1', 2);
  perform add_subscription_to_user(s_id, u_id);
  select into d_id create_document('fr', 'Document 1', 2016, 'ISBN-abcdef', 2, 10.00, true); -- 2 signifie DVDs
  select into l_id create_library('diderot');

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
select * from documents;
select * from loans;
